package com.lyokone.location;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.location.Location;
import android.support.annotation.MainThread;

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
    private BroadcastReceiver chargingStateChangeReceiver;
    private final Activity activity;

    LocationPlugin(Activity activity) {
        this.activity = activity;
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final LocationPlugin instance = new LocationPlugin(registrar.activity());

        final MethodChannel channel = new MethodChannel(registrar.messenger(), "lyokone/location");
        channel.setMethodCallHandler(instance);

        final EventChannel eventChannel =
                new EventChannel(registrar.messenger(), "lyokone/locationstream");
        eventChannel.setStreamHandler(instance);
    }

    @Override
    public void onMethodCall(MethodCall call,final Result result) {
        if (call.method.equals("getLocation")) {
            mFusedLocationClient = LocationServices.getFusedLocationProviderClient(this.activity);
            mFusedLocationClient.getLastLocation()
                    .addOnSuccessListener(this.activity, new OnSuccessListener<Location>() {
                        @Override
                        public void onSuccess(Location location) {
                            // Got last known location. In some rare situations this can be null.
                            if (location != null) {
                                HashMap loc = new HashMap();
                                loc.put("latitude", location.getLatitude());
                                loc.put("longitude", location.getLongitude());
                                result.success(loc);
                            }
                        }
                    });

        } else {
            result.notImplemented();
        }
    }



    @Override
    public void onListen(Object arguments, final EventSink events) {
        LocationRequest mLocationRequest = new LocationRequest();
        mLocationRequest.setInterval(10000);
        mLocationRequest.setFastestInterval(5000);
        mLocationRequest.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);

        LocationCallback mLocationCallback = new LocationCallback() {
            @Override
            public void onLocationResult(LocationResult locationResult) {
                for (Location location : locationResult.getLocations()) {
                    HashMap loc = new HashMap();
                    loc.put("latitude", location.getLatitude());
                    loc.put("longitude", location.getLongitude());

                    events.success(loc);
                }
            };
        };

        mFusedLocationClient.requestLocationUpdates(mLocationRequest,
                mLocationCallback,
                null /* Looper */);
    }

    @Override
    public void onCancel(Object arguments) {
        activity.unregisterReceiver(chargingStateChangeReceiver);
        chargingStateChangeReceiver = null;
    }

}
