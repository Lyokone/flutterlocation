package com.lyokone.location;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.location.Location;
import android.support.annotation.MainThread;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.location.Location;
import android.os.Build;
import android.os.Bundle;
import android.os.Looper;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;

import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.tasks.OnSuccessListener;

import java.util.HashMap;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * LocationPlugin
 */
public class LocationPlugin implements MethodCallHandler, StreamHandler {

    private FusedLocationProviderClient mFusedLocationClient;
    private EventSink events;
    private BroadcastReceiver chargingStateChangeReceiver;
    private final Activity activity;
    private boolean hasPermission = false;
    private static final int MY_PERMISSIONS_REQUEST_LOCATION = 895;

    LocationPlugin(Activity activity) {
        this.activity = activity;
    }

    private void getGPSPermission() {
        String requestedPermission = "";
        PackageManager pm = activity.getPackageManager();

        try {
            PackageInfo packageInfo = pm.getPackageInfo(activity.getPackageName(), PackageManager.GET_PERMISSIONS);
            if (packageInfo != null) {
                for (String permission : packageInfo.requestedPermissions) {
                    if (permission.equals(Manifest.permission.ACCESS_COARSE_LOCATION)) {
                        requestedPermission = Manifest.permission.ACCESS_COARSE_LOCATION;
                        break;
                    } else if (permission.equals(Manifest.permission.ACCESS_FINE_LOCATION)) {
                        requestedPermission = Manifest.permission.ACCESS_FINE_LOCATION;
                        break;
                    }
                }
            }

            if (!requestedPermission.isEmpty()) {
                int permissionCheck = ContextCompat.checkSelfPermission(activity, requestedPermission);

                if (permissionCheck != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(activity, new String[] { requestedPermission },
                            MY_PERMISSIONS_REQUEST_LOCATION);
                } else {
                    hasPermission = true;
                }
            }
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
    }

    private void checkPermission() {

    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {

        final LocationPlugin instance = new LocationPlugin(registrar.activity());

        final MethodChannel channel = new MethodChannel(registrar.messenger(), "lyokone/location");
        channel.setMethodCallHandler(instance);

        final EventChannel eventChannel = new EventChannel(registrar.messenger(), "lyokone/locationstream");
        eventChannel.setStreamHandler(instance);
    }

    @Override
    public void onMethodCall(MethodCall call, final Result result) {
        if (call.method.equals("getLocation")) {

            int targetSdkVersion = activity.getApplicationInfo().targetSdkVersion;
            if (targetSdkVersion >= Build.VERSION_CODES.M) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    getGPSPermission();
                } else {
                    hasPermission = true;
                }
            } else {
                hasPermission = true;
            }

            if (hasPermission) {
                if (mFusedLocationClient == null) {
                    mFusedLocationClient = LocationServices.getFusedLocationProviderClient(this.activity);
                }
                mFusedLocationClient.getLastLocation().addOnSuccessListener(this.activity,
                        new OnSuccessListener<Location>() {
                            @Override
                            public void onSuccess(Location location) {
                                // Got last known location. In some rare situations this can be null.
                                if (location != null) {
                                    HashMap loc = new HashMap();
                                    loc.put("latitude", location.getLatitude());
                                    loc.put("longitude", location.getLongitude());
                                    loc.put("accuracy", location.getAccuracy());
                                    loc.put("altitude", location.getAltitude());
                                    result.success(loc);
                                }
                            }
                        });
            }

        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onListen(Object arguments, final EventSink eventsSink) {
        events = eventsSink;
        int targetSdkVersion = activity.getApplicationInfo().targetSdkVersion;

        if (targetSdkVersion >= Build.VERSION_CODES.M) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                getGPSPermission();
            } else {
                hasPermission = true;
            }
        } else {
            hasPermission = true;
        }

        if (hasPermission) {
            LocationRequest mLocationRequest = new LocationRequest();
            mLocationRequest.setInterval(10000);
            mLocationRequest.setFastestInterval(5000);
            mLocationRequest.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);
            if (mFusedLocationClient == null) {
                mFusedLocationClient = LocationServices.getFusedLocationProviderClient(this.activity);
            }
            mFusedLocationClient.requestLocationUpdates(mLocationRequest, mLocationCallback, Looper.myLooper());
        }
    }

    private LocationCallback mLocationCallback = new LocationCallback() {
        @Override
        public void onLocationResult(LocationResult locationResult) {
            for (Location location : locationResult.getLocations()) {
                HashMap loc = new HashMap();
                loc.put("latitude", location.getLatitude());
                loc.put("longitude", location.getLongitude());
                loc.put("accuracy", location.getAccuracy());
                loc.put("altitude", location.getAltitude());
                events.success(loc);
            }
        };
    };

    @Override
    public void onCancel(Object arguments) {
        mFusedLocationClient.removeLocationUpdates(mLocationCallback);
        activity.unregisterReceiver(chargingStateChangeReceiver);
        chargingStateChangeReceiver = null;
    }
}
