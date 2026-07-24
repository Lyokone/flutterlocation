#include "include/location/location_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>
#include <gtk/gtk.h>

#include <cstring>

#define LOCATION_METHOD_CHANNEL "lyokone/location"
#define LOCATION_EVENT_CHANNEL "lyokone/locationstream"

#define GEOCLUE_BUS_NAME "org.freedesktop.GeoClue2"
#define GEOCLUE_MANAGER_PATH "/org/freedesktop/GeoClue2/Manager"
#define GEOCLUE_MANAGER_INTERFACE "org.freedesktop.GeoClue2.Manager"
#define GEOCLUE_CLIENT_INTERFACE "org.freedesktop.GeoClue2.Client"
#define GEOCLUE_LOCATION_INTERFACE "org.freedesktop.GeoClue2.Location"

// GeoClue2 accuracy level for a high-accuracy request (GCLUE_ACCURACY_LEVEL_EXACT).
#define GEOCLUE_ACCURACY_EXACT 8

struct _LocationPlugin {
  GObject parent_instance;

  FlMethodChannel* method_channel;
  FlEventChannel* event_channel;

  GDBusConnection* connection;
  gchar* client_path;
  guint location_updated_subscription;

  gboolean streaming;
  // Pending one-shot getLocation call, answered on the next location update.
  FlMethodCall* pending_get_location;
};

G_DEFINE_TYPE(LocationPlugin, location_plugin, g_object_get_type())

#define LOCATION_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), location_plugin_get_type(), \
                              LocationPlugin))

// Reads a GeoClue2 Location object into the map expected by the Dart side.
static FlValue* read_location(LocationPlugin* self, const gchar* location_path) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) result = g_dbus_connection_call_sync(
      self->connection, GEOCLUE_BUS_NAME, location_path,
      "org.freedesktop.DBus.Properties", "GetAll",
      g_variant_new("(s)", GEOCLUE_LOCATION_INTERFACE),
      G_VARIANT_TYPE("(a{sv})"), G_DBUS_CALL_FLAGS_NONE, -1, nullptr, &error);
  if (result == nullptr) {
    return nullptr;
  }

  g_autoptr(GVariant) properties = g_variant_get_child_value(result, 0);

  FlValue* map = fl_value_new_map();
  GVariantIter iter;
  const gchar* key;
  GVariant* value;
  g_variant_iter_init(&iter, properties);
  while (g_variant_iter_next(&iter, "{&sv}", &key, &value)) {
    if (strcmp(key, "Latitude") == 0) {
      fl_value_set_string_take(map, "latitude",
                               fl_value_new_float(g_variant_get_double(value)));
    } else if (strcmp(key, "Longitude") == 0) {
      fl_value_set_string_take(map, "longitude",
                               fl_value_new_float(g_variant_get_double(value)));
    } else if (strcmp(key, "Accuracy") == 0) {
      fl_value_set_string_take(map, "accuracy",
                               fl_value_new_float(g_variant_get_double(value)));
    } else if (strcmp(key, "Altitude") == 0) {
      fl_value_set_string_take(map, "altitude",
                               fl_value_new_float(g_variant_get_double(value)));
    } else if (strcmp(key, "Speed") == 0) {
      fl_value_set_string_take(map, "speed",
                               fl_value_new_float(g_variant_get_double(value)));
    } else if (strcmp(key, "Heading") == 0) {
      fl_value_set_string_take(map, "heading",
                               fl_value_new_float(g_variant_get_double(value)));
    } else if (strcmp(key, "Timestamp") == 0) {
      uint64_t seconds = 0;
      uint64_t microseconds = 0;
      g_variant_get(value, "(tt)", &seconds, &microseconds);
      double time_ms = static_cast<double>(seconds) * 1000.0 +
                       static_cast<double>(microseconds) / 1000.0;
      fl_value_set_string_take(map, "time", fl_value_new_float(time_ms));
    }
    g_variant_unref(value);
  }

  return map;
}

