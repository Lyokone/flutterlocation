package com.lyokone.location;

import android.Manifest;
import android.app.Activity;
import android.provider.Settings;
import android.content.IntentSender;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationManager;
import android.location.OnNmeaMessageListener;
import android.content.Context;
import android.os.Build;
import android.os.Looper;
import androidx.annotation.MainThread;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import android.util.Log;
import android.annotation.TargetApi;

import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.Status;

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

import java.util.ArrayList;
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
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener;

/**
 * LocationPlugin
 */
public class LocationPlugin implements MethodCallHandler, StreamHandler, PluginRegistry.ActivityResultListener {
    private static final String STREAM_CHANNEL_NAME = "lyokone/locationstream";
    private static final String METHOD_CHANNEL_NAME = "lyokone/location";

    private static final int REQUEST_PERMISSIONS_REQUEST_CODE = 34;
    private static final int REQUEST_CHECK_SETTINGS = 0x1;

    private static final int GPS_ENABLE_REQUEST = 0x1001;

    private final FusedLocationProviderClient mFusedLocationClient;
    private final SettingsClient mSettingsClient;
    private static LocationRequest mLocationRequest;
    private LocationSettingsRequest mLocationSettingsRequest;
    private LocationCallback mLocationCallback;
    private PluginRegistry.RequestPermissionsResultListener mPermissionsResultListener;

    @TargetApi(Build.VERSION_CODES.N)
    private OnNmeaMessageListener mMessageListener;

    private Double mLastMslAltitude;

    // Parameters of the request
    private static long update_interval_in_milliseconds = 5000;
    private static long fastest_update_interval_in_milliseconds = update_interval_in_milliseconds / 2;
    private static Integer location_accuray = LocationRequest.PRIORITY_HIGH_ACCURACY;
    private static float distanceFilter = 0f;

    private EventSink events;
    private Result result;

    private int locationPermissionState;

    private final Activity activity;

    private boolean waitingForPermission = false;
    private LocationManager locationManager;


    private HashMap<Integer, Integer> mapFlutterAccuracy = new HashMap<>();

    LocationPlugin(Activity activity) {
        this.activity = activity;
        mFusedLocationClient = LocationServices.getFusedLocationProviderClient(activity);
        mSettingsClient = LocationServices.getSettingsClient(activity);
        locationManager = (LocationManager) activity.getSystemService(Context.LOCATION_SERVICE);

        this.mapFlutterAccuracy.put(0, LocationRequest.PRIORITY_NO_POWER);
        this.mapFlutterAccuracy.put(1, LocationRequest.PRIORITY_LOW_POWER);
        this.mapFlutterAccuracy.put(2, LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY);
        this.mapFlutterAccuracy.put(3, LocationRequest.PRIORITY_HIGH_ACCURACY);
        this.mapFlutterAccuracy.put(4, LocationRequest.PRIORITY_HIGH_ACCURACY);

        createLocationCallback();
        createLocationRequest();
        createPermissionsResultListener();
        buildLocationSettingsRequest();
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        if(registrar.activity() != null) {
            final MethodChannel channel = new MethodChannel(registrar.messenger(), METHOD_CHANNEL_NAME);
            LocationPlugin locationWithMethodChannel = new LocationPlugin(registrar.activity());
            channel.setMethodCallHandler(locationWithMethodChannel);
            registrar.addRequestPermissionsResultListener(locationWithMethodChannel.getPermissionsResultListener());
            registrar.addActivityResultListener(locationWithMethodChannel);

            final EventChannel eventChannel = new EventChannel(registrar.messenger(), STREAM_CHANNEL_NAME);
            LocationPlugin locationWithEventChannel = new LocationPlugin(registrar.activity());
            eventChannel.setStreamHandler(locationWithEventChannel);
            registrar.addRequestPermissionsResultListener(locationWithEventChannel.getPermissionsResultListener());
        }
    }

    @Override
    public void onMethodCall(MethodCall call, final Result result) {
        if (call.method.equals("changeSettings")) {
            try {
                this.location_accuray = this.mapFlutterAccuracy.get(call.argument("accuracy"));
                this.update_interval_in_milliseconds = new Long((int) call.argument("interval"));
                this.fastest_update_interval_in_milliseconds = this.update_interval_in_milliseconds / 2;
                
                this.distanceFilter = new Float((double) call.argument("distanceFilter"));

                createLocationCallback();
                createLocationRequest();
                createPermissionsResultListener();
                buildLocationSettingsRequest();
                result.success(1);
            } catch(Exception e) {
                result.error("CHANGE_SETTINGS_ERROR", "An unexcepted error happened during location settings change:" + e.getMessage(), null);
            }

        } else if (call.method.equals("getLocation")) {
            this.result = result;
            if (!checkPermissions()) {
                requestPermissions();
            } else {
                startRequestingLocation();
            }

        } else if (call.method.equals("hasPermission")) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                result.success(1);
                return;
            }

