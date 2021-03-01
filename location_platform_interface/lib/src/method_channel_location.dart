// File created by
// Lung Razvan <long1eu>
// on 23/03/2020

part of location_platform_interface;

/// The interface that implementations of `location` must extend.
///
/// Platform implementations should extend this class rather than implement it
/// as `location` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// will get the default implementation, while platform implementations that
/// `implements` this interface will be broken by newly added
/// [LocationPlatform] methods.
class MethodChannelLocation extends LocationPlatform {
  /// Initializes the plugin and starts listening for potential platform events.
  factory MethodChannelLocation() {
    if (_instance == null) {
      const MethodChannel methodChannel = MethodChannel('lyokone/location');
      const EventChannel eventChannel = EventChannel('lyokone/locationstream');
      _instance = MethodChannelLocation.private(methodChannel, eventChannel);
    }
    return _instance;
  }

  /// This constructor is only used for testing and shouldn't be accessed by
  /// users of the plugin. It may break or change at any time.
  @visibleForTesting
  MethodChannelLocation.private(this._methodChannel, this._eventChannel);

  static MethodChannelLocation _instance;

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<LocationData> _onLocationChanged;

  /// Change settings of the location request.
  ///
  /// The [accuracy] argument is controlling the precision of the
  /// [LocationData]. The [interval] and [distanceFilter] are controlling how
  /// often a new location is sent through [onLocationChanged].
  @override
  Future<bool> changeSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int interval = 1000,
    double distanceFilter = 0,
  }) async {
    final int result = await _methodChannel.invokeMethod(
      'changeSettings',
      <String, dynamic>{'accuracy': accuracy.index, 'interval': interval, 'distanceFilter': distanceFilter},
    );

    return result == 1;
  }

  /// Checks if service is enabled in the background mode.
  @override
  Future<bool> isBackgroundModeEnabled() async {
    final int result =
        await _methodChannel.invokeMethod('isBackgroundModeEnabled');
    return result == 1;
  }

  /// Enables or disables service in the background mode.
  @override
  Future<bool> enableBackgroundMode({bool enable}) async {
    final int result = await _methodChannel.invokeMethod(
      'enableBackgroundMode',
      <String, dynamic>{'enable': enable},
    );

    return result == 1;
  }

  /// Gets the current location of the user.
  ///
  /// Throws an error if the app has no permission to access location.
  /// Returns a [LocationData] object.
  @override
  Future<LocationData> getLocation() async {
    final Map<String, double> resultMap = await _methodChannel.invokeMapMethod('getLocation');
    return LocationData.fromMap(resultMap);
  }

  @override
  Future<PermissionStatus> hasPermission() async {
    final int result = await _methodChannel.invokeMethod('hasPermission');
    return _parsePermissionStatus(result);
  }

  @override
  Future<PermissionStatus> requestPermission() async {
    final int result = await _methodChannel.invokeMethod('requestPermission');
    return _parsePermissionStatus(result);
  }

  PermissionStatus _parsePermissionStatus(int result) {
    switch (result) {
      case 0:
        return PermissionStatus.denied;
      case 1:
        return PermissionStatus.granted;
      case 2:
        return PermissionStatus.deniedForever;
      case 3:
        return PermissionStatus.grantedLimited;
      default:
        throw PlatformException(
          code: 'UNKNOWN_NATIVE_MESSAGE',
          message: 'Could not decode parsePermissionStatus with $result',
        );
    }
  }

  /// Checks if the location service is enabled.
  @override
  Future<bool> serviceEnabled() async {
    final int result = await _methodChannel.invokeMethod('serviceEnabled');
    return result == 1;
  }

  /// Request the activation of the location service.
  @override
  Future<bool> requestService() async {
    final int result = await _methodChannel.invokeMethod('requestService');
    return result == 1;
  }

  /// Returns a stream of [LocationData] objects. The frequency and accuracy of
  /// this stream can be changed with [changeSettings]
  ///
  /// Throws an error if the app has no permission to access location.
  @override
  Stream<LocationData> get onLocationChanged {
    return _onLocationChanged ??= _eventChannel
        .receiveBroadcastStream()
        .map<LocationData>((dynamic element) => LocationData.fromMap(Map<String, double>.from(element)));
  }

  /// Change options of sticky background notification on Android.
  ///
  /// This method only applies to Android and allows for customizing the
  /// notification, which is shown when [enableBackgroundMode] is set to true.
  /// On platforms other than Android, this method will do nothing.
  ///
  /// Uses [title] as the notification's content title and searches for a
  /// drawable resource with the given [iconName]. If no matching resource is
  /// found, no icon is shown. The content text will be set to [subTitle], while
  /// the sub text will be set to [description]. The notification [color] can
  /// also be customized.
  ///
  /// Both [title] and [channelName] will be set to defaults, if no values are
  /// provided. All other null arguments will be ignored.
  ///
  /// For Android SDK versions above 25, uses [channelName] for the
  /// [NotificationChannel](https://developer.android.com/reference/android/app/NotificationChannel).
  @override
  Future<bool> changeNotificationOptions({
    String channelName,
    String title,
    String iconName,
    String subtitle,
    String description,
    Color color,
  }) async {
    if (!Platform.isAndroid) {
      // This method only applies to Android.
      // Do nothing to prevent user from handling a potential error.
      return true;
    }

    final Map<String, dynamic> data = <String, dynamic>{
      'channelName': channelName,
      'title': title,
      'iconName': iconName,
    };

    if (subtitle != null) {
      data['subtitle'] = subtitle;
    }

    if (description != null) {
      data['description'] = description;
    }

    if (color != null) {
      data['color'] = '#${color.value.toRadixString(16)}';
    }

    final int result =
        await _methodChannel.invokeMethod('changeNotificationOptions', data);

    return result == 1;
  }
}