// D-Bus signal handler for org.freedesktop.GeoClue2.Client.LocationUpdated.
static void on_location_updated(GDBusConnection* connection,
                                const gchar* sender_name,
                                const gchar* object_path,
                                const gchar* interface_name,
                                const gchar* signal_name, GVariant* parameters,
                                gpointer user_data) {
  LocationPlugin* self = LOCATION_PLUGIN(user_data);

  const gchar* old_path = nullptr;
  const gchar* new_path = nullptr;
  g_variant_get(parameters, "(&o&o)", &old_path, &new_path);
  if (new_path == nullptr) {
    return;
  }

  FlValue* location = read_location(self, new_path);
  if (location == nullptr) {
    return;
  }

  if (self->pending_get_location != nullptr) {
    g_autoptr(GError) error = nullptr;
    fl_method_call_respond_success(self->pending_get_location, location, &error);
    g_clear_object(&self->pending_get_location);
  }
  if (self->streaming) {
    fl_event_channel_send(self->event_channel, location, nullptr, nullptr);
  }
  fl_value_unref(location);
}

// Sets a property on the GeoClue2 client object.
static void set_client_property(LocationPlugin* self, const gchar* name,
                                GVariant* value) {
  g_dbus_connection_call_sync(
      self->connection, GEOCLUE_BUS_NAME, self->client_path,
      "org.freedesktop.DBus.Properties", "Set",
      g_variant_new("(ssv)", GEOCLUE_CLIENT_INTERFACE, name, value),
      nullptr, G_DBUS_CALL_FLAGS_NONE, -1, nullptr, nullptr);
}

// Lazily creates and configures the GeoClue2 client. Returns FALSE on failure.
static gboolean ensure_client(LocationPlugin* self) {
  if (self->client_path != nullptr) {
    return TRUE;
  }

  g_autoptr(GError) error = nullptr;
  if (self->connection == nullptr) {
    self->connection = g_bus_get_sync(G_BUS_TYPE_SYSTEM, nullptr, &error);
    if (self->connection == nullptr) {
      return FALSE;
    }
  }

  g_autoptr(GVariant) client_result = g_dbus_connection_call_sync(
      self->connection, GEOCLUE_BUS_NAME, GEOCLUE_MANAGER_PATH,
      GEOCLUE_MANAGER_INTERFACE, "GetClient", nullptr, G_VARIANT_TYPE("(o)"),
      G_DBUS_CALL_FLAGS_NONE, -1, nullptr, &error);
  if (client_result == nullptr) {
    return FALSE;
  }
  g_variant_get(client_result, "(o)", &self->client_path);

  // GeoClue2 requires a DesktopId matching an installed .desktop file. Fall
  // back to the application id so agents that are permissive still work.
  const gchar* app_id = g_get_prgname();
  set_client_property(self, "DesktopId",
                      g_variant_new_string(app_id != nullptr ? app_id : "flutter"));
  set_client_property(self, "RequestedAccuracyLevel",
                      g_variant_new_uint32(GEOCLUE_ACCURACY_EXACT));

  self->location_updated_subscription = g_dbus_connection_signal_subscribe(
      self->connection, GEOCLUE_BUS_NAME, GEOCLUE_CLIENT_INTERFACE,
      "LocationUpdated", self->client_path, nullptr, G_DBUS_SIGNAL_FLAGS_NONE,
      on_location_updated, self, nullptr);

  return TRUE;
}

static gboolean start_client(LocationPlugin* self) {
  if (!ensure_client(self)) {
    return FALSE;
  }
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) result = g_dbus_connection_call_sync(
      self->connection, GEOCLUE_BUS_NAME, self->client_path,
      GEOCLUE_CLIENT_INTERFACE, "Start", nullptr, nullptr,
      G_DBUS_CALL_FLAGS_NONE, -1, nullptr, &error);
  return result != nullptr;
}

static void stop_client(LocationPlugin* self) {
  if (self->connection == nullptr || self->client_path == nullptr) {
    return;
  }
  g_dbus_connection_call_sync(self->connection, GEOCLUE_BUS_NAME,
                              self->client_path, GEOCLUE_CLIENT_INTERFACE,
                              "Stop", nullptr, nullptr, G_DBUS_CALL_FLAGS_NONE,
                              -1, nullptr, nullptr);
}

