package com.lyokone.location;

import android.Manifest;
import android.app.Activity;
import android.content.IntentSender;
import android.content.pm.PackageManager;
import android.location.Location;
import android.os.Build;
import android.os.Looper;
import androidx.annotation.MainThread;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import android.util.Log;

import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.ResolvableApiException;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationSettingsRequest;
import com.google.android.gms.location.LocationSettingsResponse;
import com.google.android.gms.location.LocationSettingsStatusCodes;
import com.google.android.gms.location.SettingsClient;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.OnFailureListener;

import java.util.HashMap;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * LocationPlugin
 */
public class LocationPlugin implements MethodCallHandler, StreamHandler {
    private static final String STREAM_CHANNEL_NAME = "lyokone/locationstream";
    private static final String METHOD_CHANNEL_NAME = "lyokone/location";

    private static final int REQUEST_PERMISSIONS_REQUEST_CODE = 34;
    private static final int REQUEST_CHECK_SETTINGS = 0x1;
    private static final long UPDATE_INTERVAL_IN_MILLISECONDS = 10000;
    private static final long FASTEST_UPDATE_INTERVAL_IN_MILLISECONDS = UPDATE_INTERVAL_IN_MILLISECONDS / 2;

    private final FusedLocationProviderClient mFusedLocationClient;
    private final SettingsClient mSettingsClient;
    private LocationRequest mLocationRequest;
    private LocationSettingsRequest mLocationSettingsRequest;
    private LocationCallback mLocationCallback;
    private PluginRegistry.RequestPermissionsResultListener mPermissionsResultListener;

    private EventSink events;
    private Result result;

    private final Activity activity;

    LocationPlugin(Activity activity) {
        this.activity = activity;
        mFusedLocationClient = LocationServices.getFusedLocationProviderClient(activity);
        mSettingsClient = LocationServices.getSettingsClient(activity);
        createLocationCallback();
        createLocationRequest();
        createPermissionsResultListener();
        buildLocationSettingsRequest();
    }

    public PluginRegistry.RequestPermissionsResultListener getPermissionsResultListener() {
        return mPermissionsResultListener;
    }

