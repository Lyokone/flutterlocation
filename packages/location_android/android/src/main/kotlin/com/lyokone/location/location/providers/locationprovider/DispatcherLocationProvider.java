package com.lyokone.location.location.providers.locationprovider;

import android.app.Dialog;
import android.content.DialogInterface;
import android.content.Intent;

import androidx.annotation.NonNull;

import com.google.android.gms.common.ConnectionResult;
import com.lyokone.location.location.constants.FailType;
import com.lyokone.location.location.constants.RequestCode;
import com.lyokone.location.location.helper.LogUtils;
import com.lyokone.location.location.helper.continuoustask.ContinuousTask.ContinuousTaskRunner;
import com.lyokone.location.location.listener.FallbackListener;
import com.lyokone.location.location.providers.locationprovider.DispatcherLocationSource;
import com.lyokone.location.location.providers.locationprovider.GooglePlayServicesLocationProvider;
import com.lyokone.location.location.providers.locationprovider.LocationProvider;

public class DispatcherLocationProvider extends com.lyokone.location.location.providers.locationprovider.LocationProvider implements ContinuousTaskRunner, FallbackListener {

    private Dialog gpServicesDialog;
    private com.lyokone.location.location.providers.locationprovider.LocationProvider activeProvider;
    private com.lyokone.location.location.providers.locationprovider.DispatcherLocationSource dispatcherLocationSource;

    @Override
    public void onPause() {
        super.onPause();

        if (activeProvider != null) {
            activeProvider.onPause();
        }

        getSourceProvider().gpServicesSwitchTask().pause();
    }

    @Override
    public void onResume() {
        super.onResume();

        if (activeProvider != null) {
            activeProvider.onResume();
        }

        getSourceProvider().gpServicesSwitchTask().resume();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();

        if (activeProvider != null) {
            activeProvider.onDestroy();
        }

        getSourceProvider().gpServicesSwitchTask().stop();

        dispatcherLocationSource = null;
        gpServicesDialog = null;
    }

    @Override
    public void cancel() {
        if (activeProvider != null) {
            activeProvider.cancel();
        }

        getSourceProvider().gpServicesSwitchTask().stop();
    }

    @Override
    public boolean isWaiting() {
        return activeProvider != null && activeProvider.isWaiting();
    }

    @Override
    public boolean isDialogShowing() {
        boolean gpServicesDialogShown = gpServicesDialog != null && gpServicesDialog.isShowing();
        boolean anyProviderDialogShown = activeProvider != null && activeProvider.isDialogShowing();
        return gpServicesDialogShown || anyProviderDialogShown;
    }

    @Override
    public void runScheduledTask(@NonNull String taskId) {
        if (taskId.equals(com.lyokone.location.location.providers.locationprovider.DispatcherLocationSource.GOOGLE_PLAY_SERVICE_SWITCH_TASK)) {
            if (activeProvider instanceof GooglePlayServicesLocationProvider && activeProvider.isWaiting()) {
                LogUtils.logI("We couldn't receive location from GooglePlayServices, so switching default providers...");
                cancel();
                continueWithDefaultProviders();
            }
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == RequestCode.GOOGLE_PLAY_SERVICES) {
            // Check whether do we have gpServices now or still not!
            checkGooglePlayServicesAvailability(false);
        } else {
            if (activeProvider != null) {
                activeProvider.onActivityResult(requestCode, resultCode, data);
            }
        }
    }

    @Override
    public void get() {
        if (getConfiguration().googlePlayServicesConfiguration() != null) {
            checkGooglePlayServicesAvailability(true);
        } else {
            LogUtils.logI("Configuration requires not to use Google Play Services, "
                  + "so skipping that step to Default Location Providers");
            continueWithDefaultProviders();
        }
    }

    @Override
    public void onFallback() {
        // This is called from GooglePlayServicesLocationProvider when it fails to before its scheduled time
        cancel();
        continueWithDefaultProviders();
    }

    void checkGooglePlayServicesAvailability(boolean askForGooglePlayServices) {
        int gpServicesAvailability = getSourceProvider().isGoogleApiAvailable(getContext());

        if (gpServicesAvailability == ConnectionResult.SUCCESS) {
            LogUtils.logI("GooglePlayServices is available on device.");
            getLocationFromGooglePlayServices();
        } else {
            LogUtils.logI("GooglePlayServices is NOT available on device.");
            if (askForGooglePlayServices) {
                askForGooglePlayServices(gpServicesAvailability);
            } else {
                LogUtils.logI("GooglePlayServices is NOT available and even though we ask user to handle error, "
                      + "it is still NOT available.");

                // This means get method is called by onActivityResult
                // which we already ask user to handle with gpServices error
                continueWithDefaultProviders();
            }
        }
    }

