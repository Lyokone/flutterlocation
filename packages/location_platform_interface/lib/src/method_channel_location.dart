part of location_platform_interface;

///
class MethodChannelLocation extends LocationPlatform {
  ///
  factory MethodChannelLocation() {
    if (_instance == null) {
      const eventChannel = EventChannel('lyokone/location_stream');
      _instance = MethodChannelLocation.private(eventChannel);
    }
    return _instance!;
  }

  /// This constructor is only used for testing and shouldn't be accessed by
  /// users of the plugin. It may break or change at any time.
  @visibleForTesting
  MethodChannelLocation.private(this._eventChannel);

  static MethodChannelLocation? _instance;

  final _api = LocationHostApi();
  late final EventChannel _eventChannel;

  @override
  Future<LocationData?> getLocation({LocationSettings? settings}) async {
    final pigeonData = await _api.getLocation(settings?.toPigeon());
    return LocationData.fromPigeon(pigeonData);
  }

  /// Current opened stream of location
  Stream<LocationData>? _onLocationChanged;

  @override
  Stream<LocationData?> onLocationChanged({bool inBackground = false}) {
    if (_onLocationChanged != null) {
      _api.setBackgroundActivated(inBackground);
    }

    return _onLocationChanged ??=
        _eventChannel.receiveBroadcastStream(inBackground).map<LocationData>(
              (dynamic event) => LocationData.fromPigeon(
                PigeonLocationData.decode(event as Object),
              ),
            );
  }

  @override
  Future<bool?> setLocationSettings(LocationSettings settings) {
    return _api.setLocationSettings(settings.toPigeon());
  }

  @override
  Future<PermissionStatus?> getPermissionStatus() async {
    final permission = await _api.getPermissionStatus();
    return permissionStatusFromInt(permission);
  }

  @override
  Future<PermissionStatus?> requestPermission() async {
    final permission = await _api.requestPermission();
    return permissionStatusFromInt(permission);
  }

  @override
  Future<bool?> isGPSEnabled() {
    return _api.isGPSEnabled();
  }

  @override
  Future<bool?> isNetworkEnabled() {
    return _api.isNetworkEnabled();
  }

  @override
  Future<bool?> updateBackgroundNotification({
    String? channelName,
    String? title,
    String? iconName,
    String? subtitle,
    String? description,
    Color? color,
    bool? onTapBringToFront,
  }) async {
    if (!Platform.isAndroid) {
      return true;
    }
    return _api.changeNotificationSettings(
      PigeonNotificationSettings(
        channelName: channelName,
        title: title,
        iconName: iconName,
        subtitle: subtitle,
        description: description,
        color: color != null ? '#${color.value.toRadixString(16)}' : null,
        onTapBringToFront: onTapBringToFront,
      ),
    );
  }
}
