#ifndef FLUTTER_PLUGIN_LOCATION_PLUGIN_H_
#define FLUTTER_PLUGIN_LOCATION_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <winrt/Windows.Devices.Geolocation.h>

#include <memory>

namespace location {

class LocationPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(
      flutter::PluginRegistrarWindows* registrar);

  LocationPlugin();

  ~LocationPlugin() override;

  // Disallow copy and assign.
  LocationPlugin(const LocationPlugin&) = delete;
  LocationPlugin& operator=(const LocationPlugin&) = delete;

 private:
  // Called when a method is called on the plugin channel.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Ensures the Geolocator instance exists.
  void EnsureGeolocator();

  // Starts forwarding position updates on the event channel.
  void StartListening();
  void StopListening();

  winrt::Windows::Devices::Geolocation::Geolocator geolocator_{nullptr};
  winrt::event_token position_changed_token_{};

  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
};

}  // namespace location

#endif  // FLUTTER_PLUGIN_LOCATION_PLUGIN_H_