    void askForGooglePlayServices(int gpServicesAvailability) {
        if (getConfiguration().googlePlayServicesConfiguration().askForGooglePlayServices() &&
              getSourceProvider().isGoogleApiErrorUserResolvable(gpServicesAvailability)) {

            resolveGooglePlayServices(gpServicesAvailability);
        } else {
            LogUtils.logI("Either GooglePlayServices error is not resolvable "
                  + "or the configuration doesn't wants us to bother user.");
            continueWithDefaultProviders();
        }
    }

    /**
     * Handle GooglePlayServices error. Try showing a dialog that maybe can fix the error by user action.
     * If error cannot be resolved or user cancelled dialog or dialog cannot be displayed, then {@link #continueWithDefaultProviders()} is called.
     * <p>
     * The {@link com.google.android.gms.common.GoogleApiAvailability#isGooglePlayServicesAvailable(android.content.Context)} returns one of following in {@link ConnectionResult}:
     * SUCCESS, SERVICE_MISSING, SERVICE_UPDATING, SERVICE_VERSION_UPDATE_REQUIRED, SERVICE_DISABLED, SERVICE_INVALID.
     * <p>
     * See https://developers.google.com/android/reference/com/google/android/gms/common/GoogleApiAvailability#public-int-isgoogleplayservicesavailable-context-context
     */
    void resolveGooglePlayServices(int gpServicesAvailability) {
        LogUtils.logI("Asking user to handle GooglePlayServices error...");
        gpServicesDialog = getSourceProvider().getGoogleApiErrorDialog(getActivity(), gpServicesAvailability,
              RequestCode.GOOGLE_PLAY_SERVICES, new DialogInterface.OnCancelListener() {
                  @Override
                  public void onCancel(DialogInterface dialog) {
                      LogUtils.logI("GooglePlayServices error could've been resolved, "
                            + "but user canceled it.");
                      continueWithDefaultProviders();
                  }
              });

        if (gpServicesDialog != null) {

            /*
            The SERVICE_INVALID, SERVICE_UPDATING errors cannot be resolved via user action.
            In these cases, when user closes dialog by clicking OK button, OnCancelListener is not called.
            So, to handle these errors, we attach a dismiss event listener that calls continueWithDefaultProviders(), when dialog is closed.
             */
            switch (gpServicesAvailability) {
                // The version of the Google Play services installed on this device is not authentic.
                case ConnectionResult.SERVICE_INVALID:
                // Google Play service is currently being updated on this device.
                case ConnectionResult.SERVICE_UPDATING:
                    gpServicesDialog.setOnDismissListener(new DialogInterface.OnDismissListener() {
                        @Override
                        public void onDismiss(DialogInterface dialog) {
                            LogUtils.logI("GooglePlayServices error could not have been resolved");
                            continueWithDefaultProviders();
                        }
                    });

                    break;
            }

            gpServicesDialog.show();
        } else {
            LogUtils.logI("GooglePlayServices error could've been resolved, but since LocationManager "
                  + "is not running on an Activity, dialog cannot be displayed.");
            continueWithDefaultProviders();
        }
    }

    void getLocationFromGooglePlayServices() {
        LogUtils.logI("Attempting to get location from Google Play Services providers...");
        setLocationProvider(getSourceProvider().createGooglePlayServicesLocationProvider(this));
        getSourceProvider().gpServicesSwitchTask().delayed(getConfiguration()
              .googlePlayServicesConfiguration().googlePlayServicesWaitPeriod());
        activeProvider.get();
    }

    /**
     * Called in case of Google Play Services failed to retrieve location,
     * or GooglePlayServicesConfiguration doesn't provided by developer
     */
    void continueWithDefaultProviders() {
        if (getConfiguration().defaultProviderConfiguration() == null) {
            LogUtils.logI("Configuration requires not to use default providers, abort!");
            if (getListener() != null) {
                getListener().onLocationFailed(FailType.GOOGLE_PLAY_SERVICES_NOT_AVAILABLE);
            }
        } else {
            LogUtils.logI("Attempting to get location from default providers...");
            setLocationProvider(getSourceProvider().createDefaultLocationProvider());
            activeProvider.get();
        }
    }

    void setLocationProvider(LocationProvider provider) {
        this.activeProvider = provider;
        activeProvider.configure(this);
    }

    // For test purposes
    void setDispatcherLocationSource(com.lyokone.location.location.providers.locationprovider.DispatcherLocationSource dispatcherLocationSource) {
        this.dispatcherLocationSource = dispatcherLocationSource;
    }

    private com.lyokone.location.location.providers.locationprovider.DispatcherLocationSource getSourceProvider() {
        if (dispatcherLocationSource == null) {
            dispatcherLocationSource = new com.lyokone.location.location.providers.locationprovider.DispatcherLocationSource(this);
        }
        return dispatcherLocationSource;
    }
}
