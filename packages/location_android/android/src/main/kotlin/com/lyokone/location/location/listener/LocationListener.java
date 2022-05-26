package com.lyokone.location.location.listener;

import android.location.Location;
import android.os.Bundle;

import com.lyokone.location.location.constants.FailType;
import com.lyokone.location.location.constants.ProcessType;

public interface LocationListener {

    /**
     * This method will be called whenever the process is changed.
     *
     * @param processType new on going process
     */
    void onProcessTypeChanged(@ProcessType int processType);

    /**
     * This method will be invoked whenever new location update received
     */
    void onLocationChanged(Location location);

    /**
     * When it is not possible to receive location, such as no active provider or no permission etc.
     * It will pass an integer value from {@linkplain FailType}
     * which will help you to determine how did it fail to receive location
     */
    void onLocationFailed(@FailType int type);

    /**
     * This method will be invoked when user grants for location permissions,
     * or when you ask for it but the application already had that granted.
     * You can determine if permission is just granted or
     * did the application already have it by checking boolean input of this method.
     */
    void onPermissionGranted(boolean alreadyHadPermission);

    /**
     * This method will be invoked if only you use android.location.LocationManager
     * with GPS or Network Providers to receive location
     */
    void onStatusChanged(String provider, int status, Bundle extras);

    /**
     * This method will be invoked if only you use android.location.LocationManager
     * with GPS or Network Providers to receive location
     */
    void onProviderEnabled(String provider);

    /**
     * This method will be invoked if only you use android.location.LocationManager
     * with GPS or Network Providers to receive location
     */
    void onProviderDisabled(String provider);

}