package com.lyokone.location.location.base;

import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.CallSuper;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import com.lyokone.location.location.LocationManager;
import com.lyokone.location.location.configuration.LocationConfiguration;
import com.lyokone.location.location.constants.ProcessType;
import com.lyokone.location.location.listener.LocationListener;

public abstract class LocationBaseActivity extends AppCompatActivity implements LocationListener {

    private LocationManager locationManager;

    public abstract LocationConfiguration getLocationConfiguration();

    protected LocationManager getLocationManager() {
        return locationManager;
    }

    protected void getLocation() {
        if (locationManager != null) {
            locationManager.get();
        } else {
            throw new IllegalStateException("locationManager is null. "
                  + "Make sure you call super.initialize before attempting to getLocation");
        }
    }

    @CallSuper
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        locationManager = new LocationManager.Builder(getApplicationContext())
              .configuration(getLocationConfiguration())
              .activity(this)
              .notify(this)
              .build();
    }

    @CallSuper
    @Override
    protected void onDestroy() {
        locationManager.onDestroy();
        super.onDestroy();
    }

    @CallSuper
    @Override
    protected void onPause() {
        locationManager.onPause();
        super.onPause();
    }

    @CallSuper
    @Override
    protected void onResume() {
        super.onResume();
        locationManager.onResume();
    }

    @CallSuper
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        locationManager.onActivityResult(requestCode, resultCode, data);
    }

    @CallSuper
    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        locationManager.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }

    @Override
    public void onProcessTypeChanged(@ProcessType int processType) {
        // override if needed
    }

    @Override
    public void onPermissionGranted(boolean alreadyHadPermission) {
        // override if needed
    }

    @Override
    public void onStatusChanged(String provider, int status, Bundle extras) {
        // override if needed
    }

    @Override
    public void onProviderEnabled(String provider) {
        // override if needed
    }

    @Override
    public void onProviderDisabled(String provider) {
        // override if needed
    }
}
