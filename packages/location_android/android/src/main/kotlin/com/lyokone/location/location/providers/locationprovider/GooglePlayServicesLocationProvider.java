package com.lyokone.location.location.providers.locationprovider;

import android.app.Activity;
import android.content.Intent;
import android.content.IntentSender;
import android.location.Location;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.CommonStatusCodes;
import com.google.android.gms.common.api.ResolvableApiException;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationSettingsResponse;
import com.google.android.gms.location.LocationSettingsStatusCodes;
import com.google.android.gms.tasks.Task;
import com.lyokone.location.location.constants.FailType;
import com.lyokone.location.location.constants.ProcessType;
import com.lyokone.location.location.constants.RequestCode;
import com.lyokone.location.location.helper.LogUtils;
import com.lyokone.location.location.listener.FallbackListener;
import com.lyokone.location.location.providers.locationprovider.GooglePlayServicesLocationSource;
import com.lyokone.location.location.providers.locationprovider.GooglePlayServicesLocationSource.SourceListener;
import com.lyokone.location.location.providers.locationprovider.LocationProvider;

import java.lang.ref.WeakReference;

public class GooglePlayServicesLocationProvider extends LocationProvider implements SourceListener {

    private final WeakReference<FallbackListener> fallbackListener;

    private boolean settingsDialogIsOn = false;

    private com.lyokone.location.location.providers.locationprovider.GooglePlayServicesLocationSource googlePlayServicesLocationSource;

    GooglePlayServicesLocationProvider(FallbackListener fallbackListener) {
        this.fallbackListener = new WeakReference<>(fallbackListener);
    }

    @Override
    public void onResume() {
        if (!settingsDialogIsOn && (isWaiting() || getConfiguration().keepTracking())) {
            requestLocationUpdate();
        }
    }

