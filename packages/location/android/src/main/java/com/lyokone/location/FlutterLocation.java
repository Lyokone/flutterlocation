package com.lyokone.location;

import android.Manifest;
import android.annotation.TargetApi;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationManager;
import android.location.OnNmeaMessageListener;
import android.os.Build;
import android.os.Bundle;
import android.os.Looper;
import android.util.Log;
import android.util.SparseArray;

import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;

import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.ResolvableApiException;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.LocationSettingsRequest;
import com.google.android.gms.location.LocationSettingsStatusCodes;
import com.google.android.gms.location.SettingsClient;

import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import org.jetbrains.annotations.NotNull;

import java.util.HashMap;

public class FlutterLocation
        implements PluginRegistry.RequestPermissionsResultListener, PluginRegistry.ActivityResultListener {
    private static final String TAG = "FlutterLocation";

    @Nullable
    public Activity activity;

    private static final int REQUEST_PERMISSIONS_REQUEST_CODE = 34;
    private static final int REQUEST_CHECK_SETTINGS = 0x1;

    private static final int GPS_ENABLE_REQUEST = 0x1001;

    public FusedLocationProviderClient mFusedLocationClient;
    private SettingsClient mSettingsClient;
    private LocationRequest mLocationRequest;
    private LocationSettingsRequest mLocationSettingsRequest;
    public LocationCallback mLocationCallback;

    @TargetApi(Build.VERSION_CODES.N)
    private OnNmeaMessageListener mMessageListener;

    private Double mLastMslAltitude;

    // Parameters of the request
    private long updateIntervalMilliseconds = 5000;
    private long fastestUpdateIntervalMilliseconds = updateIntervalMilliseconds / 2;
    private Integer locationAccuracy = LocationRequest.PRIORITY_HIGH_ACCURACY;
    private float distanceFilter = 0f;

    public EventSink events;

    // Store result until a permission check is resolved
    public Result result;

    // Store the result for the requestService, used in ActivityResult
    private Result requestServiceResult;

    // Store result until a location is getting resolved
    public Result getLocationResult;

    private final LocationManager locationManager;

    public SparseArray<Integer> mapFlutterAccuracy = new SparseArray<Integer>() {
        {
            put(0, LocationRequest.PRIORITY_NO_POWER);
            put(1, LocationRequest.PRIORITY_LOW_POWER);
            put(2, LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY);
            put(3, LocationRequest.PRIORITY_HIGH_ACCURACY);
            put(4, LocationRequest.PRIORITY_HIGH_ACCURACY);
            put(5, LocationRequest.PRIORITY_LOW_POWER);
        }
    };

    FlutterLocation(Context applicationContext, @Nullable Activity activity) {
        this.activity = activity;
        this.locationManager = (LocationManager) applicationContext.getSystemService(Context.LOCATION_SERVICE);
    }

    void setActivity(@Nullable Activity activity) {
        this.activity = activity;
        if (this.activity != null) {
            mFusedLocationClient = LocationServices.getFusedLocationProviderClient(activity);
            mSettingsClient = LocationServices.getSettingsClient(activity);

            createLocationCallback();
            createLocationRequest();
            buildLocationSettingsRequest();
        } else {
            if (mFusedLocationClient != null) {
                mFusedLocationClient.removeLocationUpdates(mLocationCallback);
            }
            mFusedLocationClient = null;
            mSettingsClient = null;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && locationManager != null) {
                locationManager.removeNmeaListener(mMessageListener);
                mMessageListener = null;
            }
        }
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, @NotNull String[] permissions, @NotNull int[] grantResults) {
        return onRequestPermissionsResultHandler(requestCode, permissions, grantResults);
    }

    public boolean onRequestPermissionsResultHandler(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == REQUEST_PERMISSIONS_REQUEST_CODE && permissions.length == 1
                && permissions[0].equals(Manifest.permission.ACCESS_FINE_LOCATION)) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Checks if this permission was automatically triggered by a location request
                if (getLocationResult != null || events != null) {
                    startRequestingLocation();
                }
                if (result != null) {
                    result.success(1);
                    result = null;
                }
            } else {
                if (!shouldShowRequestPermissionRationale()) {
                    sendError("PERMISSION_DENIED_NEVER_ASK",
                            "Location permission denied forever - please open app settings", null);
                    if (result != null) {
                        result.success(2);
                        result = null;
                    }
                } else {
                    sendError("PERMISSION_DENIED", "Location permission denied", null);
                    if (result != null) {
                        result.success(0);
                        result = null;
                    }
                }
            }
            return true;
        }
        return false;

    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        switch (requestCode) {
            case GPS_ENABLE_REQUEST:
                if (this.requestServiceResult == null) {
                    return false;
                }
                if (resultCode == Activity.RESULT_OK) {
                    this.requestServiceResult.success(1);
                } else {
                    this.requestServiceResult.success(0);
                }
                this.requestServiceResult = null;
                return true;
            case REQUEST_CHECK_SETTINGS:
                if (this.result == null) {
                    return false;
                }
                if (resultCode == Activity.RESULT_OK) {
                    startRequestingLocation();
                    return true;
                }

                this.result.error("SERVICE_STATUS_DISABLED", "Failed to get location. Location services disabled", null);
                this.result = null;
                return true;
            default:
                return false;
        }
    }

    public void changeSettings(Integer newLocationAccuracy, Long updateIntervalMilliseconds,
                               Long fastestUpdateIntervalMilliseconds, Float distanceFilter) {
        this.locationAccuracy = newLocationAccuracy;
        this.updateIntervalMilliseconds = updateIntervalMilliseconds;
        this.fastestUpdateIntervalMilliseconds = fastestUpdateIntervalMilliseconds;
        this.distanceFilter = distanceFilter;

        createLocationCallback();
        createLocationRequest();
        buildLocationSettingsRequest();
        startRequestingLocation();
    }

    private void sendError(String errorCode, String errorMessage, Object errorDetails) {
        if (getLocationResult != null) {
            getLocationResult.error(errorCode, errorMessage, errorDetails);
            getLocationResult = null;
        }
        if (events != null) {
            events.error(errorCode, errorMessage, errorDetails);
            events = null;
        }
    }

    /**
     * Creates a callback for receiving location events.
     */
    private void createLocationCallback() {
        if (mLocationCallback != null) {
            mFusedLocationClient.removeLocationUpdates(mLocationCallback);
            mLocationCallback = null;
        }
        mLocationCallback = new LocationCallback() {
            @Override
            public void onLocationResult(LocationResult locationResult) {
                super.onLocationResult(locationResult);
                Location location = locationResult.getLastLocation();
                HashMap<String, Object> loc = new HashMap<>();
                loc.put("latitude", location.getLatitude());
                loc.put("longitude", location.getLongitude());
                loc.put("accuracy", (double) location.getAccuracy());
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    loc.put("verticalAccuracy", (double) location.getVerticalAccuracyMeters());
                    loc.put("headingAccuracy", (double) location.getBearingAccuracyDegrees());
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    loc.put("elapsedRealtimeUncertaintyNanos", (double) location.getElapsedRealtimeUncertaintyNanos());
                }

                loc.put("provider", location.getProvider());
                final Bundle extras = location.getExtras();
                if (extras != null) {
                    loc.put("satelliteNumber", location.getExtras().getInt("satellites"));
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                    loc.put("elapsedRealtimeNanos", (double) location.getElapsedRealtimeNanos());

                    if (location.isFromMockProvider()) {
                        loc.put("isMock", (double) 1);
                    }
                } else {
                    loc.put("isMock", (double) 0);
                }

                // Using NMEA Data to get MSL level altitude
                if (mLastMslAltitude == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
                    loc.put("altitude", location.getAltitude());
                } else {
                    loc.put("altitude", mLastMslAltitude);
                }

                loc.put("speed", (double) location.getSpeed());
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    loc.put("speed_accuracy", (double) location.getSpeedAccuracyMetersPerSecond());
                }
                loc.put("heading", (double) location.getBearing());
                loc.put("time", (double) location.getTime());

                if (getLocationResult != null) {
                    getLocationResult.success(loc);
                    getLocationResult = null;
                }
                if (events != null) {
                    events.success(loc);
                } else {
                    if (mFusedLocationClient != null) {
                        mFusedLocationClient.removeLocationUpdates(mLocationCallback);
                    }
                }
            }
        };

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            mMessageListener = (message, timestamp) -> {
                if (message.startsWith("$")) {
                    String[] tokens = message.split(",");
                    String type = tokens[0];

                    // Parse altitude above sea level, Detailed description of NMEA string here
                    // http://aprs.gids.nl/nmea/#gga
                    if (type.startsWith("$GPGGA") && tokens.length > 9) {
                        if (!tokens[9].isEmpty()) {
                            mLastMslAltitude = Double.parseDouble(tokens[9]);
                        }
                    }
                }
            };
        }
    }

    /**
     * Sets up the location request. Android has two location request settings:
     */
    private void createLocationRequest() {
        mLocationRequest = LocationRequest.create();

        mLocationRequest.setInterval(this.updateIntervalMilliseconds);
        mLocationRequest.setFastestInterval(this.fastestUpdateIntervalMilliseconds);
        mLocationRequest.setPriority(this.locationAccuracy);
        mLocationRequest.setSmallestDisplacement(this.distanceFilter);
    }

    /**
     * Uses a
     * {@link com.google.android.gms.location.LocationSettingsRequest.Builder} to
     * build a {@link com.google.android.gms.location.LocationSettingsRequest} that
     * is used for checking if a device has the needed location settings.
     */
    private void buildLocationSettingsRequest() {
        LocationSettingsRequest.Builder builder = new LocationSettingsRequest.Builder();
        builder.addLocationRequest(mLocationRequest);
        mLocationSettingsRequest = builder.build();
    }

    /**
     * Return the current state of the permissions needed.
     */
    public boolean checkPermissions() {
        if (this.activity == null) {
            result.error("MISSING_ACTIVITY", "You should not checkPermissions activation outside of an activity.", null);
            throw new ActivityNotFoundException();
        }
        int locationPermissionState = ActivityCompat.checkSelfPermission(activity,
                Manifest.permission.ACCESS_FINE_LOCATION);
        return locationPermissionState == PackageManager.PERMISSION_GRANTED;
    }

    public void requestPermissions() {
        if (this.activity == null) {
            result.error("MISSING_ACTIVITY", "You should not requestPermissions activation outside of an activity.", null);
            throw new ActivityNotFoundException();
        }
        if (checkPermissions()) {
            result.success(1);
            return;
        }
        ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.ACCESS_FINE_LOCATION},
                REQUEST_PERMISSIONS_REQUEST_CODE);
    }

    public boolean shouldShowRequestPermissionRationale() {
        if (activity == null) {
            return false;
        }
        return ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.ACCESS_FINE_LOCATION);
    }

    /**
     * Checks whether location services is enabled.
     */
    public boolean checkServiceEnabled() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            return locationManager.isLocationEnabled();
        }

        boolean gps_enabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER);
        boolean network_enabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER);

        return gps_enabled || network_enabled;
    }

    public void requestService(final Result requestServiceResult) {
        if (this.activity == null) {
            requestServiceResult.error("MISSING_ACTIVITY", "You should not requestService activation outside of an activity.", null);
            throw new ActivityNotFoundException();
        }
        try {
            if (this.checkServiceEnabled()) {
                requestServiceResult.success(1);
                return;
            }
        } catch (Exception e) {
            requestServiceResult.error("SERVICE_STATUS_ERROR", "Location service status couldn't be determined", null);
            return;
        }

        this.requestServiceResult = requestServiceResult;
        mSettingsClient.checkLocationSettings(mLocationSettingsRequest).addOnFailureListener(activity,
                e -> {
                    if (e instanceof ResolvableApiException) {
                        ResolvableApiException rae = (ResolvableApiException) e;
                        int statusCode = rae.getStatusCode();
                        switch (statusCode) {
                            case LocationSettingsStatusCodes.RESOLUTION_REQUIRED:
                                try {
                                    // Show the dialog by calling startResolutionForResult(), and check the
                                    // result in onActivityResult().
                                    rae.startResolutionForResult(activity, GPS_ENABLE_REQUEST);
                                } catch (IntentSender.SendIntentException sie) {
                                    requestServiceResult.error("SERVICE_STATUS_ERROR", "Could not resolve location request",
                                            null);
                                }
                                break;
                            case LocationSettingsStatusCodes.SETTINGS_CHANGE_UNAVAILABLE:
                                requestServiceResult.error("SERVICE_STATUS_DISABLED",
                                        "Failed to get location. Location services disabled", null);
                                break;
                        }
                    } else {
                        // This should not happen according to Android documentation but it has been
                        // observed on some phones.
                        requestServiceResult.error("SERVICE_STATUS_ERROR", "Unexpected error type received", null);
                    }
                });
    }

    public void startRequestingLocation() {
        if (this.activity == null) {
            result.error("MISSING_ACTIVITY", "You should not requestLocation activation outside of an activity.", null);
            throw new ActivityNotFoundException();
        }
        mSettingsClient.checkLocationSettings(mLocationSettingsRequest)
                .addOnSuccessListener(activity, locationSettingsResponse -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        locationManager.addNmeaListener(mMessageListener, null);
                    }

                    if (mFusedLocationClient != null) {
                        mFusedLocationClient
                                .requestLocationUpdates(mLocationRequest, mLocationCallback, Looper.myLooper());
                    }
                }).addOnFailureListener(activity, e -> {
                    if (e instanceof ResolvableApiException) {
                        ResolvableApiException rae = (ResolvableApiException) e;
                        int statusCode = rae.getStatusCode();
                        if (statusCode == LocationSettingsStatusCodes.RESOLUTION_REQUIRED) {
                            try {
                                // Show the dialog by calling startResolutionForResult(), and check the
                                // result in onActivityResult().
                                rae.startResolutionForResult(activity, REQUEST_CHECK_SETTINGS);
                            } catch (IntentSender.SendIntentException sie) {
                                Log.i(TAG, "PendingIntent unable to execute request.");
                            }
                        }
                    } else {
                        ApiException ae = (ApiException) e;
                        int statusCode = ae.getStatusCode();
                        if (statusCode == LocationSettingsStatusCodes.SETTINGS_CHANGE_UNAVAILABLE) {// This error code happens during AirPlane mode.
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                locationManager.addNmeaListener(mMessageListener, null);
                            }
                            mFusedLocationClient.requestLocationUpdates(mLocationRequest, mLocationCallback,
                                    Looper.myLooper());
                        } else {// This should not happen according to Android documentation but it has been
                            // observed on some phones.
                            sendError("UNEXPECTED_ERROR", e.getMessage(), null);
                        }
                    }
                });
    }

}
