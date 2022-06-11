package com.lyokone.location.location.helper;

import android.location.LocationListener;
import android.location.LocationManager;

import com.lyokone.location.location.helper.StringUtils;

public class UpdateRequest {

    private final LocationManager locationManager;
    private final LocationListener locationListener;

    private String provider;
    private long minTime;
    private float minDistance;

    public UpdateRequest(LocationManager locationManager, LocationListener locationListener) {
        this.locationManager = locationManager;
        this.locationListener = locationListener;
    }

    public void run(String provider, long minTime, float minDistance) {
        this.provider = provider;
        this.minTime = minTime;
        this.minDistance = minDistance;
        run();
    }

    @SuppressWarnings("ResourceType")
    public void run() {
        if(StringUtils.isNotEmpty(provider)) {
            locationManager.requestLocationUpdates(provider, minTime, minDistance, locationListener);
        }
    }

    @SuppressWarnings("ResourceType")
    public void release() {
        if (locationManager != null) locationManager.removeUpdates(locationListener);
    }

}