    private void createPermissionsResultListener() {
        mPermissionsResultListener = new PluginRegistry.RequestPermissionsResultListener() {
            @Override
            public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
                if (requestCode == REQUEST_PERMISSIONS_REQUEST_CODE && permissions.length == 1 && permissions[0].equals(Manifest.permission.ACCESS_FINE_LOCATION)) {
                    if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                        if (result != null) {
                            getLastLocation(result);
                        } else if (events != null) {
                            getLastLocation(null);
                        }
                    } else {
                        if (!shouldShowRequestPermissionRationale()) {
                            if (result != null) {
                                result.error("PERMISSION_DENIED_NEVER_ASK", "Location permission denied forever- please open app settings", null);
                            } else if (events != null) {
                                events.error("PERMISSION_DENIED_NEVER_ASK", "Location permission denied forever - please open app settings", null);
                                events = null;
                            }
                        } else {
                            if (result != null) {
                                result.error("PERMISSION_DENIED", "Location permission denied", null);
                            } else if (events != null) {
                                events.error("PERMISSION_DENIED", "Location permission denied", null);
                                events = null;
                            }
                        }
                    }
                    return true;
                }

                return false;
            }
        };
    }

    /**
     * Creates a callback for receiving location events.
     */
    private void createLocationCallback() {
        mLocationCallback = new LocationCallback() {
            @Override
            public void onLocationResult(LocationResult locationResult) {
                super.onLocationResult(locationResult);
                Location location = locationResult.getLastLocation();
                HashMap<String, Double> loc = new HashMap<>();
                loc.put("latitude", location.getLatitude());
                loc.put("longitude", location.getLongitude());
                loc.put("accuracy", (double) location.getAccuracy());
                loc.put("altitude", location.getAltitude());
                loc.put("speed", (double) location.getSpeed());
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    loc.put("speed_accuracy", (double) location.getSpeedAccuracyMetersPerSecond());
                }
                if (events != null) {
                    events.success(loc);
                }
            }
        };
    }

    /**
     * Sets up the location request. Android has two location request settings:
     * {@code ACCESS_COARSE_LOCATION} and {@code ACCESS_FINE_LOCATION}. These settings control
     * the accuracy of the current location. This sample uses ACCESS_FINE_LOCATION, as defined in
     * the AndroidManifest.xml.
     * <p/>
     * When the ACCESS_FINE_LOCATION setting is specified, combined with a fast update
     * interval (5 seconds), the Fused Location Provider API returns location updates that are
     * accurate to within a few feet.
     * <p/>
     * These settings are appropriate for mapping applications that show real-time location
     * updates.
     */
    private void createLocationRequest() {
        mLocationRequest = LocationRequest.create();

        // Sets the desired interval for active location updates. This interval is
        // inexact. You may not receive updates at all if no location sources are available, or
        // you may receive them slower than requested. You may also receive updates faster than
        // requested if other applications are requesting location at a faster interval.
        mLocationRequest.setInterval(UPDATE_INTERVAL_IN_MILLISECONDS);

        // Sets the fastest rate for active location updates. This interval is exact, and your
        // application will never receive updates faster than this value.
        mLocationRequest.setFastestInterval(FASTEST_UPDATE_INTERVAL_IN_MILLISECONDS);

        mLocationRequest.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);
    }

    /**
     * Uses a {@link com.google.android.gms.location.LocationSettingsRequest.Builder} to build
     * a {@link com.google.android.gms.location.LocationSettingsRequest} that is used for checking
     * if a device has the needed location settings.
     */
    private void buildLocationSettingsRequest() {
        LocationSettingsRequest.Builder builder = new LocationSettingsRequest.Builder();
        builder.addLocationRequest(mLocationRequest);
        mLocationSettingsRequest = builder.build();
    }

    /**
     * Return the current state of the permissions needed.
     */
    private boolean checkPermissions() {
        int permissionState = ActivityCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION);
        return permissionState == PackageManager.PERMISSION_GRANTED;
    }

    private void requestPermissions() {
        ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.ACCESS_FINE_LOCATION},
                REQUEST_PERMISSIONS_REQUEST_CODE);
    }

    private boolean shouldShowRequestPermissionRationale() {
        return ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.ACCESS_FINE_LOCATION);
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), METHOD_CHANNEL_NAME);
        LocationPlugin locationWithMethodChannel = new LocationPlugin(registrar.activity());
        channel.setMethodCallHandler(locationWithMethodChannel);
        registrar.addRequestPermissionsResultListener(locationWithMethodChannel.getPermissionsResultListener());

        final EventChannel eventChannel = new EventChannel(registrar.messenger(), STREAM_CHANNEL_NAME);
        LocationPlugin locationWithEventChannel = new LocationPlugin(registrar.activity());
        eventChannel.setStreamHandler(locationWithEventChannel);
        registrar.addRequestPermissionsResultListener(locationWithEventChannel.getPermissionsResultListener());
    }

    private void getLastLocation(final Result result) {

        mFusedLocationClient.getLastLocation().addOnSuccessListener(new OnSuccessListener<Location>() {
            @Override
            public void onSuccess(Location location) {
                if (location != null) {
                    HashMap<String, Double> loc = new HashMap<String, Double>();
                    loc.put("latitude", location.getLatitude());
                    loc.put("longitude", location.getLongitude());
                    loc.put("accuracy", (double) location.getAccuracy());
                    loc.put("altitude", location.getAltitude());
                    loc.put("speed", (double) location.getSpeed());
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        loc.put("speed_accuracy", (double) location.getSpeedAccuracyMetersPerSecond());
                    }
                    loc.put("heading", (double) location.getBearing());

                    if (result != null) {
                        result.success(loc);
                        return;
                    }
                    if (events != null) {
                        events.success(loc);
                    }
                } else {
                    if (result != null) {
                        result.error("ERROR", "Failed to get location.", null);
                        return;
                    }
                    // Do not send error on events otherwise it will produce an error
                }
            }
        });
    }

    @Override
    public void onMethodCall(MethodCall call, final Result result) {
        if (call.method.equals("getLocation")) {
            if (!checkPermissions()) {
                this.result = result;
                requestPermissions();
                return;
            }
            getLastLocation(result);
        } else if(call.method.equals("hasPermission")) {
            if(checkPermissions()) {
                result.success(1);
            } else {
                result.error("PERMISSION_DENIED", "The user explicitly denied the use of location services for this app or location services are currently disabled in Settings.", null);
            }
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onListen(Object arguments, final EventSink eventsSink) {
        events = eventsSink;
        if (!checkPermissions()) {
            requestPermissions();
            return;
        }
        getLastLocation(null);
        /**
         * Requests location updates from the FusedLocationApi. Note: we don't call this unless location
         * runtime permission has been granted.
         */
        mSettingsClient.checkLocationSettings(mLocationSettingsRequest)
                .addOnSuccessListener(activity, new OnSuccessListener<LocationSettingsResponse>() {
                    @Override
                    public void onSuccess(LocationSettingsResponse locationSettingsResponse) {
                        mFusedLocationClient.requestLocationUpdates(mLocationRequest, mLocationCallback,
                                Looper.myLooper());
                    }
                }).addOnFailureListener(activity, new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
                int statusCode = ((ApiException) e).getStatusCode();
                switch (statusCode) {
                    case LocationSettingsStatusCodes.RESOLUTION_REQUIRED:
                        try {
                            // Show the dialog by calling startResolutionForResult(), and check the
                            // result in onActivityResult().
                            ResolvableApiException rae = (ResolvableApiException) e;
                            rae.startResolutionForResult(activity, REQUEST_CHECK_SETTINGS);
                        } catch (IntentSender.SendIntentException sie) {
                            Log.i(METHOD_CHANNEL_NAME, "PendingIntent unable to execute request.");
                        }
                        break;
                    case LocationSettingsStatusCodes.SETTINGS_CHANGE_UNAVAILABLE:
                        String errorMessage = "Location settings are inadequate, and cannot be "
                                + "fixed here. Fix in Settings.";
                        Log.e(METHOD_CHANNEL_NAME, errorMessage);
                }
            }
        });
    }

    @Override
    public void onCancel(Object arguments) {
        mFusedLocationClient.removeLocationUpdates(mLocationCallback);
        events = null;
    }
}
