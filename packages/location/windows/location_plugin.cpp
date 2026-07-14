#include "location_plugin.h"

#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>

#include <winrt/Windows.Foundation.h>

#include <memory>
#include <string>

namespace location {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using winrt::Windows::Devices::Geolocation::Geolocator;
using winrt::Windows::Devices::Geolocation::Geoposition;
using winrt::Windows::Devices::Geolocation::GeolocationAccessStatus;
using winrt::Windows::Devices::Geolocation::PositionAccuracy;
using winrt::Windows::Devices::Geolocation::PositionStatus;

// Builds the location map expected by the Dart LocationData.fromMap.
EncodableValue GeopositionToEncodable(const Geoposition& position) {
  auto coordinate = position.Coordinate();
  auto point = coordinate.Point().Position();

  EncodableMap map;
  map[EncodableValue("latitude")] = EncodableValue(point.Latitude);
  map[EncodableValue("longitude")] = EncodableValue(point.Longitude);
  map[EncodableValue("altitude")] = EncodableValue(point.Altitude);
  map[EncodableValue("accuracy")] = EncodableValue(coordinate.Accuracy());

  if (const auto heading = coordinate.Heading()) {
    map[EncodableValue("heading")] = EncodableValue(heading.Value());
  } else {
    map[EncodableValue("heading")] = EncodableValue(0.0);
  }

  if (const auto speed = coordinate.Speed()) {
    map[EncodableValue("speed")] = EncodableValue(speed.Value());
  } else {
    map[EncodableValue("speed")] = EncodableValue(0.0);
  }

  // Timestamp -> milliseconds since the Unix epoch.
  const auto seconds = winrt::clock::to_time_t(coordinate.Timestamp());
  map[EncodableValue("time")] =
      EncodableValue(static_cast<double>(seconds) * 1000.0);

  return EncodableValue(map);
}

// Whether the current location status allows retrieving a position.
bool IsServiceEnabled(const Geolocator& geolocator) {
  const auto status = geolocator.LocationStatus();
  return status != PositionStatus::Disabled &&
         status != PositionStatus::NotAvailable;
}

}  // namespace

// static
void LocationPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<LocationPlugin>();

  auto method_channel =
      std::make_unique<flutter::MethodChannel<EncodableValue>>(
          registrar->messenger(), "lyokone/location",
          &flutter::StandardMethodCodec::GetInstance());
  method_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  auto event_channel = std::make_unique<flutter::EventChannel<EncodableValue>>(
      registrar->messenger(), "lyokone/locationstream",
      &flutter::StandardMethodCodec::GetInstance());
  event_channel->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
          [plugin_pointer = plugin.get()](
              const EncodableValue*,
              std::unique_ptr<flutter::EventSink<EncodableValue>>&& events)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            plugin_pointer->event_sink_ = std::move(events);
            plugin_pointer->StartListening();
            return nullptr;
          },
          [plugin_pointer = plugin.get()](const EncodableValue*)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            plugin_pointer->StopListening();
            plugin_pointer->event_sink_.reset();
            return nullptr;
          }));

  registrar->AddPlugin(std::move(plugin));
}

LocationPlugin::LocationPlugin() {}

LocationPlugin::~LocationPlugin() { StopListening(); }

void LocationPlugin::EnsureGeolocator() {
  if (geolocator_ == nullptr) {
    geolocator_ = Geolocator();
  }
}

void LocationPlugin::StartListening() {
  EnsureGeolocator();
  if (position_changed_token_) {
    return;
  }
  position_changed_token_ = geolocator_.PositionChanged(
      [this](const Geolocator&, const auto& args) {
        if (event_sink_) {
          event_sink_->Success(GeopositionToEncodable(args.Position()));
        }
      });
}

void LocationPlugin::StopListening() {
  if (position_changed_token_ && geolocator_ != nullptr) {
    geolocator_.PositionChanged(position_changed_token_);
    position_changed_token_ = {};
  }
}

void LocationPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  EnsureGeolocator();
  const std::string& method = method_call.method_name();

  if (method == "getLocation") {
    // Marshal back to the calling (UI) thread before responding.
    winrt::apartment_context ui_thread;
    std::shared_ptr<flutter::MethodResult<EncodableValue>> shared_result(
        std::move(result));
    Geolocator geolocator = geolocator_;
    [](Geolocator geolocator, winrt::apartment_context ui_thread,
       std::shared_ptr<flutter::MethodResult<EncodableValue>> result)
        -> winrt::fire_and_forget {
      // co_await is not allowed inside a catch block, so record any failure
      // and respond after the try/catch.
      std::string error_message;
      try {
        auto access = co_await Geolocator::RequestAccessAsync();
        if (access != GeolocationAccessStatus::Allowed) {
          co_await ui_thread;
          result->Error("PERMISSION_DENIED",
                        "Location permission not granted");
          co_return;
        }
        auto position = co_await geolocator.GetGeopositionAsync();
        co_await ui_thread;
        result->Success(GeopositionToEncodable(position));
        co_return;
      } catch (const winrt::hresult_error& e) {
        error_message = winrt::to_string(e.message());
      }
      co_await ui_thread;
      result->Error("LOCATION_ERROR", error_message);
    }(geolocator, ui_thread, shared_result);
  } else if (method == "hasPermission" || method == "requestPermission") {
    winrt::apartment_context ui_thread;
    std::shared_ptr<flutter::MethodResult<EncodableValue>> shared_result(
        std::move(result));
    [](winrt::apartment_context ui_thread,
       std::shared_ptr<flutter::MethodResult<EncodableValue>> result)
        -> winrt::fire_and_forget {
      auto access = co_await Geolocator::RequestAccessAsync();
      co_await ui_thread;
      result->Success(EncodableValue(
          access == GeolocationAccessStatus::Allowed ? 1 : 0));
    }(ui_thread, shared_result);
  } else if (method == "serviceEnabled" || method == "requestService") {
    result->Success(EncodableValue(IsServiceEnabled(geolocator_) ? 1 : 0));
  } else if (method == "changeSettings") {
    const auto* arguments =
        std::get_if<EncodableMap>(method_call.arguments());
    if (arguments != nullptr) {
      auto accuracy_it = arguments->find(EncodableValue("accuracy"));
      if (accuracy_it != arguments->end()) {
        const int accuracy = std::get<int>(accuracy_it->second);
        geolocator_.DesiredAccuracy(accuracy >= 3 ? PositionAccuracy::High
                                                  : PositionAccuracy::Default);
      }
      auto distance_it = arguments->find(EncodableValue("distanceFilter"));
      if (distance_it != arguments->end()) {
        geolocator_.MovementThreshold(std::get<double>(distance_it->second));
      }
      auto interval_it = arguments->find(EncodableValue("interval"));
      if (interval_it != arguments->end()) {
        geolocator_.ReportInterval(
            static_cast<uint32_t>(std::get<int>(interval_it->second)));
      }
    }
    result->Success(EncodableValue(1));
  } else if (method == "isBackgroundModeEnabled" ||
             method == "enableBackgroundMode") {
    // Background mode is not supported on Windows.
    result->Success(EncodableValue(0));
  } else {
    result->NotImplemented();
  }
}

}  // namespace location
