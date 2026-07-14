package com.lyokone.location

import android.graphics.Color
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

private const val METHOD_CHANNEL_NAME = "lyokone/location"

internal class MethodCallHandlerImpl : MethodCallHandler {
    private var location: FlutterLocation? = null
    private var locationService: FlutterLocationService? = null
    private var channel: MethodChannel? = null

    fun setLocation(location: FlutterLocation?) {
        this.location = location
    }

    fun setLocationService(locationService: FlutterLocationService?) {
        this.locationService = locationService
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        val location = this.location
        if (location == null) {
            result.error("NO_ACTIVITY", "Location is not attached to an activity.", null)
            return
        }
        when (call.method) {
            "changeSettings" -> onChangeSettings(call, result, location)
            "getLocation" -> onGetLocation(result, location)
            "hasPermission" -> onHasPermission(result, location)
            "requestPermission" -> onRequestPermission(result, location)
            "serviceEnabled" -> onServiceEnabled(result, location)
            "requestService" -> location.requestService(result)
            "isBackgroundModeEnabled" -> isBackgroundModeEnabled(result)
            "enableBackgroundMode" -> enableBackgroundMode(call, result)
            "changeNotificationOptions" -> onChangeNotificationOptions(call, result)
            else -> result.notImplemented()
        }
    }

    /**
     * Registers this instance as a method call handler on the given [messenger].
     */
    fun startListening(messenger: BinaryMessenger) {
        if (channel != null) {
            Log.wtf(TAG, "Setting a method call handler before the last was disposed.")
            stopListening()
        }

        channel =
            MethodChannel(messenger, METHOD_CHANNEL_NAME).apply {
                setMethodCallHandler(this@MethodCallHandlerImpl)
            }
    }

    /**
     * Clears this instance from listening to method calls.
     */
    fun stopListening() {
        val channel = this.channel
        if (channel == null) {
            Log.d(TAG, "Tried to stop listening when no MethodChannel had been initialized.")
            return
        }

        channel.setMethodCallHandler(null)
        this.channel = null
    }

    private fun onChangeSettings(
        call: MethodCall,
        result: Result,
        location: FlutterLocation,
    ) {
        try {
            val locationAccuracy = location.mapFlutterAccuracy[call.argument<Int>("accuracy")!!]
            val updateIntervalMilliseconds = call.argument<Int>("interval")!!.toLong()
            val fastestUpdateIntervalMilliseconds = updateIntervalMilliseconds / 2
            val distanceFilter = call.argument<Double>("distanceFilter")!!.toFloat()

            location.changeSettings(
                locationAccuracy,
                updateIntervalMilliseconds,
                fastestUpdateIntervalMilliseconds,
                distanceFilter,
            )

            result.success(1)
        } catch (e: Exception) {
            result.error(
                "CHANGE_SETTINGS_ERROR",
                "An unexpected error happened during location settings change:" + e.message,
                null,
            )
        }
    }

    private fun onGetLocation(
        result: Result,
        location: FlutterLocation,
    ) {
        location.getLocationResult = result
        if (!location.checkPermissions()) {
            location.requestPermissions()
        } else {
            location.startRequestingLocation()
        }
    }

    private fun onHasPermission(
        result: Result,
        location: FlutterLocation,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(1)
            return
        }

        // permissionStatusCode() returns 1 (granted), 3 (grantedLimited,
        // approximate-only on API 31+) or 0 (denied) (#736).
        result.success(location.permissionStatusCode())
    }

    private fun onServiceEnabled(
        result: Result,
        location: FlutterLocation,
    ) {
        try {
            result.success(if (location.checkServiceEnabled()) 1 else 0)
        } catch (e: Exception) {
            result.error("SERVICE_STATUS_ERROR", "Location service status couldn't be determined", null)
        }
    }

    private fun onRequestPermission(
        result: Result,
        location: FlutterLocation,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(1)
            return
        }

        location.result = result
        location.requestPermissions()
    }

    private fun isBackgroundModeEnabled(result: Result) {
        val locationService = this.locationService
        if (locationService != null) {
            result.success(if (locationService.isInForegroundMode()) 1 else 0)
        } else {
            result.success(0)
        }
    }

    private fun enableBackgroundMode(
        call: MethodCall,
        result: Result,
    ) {
        val enable = call.argument<Boolean>("enable")
        val locationService = this.locationService
        if (locationService != null && enable != null) {
            if (locationService.checkBackgroundPermissions()) {
                if (enable) {
                    locationService.enableBackgroundMode()
                    result.success(1)
                } else {
                    locationService.disableBackgroundMode()
                    result.success(0)
                }
            } else {
                if (enable) {
                    locationService.result = result
                    locationService.requestBackgroundPermissions()
                } else {
                    locationService.disableBackgroundMode()
                    result.success(0)
                }
            }
        } else {
            result.success(0)
        }
    }

    private fun onChangeNotificationOptions(
        call: MethodCall,
        result: Result,
    ) {
        try {
            val channelName = call.argument<String>("channelName") ?: DEFAULT_CHANNEL_NAME
            val title = call.argument<String>("title") ?: DEFAULT_NOTIFICATION_TITLE
            val iconName = call.argument<String>("iconName") ?: DEFAULT_NOTIFICATION_ICON_NAME
            val subtitle = call.argument<String>("subtitle")
            val description = call.argument<String>("description")
            val onTapBringToFront = call.argument<Boolean>("onTapBringToFront") ?: false

            val hexColor = call.argument<String>("color")
            val color = hexColor?.let { Color.parseColor(it) }

            val options =
                NotificationOptions(
                    channelName,
                    title,
                    iconName,
                    subtitle,
                    description,
                    color,
                    onTapBringToFront,
                )
            val notificationMeta = locationService?.changeNotificationOptions(options)
            result.success(notificationMeta)
        } catch (e: Exception) {
            result.error(
                "CHANGE_NOTIFICATION_OPTIONS_ERROR",
                "An unexpected error happened during notification options change:" + e.message,
                null,
            )
        }
    }

    companion object {
        private const val TAG = "MethodCallHandlerImpl"
    }
}