// Whether the GeoClue2 service is reachable on the system bus.
static gboolean service_enabled(LocationPlugin* self) {
  return ensure_client(self);
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  LocationPlugin* self = LOCATION_PLUGIN(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  g_autoptr(GError) error = nullptr;

  if (strcmp(method, "getLocation") == 0) {
    if (!start_client(self)) {
      fl_method_call_respond_error(method_call, "SERVICE_STATUS_ERROR",
                                   "GeoClue2 service is not available", nullptr,
                                   &error);
      return;
    }
    // Answered asynchronously by on_location_updated.
    g_clear_object(&self->pending_get_location);
    self->pending_get_location =
        FL_METHOD_CALL(g_object_ref(method_call));
  } else if (strcmp(method, "hasPermission") == 0 ||
             strcmp(method, "requestPermission") == 0) {
    // GeoClue2 mediates access through its agent; assume granted when reachable.
    g_autoptr(FlValue) value =
        fl_value_new_int(service_enabled(self) ? 1 : 0);
    fl_method_call_respond_success(method_call, value, &error);
  } else if (strcmp(method, "serviceEnabled") == 0 ||
             strcmp(method, "requestService") == 0) {
    g_autoptr(FlValue) value =
        fl_value_new_int(service_enabled(self) ? 1 : 0);
    fl_method_call_respond_success(method_call, value, &error);
  } else if (strcmp(method, "changeSettings") == 0) {
    ensure_client(self);
    g_autoptr(FlValue) value = fl_value_new_int(1);
    fl_method_call_respond_success(method_call, value, &error);
  } else if (strcmp(method, "isBackgroundModeEnabled") == 0 ||
             strcmp(method, "enableBackgroundMode") == 0) {
    g_autoptr(FlValue) value = fl_value_new_int(0);
    fl_method_call_respond_success(method_call, value, &error);
  } else {
    fl_method_call_respond_not_implemented(method_call, &error);
  }
}

static FlMethodErrorResponse* listen_cb(FlEventChannel* channel,
                                        FlValue* args, gpointer user_data) {
  LocationPlugin* self = LOCATION_PLUGIN(user_data);
  self->streaming = TRUE;
  if (!start_client(self)) {
    self->streaming = FALSE;
    return fl_method_error_response_new("SERVICE_STATUS_ERROR",
                                        "GeoClue2 service is not available",
                                        nullptr);
  }
  return nullptr;
}

static FlMethodErrorResponse* cancel_cb(FlEventChannel* channel, FlValue* args,
                                        gpointer user_data) {
  LocationPlugin* self = LOCATION_PLUGIN(user_data);
  self->streaming = FALSE;
  if (self->pending_get_location == nullptr) {
    stop_client(self);
  }
  return nullptr;
}

static void location_plugin_dispose(GObject* object) {
  LocationPlugin* self = LOCATION_PLUGIN(object);

  if (self->connection != nullptr && self->location_updated_subscription != 0) {
    g_dbus_connection_signal_unsubscribe(self->connection,
                                         self->location_updated_subscription);
    self->location_updated_subscription = 0;
  }
  stop_client(self);

  g_clear_object(&self->method_channel);
  g_clear_object(&self->event_channel);
  g_clear_object(&self->pending_get_location);
  g_clear_object(&self->connection);
  g_clear_pointer(&self->client_path, g_free);

  G_OBJECT_CLASS(location_plugin_parent_class)->dispose(object);
}

static void location_plugin_class_init(LocationPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = location_plugin_dispose;
}

static void location_plugin_init(LocationPlugin* self) {}

void location_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  LocationPlugin* plugin =
      LOCATION_PLUGIN(g_object_new(location_plugin_get_type(), nullptr));

  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();

  plugin->method_channel = fl_method_channel_new(
      messenger, LOCATION_METHOD_CHANNEL, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      plugin->method_channel, method_call_cb, g_object_ref(plugin),
      g_object_unref);

  plugin->event_channel = fl_event_channel_new(
      messenger, LOCATION_EVENT_CHANNEL, FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(plugin->event_channel, listen_cb,
                                       cancel_cb, g_object_ref(plugin),
                                       g_object_unref);

  g_object_unref(plugin);
}
