package com.lyokone.location;

import android.graphics.Color;
import android.os.Build;
import android.util.Log;

import androidx.annotation.Nullable;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

final class MethodCallHandlerImpl implements MethodCallHandler {
    private static final String TAG = "MethodCallHandlerImpl";

    private FlutterLocation location;
    private FlutterLocationService locationService;

    @Nullable
    private MethodChannel channel;

    private static final String METHOD_CHANNEL_NAME = "lyokone/location";

    void setLocation(FlutterLocation location) {
        this.location = location;
    }

    void setLocationService(FlutterLocationService locationService) {
        this.locationService = locationService;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "changeSettings":
                onChangeSettings(call, result);
                break;
            case "getLocation":
                onGetLocation(result);
                break;
            case "hasPermission":
                onHasPermission(result);
                break;
            case "requestPermission":
                onRequestPermission(result);
                break;
            case "serviceEnabled":
                onServiceEnabled(result);
                break;
            case "requestService":
                location.requestService(result);
                break;
            case "isBackgroundModeEnabled":
                isBackgroundModeEnabled(result);
                break;
            case "enableBackgroundMode":
                enableBackgroundMode(call, result);
                break;
            case "changeNotificationOptions":
                onChangeNotificationOptions(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    /**
     * Registers this instance as a method call handler on the given
     * {@code messenger}.
     */
    void startListening(BinaryMessenger messenger) {
        if (channel != null) {
            Log.wtf(TAG, "Setting a method call handler before the last was disposed.");
            stopListening();
        }

        channel = new MethodChannel(messenger, METHOD_CHANNEL_NAME);
        channel.setMethodCallHandler(this);
    }

    /**
     * Clears this instance from listening to method calls.
     */
    void stopListening() {
        if (channel == null) {
            Log.d(TAG, "Tried to stop listening when no MethodChannel had been initialized.");
            return;
        }

        channel.setMethodCallHandler(null);
        channel = null;
    }

    private void onChangeSettings(MethodCall call, Result result) {
        try {
            final Integer locationAccuracy = location.mapFlutterAccuracy.get((Integer) call.argument("accuracy"));
            final Long updateIntervalMilliseconds = new Long((int) call.argument("interval"));
            final Long fastestUpdateIntervalMilliseconds = updateIntervalMilliseconds / 2;
            final Float distanceFilter = new Float((double) call.argument("distanceFilter"));

            location.changeSettings(locationAccuracy, updateIntervalMilliseconds, fastestUpdateIntervalMilliseconds,
                    distanceFilter);

            result.success(1);
        } catch (Exception e) {
            result.error("CHANGE_SETTINGS_ERROR",
                    "An unexcepted error happened during location settings change:" + e.getMessage(), null);
        }
    }

    private void onGetLocation(Result result) {
        location.getLocationResult = result;
        if (!location.checkPermissions()) {
            location.requestPermissions();
        } else {
            location.startRequestingLocation();
        }
    }

    private void onHasPermission(Result result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(1);
            return;
        }

        if (location.checkPermissions()) {
            result.success(1);
        } else {
            result.success(0);
        }
    }

    private void onServiceEnabled(Result result) {
        try {
            result.success(location.checkServiceEnabled() ? 1 : 0);
        } catch (Exception e) {
            result.error("SERVICE_STATUS_ERROR", "Location service status couldn't be determined", null);
        }
    }

    private void onRequestPermission(Result result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(1);
            return;
        }

        location.result = result;
        location.requestPermissions();
    }

    private void isBackgroundModeEnabled(Result result) {
        if (locationService != null) {
            result.success(this.locationService.isInForegroundMode() ? 1 : 0);
        } else {
            result.success(0);
        }
    }

    private void enableBackgroundMode(MethodCall call, Result result) {
        final Boolean enable = call.argument("enable");
        if (locationService != null && enable != null) {
            if (locationService.checkBackgroundPermissions()) {
                if (enable) {
                    locationService.enableBackgroundMode();

                    result.success(1);
                } else {
                    locationService.disableBackgroundMode();

                    result.success(0);
                }
            } else {
                if (enable) {
                    locationService.setResult(result);
                    locationService.requestBackgroundPermissions();
                } else {
                    locationService.disableBackgroundMode();

                    result.success(0);
                }
            }
        } else {
            result.success(0);
        }
    }

    private void onChangeNotificationOptions(MethodCall call, Result result) {
        try {
            String passedChannelName = call.argument("channelName");
            String channelName = passedChannelName != null
                    ? passedChannelName
                    : FlutterLocationServiceKt.kDefaultChannelName;

            String passedTitle = call.argument("title");
            String title = passedTitle != null
                    ? passedTitle
                    : FlutterLocationServiceKt.kDefaultNotificationTitle;

            String passedIconName = call.argument("iconName");
            String iconName = passedIconName != null
                    ? passedIconName
                    : FlutterLocationServiceKt.kDefaultNotificationIconName;

            String subtitle = call.argument("subtitle");
            String description = call.argument("description");
            Boolean onTapBringToFront = call.argument("onTapBringToFront");
            if (onTapBringToFront == null) {
                onTapBringToFront = false;
            }

            String hexColor = call.argument("color");
            Integer color = null;
            if (hexColor != null) {
                color = Color.parseColor(hexColor);
            }

            NotificationOptions options = new NotificationOptions(
                    channelName,
                    title,
                    iconName,
                    subtitle,
                    description,
                    color,
                    onTapBringToFront);
            Map<String, Object> notificationMeta = this.locationService.changeNotificationOptions(options);
            result.success(notificationMeta);
        } catch (Exception e) {
            result.error("CHANGE_NOTIFICATION_OPTIONS_ERROR",
                    "An unexpected error happened during notification options change:" + e.getMessage(), null);
        }
    }
}
