# Location 5 Interface

## getLocation

- Settings?

## onLocationChanged

- Uses the global location settings

## setLocationSettings

Will update the location settings of the current onLocationChanged

- askForPermission

Message shown to the user

- useGooglePlayServices
- askForGooglePlayServices
- askForGPS
- fallbackToGPS
- ignoreLastKnownPosition
- setExpirationDuration(long millis)

Set the duration of this request, in milliseconds.

- setExpirationTime(long millis)

Set the request expiration time, in millisecond since boot.

- setFastestInterval(long millis)

Explicitly set the fastest interval for location updates, in milliseconds.

- setInterval(long millis)

Set the desired interval for active location updates, in milliseconds.

- setMaxWaitTime(long millis)

Sets the maximum wait time in milliseconds for location updates.

- setNumUpdates(int numUpdates)

Set the number of location updates.

- setPriority(int priority)

Set the priority of the request.

- setSmallestDisplacement(float smallestDisplacementMeters)

Set the minimum displacement between location updates in meters
By default this is 0.

- setWaitForAccurateLocation(boolean waitForAccurateLocation)

Sets whether the client wants the locations services to wait a few seconds for accurate locations initially, when accurate locations could not be computed on the device immediately after PRIORITY_HIGH_ACCURACY request is made.

## getPermissionStatus

## setBackgroundMode

## requestPermission

## isGPSEnabled

## isNetworkEnabled

# Yayaa Location Manager

## Ask for permissions

- Rationale message

## Play Services

- Fallback to default
- Ask for Google Play Services
- Ask for Settings Api
- Ignore last known location
- wait period

# Version 4 interface

| Return                    | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Future\<PermissionStatus> | **requestPermission()** <br>Request the Location permission. Return a PermissionStatus to know if the permission has been granted.                                                                                                                                                                                                                                                                                                                           |
| Future\<PermissionStatus> | **hasPermission()** <br>Return a PermissionStatus to know the state of the location permission.                                                                                                                                                                                                                                                                                                                                                              |
| Future\<bool>             | **serviceEnabled()** <br>Return a boolean to know if the Location Service is enabled or if the user manually deactivated it.                                                                                                                                                                                                                                                                                                                                 |
| Future\<bool>             | **requestService()** <br>Show an alert dialog to request the user to activate the Location Service. On iOS, will only display an alert due to Apple Guidelines, the user having to manually go to Settings. Return a boolean to know if the Location Service has been activated (always `false` on iOS).                                                                                                                                                     |
| Future\<bool>             | **changeSettings(LocationAccuracy accuracy = LocationAccuracy.HIGH, int interval = 1000, double distanceFilter = 0)** <br>Will change the settings of futur requests. `accuracy`will describe the accuracy of the request (see the LocationAccuracy object). `interval` will set the desired interval for active location updates, in milliseconds (only affects Android). `distanceFilter` set the minimum displacement between location updates in meters. |
| Future\<LocationData>     | **getLocation()** <br>Allow to get a one time position of the user. It will try to request permission if not granted yet and will throw a `PERMISSION_DENIED` error code if permission still not granted.                                                                                                                                                                                                                                                    |
| Stream\<LocationData>     | **onLocationChanged** <br>Get the stream of the user's location. It will try to request permission if not granted yet and will throw a `PERMISSION_DENIED` error code if permission still not granted.                                                                                                                                                                                                                                                       |
| Future\<bool>             | **enableBackgroundMode({bool enable})** <br>Allow or disallow to retrieve location events in the background. Return a boolean to know if background mode was successfully enabled.                                                                                                                                                                                                                                                                           |