            if (checkPermissions()) {
                result.success(1);
            } else {
                result.success(0);
            }
        } else if (call.method.equals("requestPermission")) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                result.success(1);
                return;
            }
            
            this.waitingForPermission = true;
            this.result = result;
            requestPermissions();
        } else if (call.method.equals("serviceEnabled")) {
            checkServiceEnabled(result);
        } else if (call.method.equals("requestService")) {
            requestService(result);
        } else {
            result.notImplemented();
        }
    }

    public PluginRegistry.RequestPermissionsResultListener getPermissionsResultListener() {
        return mPermissionsResultListener;
    }

    private void createPermissionsResultListener() {
        mPermissionsResultListener = new PluginRegistry.RequestPermissionsResultListener() {
            @Override
            public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
                if (requestCode == REQUEST_PERMISSIONS_REQUEST_CODE && permissions.length == 1 && permissions[0].equals(Manifest.permission.ACCESS_FINE_LOCATION)) {
                    if (waitingForPermission) {
                        waitingForPermission = false;
                        if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                            result.success(1);
                        } else {
                            result.success(0);
                        }
                        result = null;
                    }
                    if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                        if (result != null) {
                            startRequestingLocation();
                        } else if (events != null) {
                            startRequestingLocation();
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

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        switch (requestCode) {
            case GPS_ENABLE_REQUEST:
                if (resultCode == Activity.RESULT_OK) {
                    this.result.success(1);
                } else {
                    this.result.success(0);
                }
                break;
            default:
                return false;
            }
        return true;
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

                if (result != null) {
                    result.success(loc);
                    result = null;
                }
                if (events != null) {
                    events.success(loc);
                } else {
                    mFusedLocationClient.removeLocationUpdates(mLocationCallback);
                }
            }
        };

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) { 
            mMessageListener = new OnNmeaMessageListener() {
            @Override
            public void onNmeaMessage(String message, long timestamp) {
                if (message.startsWith("$")) {
                    String[] tokens = message.split(",");
                    String type = tokens[0];

                    // Parse altitude above sea level, Detailed description of NMEA string here
                    // http://aprs.gids.nl/nmea/#gga
                    if (type.startsWith("$GPGGA")) {
                        if (!tokens[9].isEmpty()) {
                            mLastMslAltitude = Double.parseDouble(tokens[9]);
                        }
                    }
                }
            }};
        }
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
        this.mLocationRequest = LocationRequest.create();

        // Sets the desired interval for active location updates. This interval is
        // inexact. You may not receive updates at all if no location sources are available, or
        // you may receive them slower than requested. You may also receive updates faster than
        // requested if other applications are requesting location at a faster interval.
        this.mLocationRequest.setInterval(this.update_interval_in_milliseconds);

        // Sets the fastest rate for active location updates. This interval is exact, and your
        // application will never receive updates faster than this value.
        this.mLocationRequest.setFastestInterval(this.fastest_update_interval_in_milliseconds);

        this.mLocationRequest.setPriority(this.location_accuray);
        this.mLocationRequest.setSmallestDisplacement(this.distanceFilter);
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
        this.locationPermissionState = ActivityCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION);
        return this.locationPermissionState == PackageManager.PERMISSION_GRANTED;
    }

    private void requestPermissions() {
        ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.ACCESS_FINE_LOCATION},
                REQUEST_PERMISSIONS_REQUEST_CODE);
    }

    private boolean shouldShowRequestPermissionRationale() {
        return ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.ACCESS_FINE_LOCATION);
    }


    public boolean checkServiceEnabled(final Result result) {
        boolean gps_enabled = false;
        boolean network_enabled = false;

        try {
            gps_enabled = this.locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER);
            network_enabled = this.locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER);
        } catch (Exception ex) {
            result.error("SERVICE_STATUS_ERROR", "Location service status couldn't be determined", null);
            return false;
        }
        if (gps_enabled || network_enabled) {
            if (result != null) {
                result.success(1);
            } 
            return true;
            
        } else {
            if (result != null) {
                result.success(0);
            } 
            return false;
        }
    }

    public void requestService(final Result result) {
        if (this.checkServiceEnabled(null)) {
            result.success(1);
            return;
        }
        this.result = result;
        mSettingsClient.checkLocationSettings(mLocationSettingsRequest)
            .addOnFailureListener(activity, new OnFailureListener() {
                @Override
                public void onFailure(@NonNull Exception e) {
                    int statusCode = ((ApiException) e).getStatusCode();
                    switch (statusCode) {
                    case LocationSettingsStatusCodes.RESOLUTION_REQUIRED:
                        try {
                            // Show the dialog by calling startResolutionForResult(), and check the
                            // result in onActivityResult().
                            ResolvableApiException rae = (ResolvableApiException) e;
                            rae.startResolutionForResult(activity, GPS_ENABLE_REQUEST);
                        } catch (IntentSender.SendIntentException sie) {
                            Log.i(METHOD_CHANNEL_NAME, "PendingIntent unable to execute request.");
                        }
                        break;
                    case LocationSettingsStatusCodes.SETTINGS_CHANGE_UNAVAILABLE:
                        result.error("SERVICE_STATUS_DISABLED",
                                "Failed to get location. Location services disabled", null);
                    }
                }
            });
    }

    public void startRequestingLocation() {
        mSettingsClient.checkLocationSettings(mLocationSettingsRequest)
                .addOnSuccessListener(activity, new OnSuccessListener<LocationSettingsResponse>() {
                    @Override
                    public void onSuccess(LocationSettingsResponse locationSettingsResponse) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) { 
                            locationManager.addNmeaListener(mMessageListener);
                        }
                        mFusedLocationClient.requestLocationUpdates(mLocationRequest, mLocationCallback, Looper.myLooper());
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
    public void onListen(Object arguments, final EventSink eventsSink) {
        events = eventsSink;
        if (!checkPermissions()) {
            requestPermissions();
            if (this.locationPermissionState == PackageManager.PERMISSION_DENIED) {
                result.error("PERMISSION_DENIED",
                        "The user explicitly denied the use of location services for this app or location services are currently disabled in Settings.",
                        null);
            }
        }     
        startRequestingLocation();   
    }

    @Override
    public void onCancel(Object arguments) {
        mFusedLocationClient.removeLocationUpdates(mLocationCallback);
        events = null;
    }
}
