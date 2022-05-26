package com.lyokone.location.location.configuration;

import android.Manifest;

import com.google.android.gms.location.LocationRequest;

public final class Defaults {

    private static final int SECOND = 1000;
    private static final int MINUTE = 60 * SECOND;

    static final int WAIT_PERIOD = 20 * SECOND;
    static final int TIME_PERIOD = 5 * MINUTE;

    static final int LOCATION_DISTANCE_INTERVAL = 0;
    static final int LOCATION_INTERVAL = 5 * MINUTE;

    static final float MIN_ACCURACY = 5.0f;

    static final boolean KEEP_TRACKING = false;
    static final boolean FALLBACK_TO_DEFAULT = true;
    static final boolean ASK_FOR_GP_SERVICES = false;
    static final boolean ASK_FOR_SETTINGS_API = true;
    static final boolean FAIL_ON_SETTINGS_API_SUSPENDED = false;
    static final boolean IGNORE_LAST_KNOW_LOCATION = false;

    static final String EMPTY_STRING = "";
    public static final String[] LOCATION_PERMISSIONS = new String[] { Manifest.permission.ACCESS_COARSE_LOCATION,
          Manifest.permission.ACCESS_FINE_LOCATION };

    private static final int LOCATION_PRIORITY = LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY;
    private static final int LOCATION_FASTEST_INTERVAL = MINUTE;

    /**
     * https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest
     */
    public static LocationRequest createDefaultLocationRequest() {
        return LocationRequest.create()
              .setPriority(Defaults.LOCATION_PRIORITY)
              .setInterval(Defaults.LOCATION_INTERVAL)
              .setFastestInterval(Defaults.LOCATION_FASTEST_INTERVAL);
    }

    private Defaults() {
        // No instance
    }

}