package com.lyokone.location.location.base;

import android.location.Location;
import android.os.Bundle;

import com.lyokone.location.location.constants.ProcessType;
import com.lyokone.location.location.listener.LocationListener;

/**
 * Empty Location Listener in case you need only some of the methods from {@linkplain LocationListener}
 * Only {@linkplain LocationListener#onLocationChanged(Location)} and {@linkplain LocationListener#onLocationFailed(int)}
 * need to be overridden.
 */
public abstract class SimpleLocationListener implements LocationListener {

    @Override
    public void onProcessTypeChanged(@ProcessType int processType) {

    }

    @Override
    public void onPermissionGranted(boolean alreadyHadPermission, boolean limitedPermission) {

    }

    @Override
    public void onStatusChanged(String provider, int status, Bundle extras) {

    }

    @Override
    public void onProviderEnabled(String provider) {

    }

    @Override
    public void onProviderDisabled(String provider) {

    }

}
