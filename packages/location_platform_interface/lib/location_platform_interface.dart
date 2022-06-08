import 'package:location_platform_interface/messages.pigeon.dart';
import 'package:location_platform_interface/method_channel_location.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of location must implement.
///
/// Platform implementations should extend this class
/// rather than implement it as `Location`.
/// Extending this class (using `extends`) ensures that the subclass will get
/// the default implementation, while platform implementations that `implements`
///  this interface will be broken by newly added [LocationPlatform] methods.
abstract class LocationPlatform extends PlatformInterface {
  /// Constructs a LocationPlatform.
  LocationPlatform() : super(token: _token);

  static final Object _token = Object();

  static LocationPlatform _instance = MethodChannelLocation();

  /// The default instance of [LocationPlatform] to use.
  ///
  /// Defaults to [MethodChannelLocation].
  static LocationPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [LocationPlatform] when they  themselves.
  static set instance(LocationPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Return the current location.
  Future<LocationData?> getLocation({LocationSettings? settings});

  /// Return a stream of the user's location.
  Stream<LocationData?> get onLocationChanged;

  /// Set new global location settings for the app
  Future<bool?> setLocationSettings(LocationSettings settings);

  /// Get the permission status of the app
  Future<PermissionStatus?> getPermissionStatus();

  /// Request location permission for the app
  Future<PermissionStatus?> requestPermission();

  /// Return true if GPS is enabled on the device
  Future<bool?> isGPSEnabled();

  /// Return true if Network is enabled on the device
  Future<bool?> isNetworkEnabled();
}