    @Override
    public void onPause() {
        // not getSourceProvider, because we don't want to create if it doesn't already exist
        if (!settingsDialogIsOn && googlePlayServicesLocationSource != null) {
            removeLocationUpdates();
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();

        // not getSourceProvider, because we don't want to create if it doesn't already exist
        if (googlePlayServicesLocationSource != null) removeLocationUpdates();
    }

    @Override
    public boolean isDialogShowing() {
        return settingsDialogIsOn;
    }

    @Override
    public void get() {
        setWaiting(true);

        if (getContext() != null) {
            LogUtils.logI("Start request location updates.");

            if (getConfiguration().googlePlayServicesConfiguration().ignoreLastKnowLocation()) {
                LogUtils.logI("Configuration requires to ignore last know location from GooglePlayServices Api.");

                // Request fresh location
                locationRequired();
            } else {
                // Try to get last location, if failed then request fresh location
                getSourceProvider().requestLastLocation();
            }
        } else {
            failed(FailType.VIEW_DETACHED);
        }
    }

    @Override
    public void cancel() {
        LogUtils.logI("Canceling GooglePlayServiceLocationProvider...");
        // not getSourceProvider, because we don't want to create if it doesn't already exist
        if (googlePlayServicesLocationSource != null) {
            removeLocationUpdates();
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == RequestCode.SETTINGS_API) {
            settingsDialogIsOn = false;

            if (resultCode == Activity.RESULT_OK) {
                LogUtils.logI("We got settings changed, requesting location update...");
                requestLocationUpdate();
            } else {
                LogUtils.logI("User denied settingsApi dialog, GooglePlayServices SettingsApi failing...");
                settingsApiFail(FailType.GOOGLE_PLAY_SERVICES_SETTINGS_DENIED);
            }
        }

    }

    public void onLocationChanged(@NonNull Location location) {
        if (getListener() != null) {
            getListener().onLocationChanged(location);
        }

        // Set waiting as false because we got at least one, even though we keep tracking user's location
        setWaiting(false);

        if (!getConfiguration().keepTracking()) {
            // If need to update location once, clear the listener to prevent multiple call
            LogUtils.logI("We got location and no need to keep tracking, so location update is removed.");

            removeLocationUpdates();
        }
    }

    @Override
    public void onLocationResult(@Nullable LocationResult locationResult) {
        if (locationResult == null) {
            // Do nothing, wait for other result
            return;
        }

        for (Location location : locationResult.getLocations()) {
            onLocationChanged(location);
        }
    }

    @Override
    public void onSuccess(LocationSettingsResponse locationSettingsResponse) {
        // All location settings are satisfied. The client can initialize location
        // requests here.
        LogUtils.logI("We got GPS, Wifi and/or Cell network providers enabled enough "
                + "to receive location as we needed. Requesting location update...");
        requestLocationUpdate();
    }

    @Override
    public void onFailure(@NonNull Exception exception) {
        int statusCode = ((ApiException) exception).getStatusCode();

        switch (statusCode) {
            case LocationSettingsStatusCodes.SETTINGS_CHANGE_UNAVAILABLE:
                // Location settings are not satisfied.
                // However, we have no way to fix the settings so we won't show the dialog.
                LogUtils.logE("Settings change is not available, SettingsApi failing...");
                settingsApiFail(FailType.GOOGLE_PLAY_SERVICES_SETTINGS_DIALOG);

                break;
            case LocationSettingsStatusCodes.RESOLUTION_REQUIRED:
                // Location settings are not satisfied. But could be fixed by showing the user
                // a dialog.
                // Cast to a resolvable exception.
                resolveSettingsApi((ResolvableApiException) exception);

                break;
            default:
                // for other CommonStatusCodes values
                LogUtils.logE("LocationSettings failing, status: " + CommonStatusCodes.getStatusCodeString(statusCode));
                settingsApiFail(FailType.GOOGLE_PLAY_SERVICES_SETTINGS_DENIED);

                break;
        }
    }

    void resolveSettingsApi(@NonNull ResolvableApiException resolvable) {
        try {
            // Show the dialog by calling startResolutionForResult(),
            // and check the result in onActivityResult().
            LogUtils.logI("We need settingsApi dialog to switch required settings on.");
            if (getActivity() != null) {
                LogUtils.logI("Displaying the dialog...");
                getSourceProvider().startSettingsApiResolutionForResult(resolvable, getActivity());
                settingsDialogIsOn = true;
            } else {
                LogUtils.logI("Settings Api cannot show dialog if LocationManager is not running on an activity!");
                settingsApiFail(FailType.VIEW_NOT_REQUIRED_TYPE);
            }
        } catch (IntentSender.SendIntentException e) {
            LogUtils.logE("Error on displaying SettingsApi dialog, SettingsApi failing...");
            settingsApiFail(FailType.GOOGLE_PLAY_SERVICES_SETTINGS_DIALOG);
        }
    }

    /**
     * Task result can be null in certain conditions
     * See: https://developers.google.com/android/reference/com/google/android/gms/location/FusedLocationProviderClient#getLastLocation()
     */
    @Override
    public void onLastKnowLocationTaskReceived(@NonNull Task<Location> task) {
        if (task.isSuccessful() && task.getResult() != null) {
            Location lastKnownLocation = task.getResult();

            LogUtils.logI("LastKnowLocation is available.");
            onLocationChanged(lastKnownLocation);

            if (getConfiguration().keepTracking()) {
                LogUtils.logI("Configuration requires keepTracking.");
                locationRequired();
            }
        } else {
            LogUtils.logI("LastKnowLocation is not available.");
            locationRequired();
        }
    }

    void locationRequired() {
        LogUtils.logI("Ask for location update...");
        if (getConfiguration().googlePlayServicesConfiguration().askForSettingsApi()) {
            LogUtils.logI("Asking for SettingsApi...");
            getSourceProvider().checkLocationSettings();
        } else {
            LogUtils.logI("SettingsApi is not enabled, requesting for location update...");
            requestLocationUpdate();
        }
    }

    void requestLocationUpdate() {
        if (getListener() != null) {
            getListener().onProcessTypeChanged(ProcessType.GETTING_LOCATION_FROM_GOOGLE_PLAY_SERVICES);
        }

        LogUtils.logI("Requesting location update...");
        getSourceProvider().requestLocationUpdate();
    }

    void settingsApiFail(@FailType int failType) {
        if (getConfiguration().googlePlayServicesConfiguration().failOnSettingsApiSuspended()) {
            failed(failType);
        } else {
            LogUtils.logE("Even though settingsApi failed, configuration requires moving on. "
                  + "So requesting location update...");

            requestLocationUpdate();
        }
    }

    void failed(@FailType int type) {
        if (getConfiguration().googlePlayServicesConfiguration().fallbackToDefault() && fallbackListener.get() != null) {
            fallbackListener.get().onFallback();
        } else {
            if (getListener() != null) {
                getListener().onLocationFailed(type);
            }
        }
        setWaiting(false);
    }

    // For test purposes
    void setDispatcherLocationSource(com.lyokone.location.location.providers.locationprovider.GooglePlayServicesLocationSource googlePlayServicesLocationSource) {
        this.googlePlayServicesLocationSource = googlePlayServicesLocationSource;
    }

    private com.lyokone.location.location.providers.locationprovider.GooglePlayServicesLocationSource getSourceProvider() {
        if (googlePlayServicesLocationSource == null) {
            googlePlayServicesLocationSource = new com.lyokone.location.location.providers.locationprovider.GooglePlayServicesLocationSource(getContext(),
                  getConfiguration().googlePlayServicesConfiguration().locationRequest(), this);
        }
        return googlePlayServicesLocationSource;
    }

    private void removeLocationUpdates() {
        LogUtils.logI("Stop location updates...");

        // not getSourceProvider, because we don't want to create if it doesn't already exist
        if (googlePlayServicesLocationSource != null) {
            setWaiting(false);
            googlePlayServicesLocationSource.removeLocationUpdates();
        }
    }

}