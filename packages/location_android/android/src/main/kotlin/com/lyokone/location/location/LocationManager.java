package com.lyokone.location.location;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;

import com.lyokone.location.location.configuration.LocationConfiguration;
import com.lyokone.location.location.constants.FailType;
import com.lyokone.location.location.constants.ProcessType;
import com.lyokone.location.location.helper.LogUtils;
import com.lyokone.location.location.helper.logging.DefaultLogger;
import com.lyokone.location.location.helper.logging.Logger;
import com.lyokone.location.location.listener.LocationListener;
import com.lyokone.location.location.listener.PermissionListener;
import com.lyokone.location.location.providers.locationprovider.DispatcherLocationProvider;
import com.lyokone.location.location.providers.locationprovider.LocationProvider;
import com.lyokone.location.location.providers.permissionprovider.PermissionProvider;
import com.lyokone.location.location.view.ContextProcessor;

public class LocationManager implements PermissionListener {

    private final LocationListener listener;
    private final LocationConfiguration configuration;
    private final LocationProvider activeProvider;
    private final PermissionProvider permissionProvider;

    /**
     * Library tries to log as much as possible in order to make it transparent to see what is actually going on
     * under the hood. You can enable it for debug purposes, but do not forget to disable on production.
     *
     * Log is disabled as default.
     */
    public static void enableLog(boolean enable) {
        LogUtils.enable(enable);
    }

    /**
     * The Logger specifies how this Library is logging debug information. By default {@link DefaultLogger}
     * is used and it can be replaced by your own custom implementation of {@link Logger}.
     */
    public static void setLogger(@NonNull Logger logger) {
        LogUtils.setLogger(logger);
    }

    /**
     * To create an instance of this manager you MUST specify a LocationConfiguration
     */
    private LocationManager(Builder builder) {
        this.listener = builder.listener;
        this.configuration = builder.configuration;
        this.activeProvider = builder.activeProvider;

        this.permissionProvider = getConfiguration().permissionConfiguration().permissionProvider();
        this.permissionProvider.setContextProcessor(builder.contextProcessor);
        this.permissionProvider.setPermissionListener(this);
    }

    public static class Builder {

        private final ContextProcessor contextProcessor;
        private LocationListener listener;
        private LocationConfiguration configuration;
        private LocationProvider activeProvider;

        /**
         * Builder object to create LocationManager
         *
         * @param contextProcessor holds the address of the context,which this manager will run on
         */
        public Builder(@NonNull ContextProcessor contextProcessor) {
            this.contextProcessor = contextProcessor;
        }

        /**
         * Builder object to create LocationManager
         *
         * @param context MUST be an application context
         */
        public Builder(@NonNull Context context) {
            this.contextProcessor = new ContextProcessor(context);
        }

        /**
         * Activity is required in order to ask for permission, GPS enable dialog, Rationale dialog,
         * GoogleApiClient and SettingsApi.
         *
         * @param activity will be kept as weakReference
         */
        public Builder activity(Activity activity) {
            this.contextProcessor.setActivity(activity);
            return this;
        }

        /**
         * Fragment is required in order to ask for permission, GPS enable dialog, Rationale dialog,
         * GoogleApiClient and SettingsApi.
         *
         * @param fragment will be kept as weakReference
         */
        public Builder fragment(Fragment fragment) {
            this.contextProcessor.setFragment(fragment);
            return this;
        }

        /**
         * Configuration object in order to take decisions accordingly while trying to retrieve location
         */
        public Builder configuration(@NonNull LocationConfiguration locationConfiguration) {
            this.configuration = locationConfiguration;
            return this;
        }

        /**
         * Instead of using {@linkplain DispatcherLocationProvider} you can create your own,
         * and set it to manager so it will use given one.
         */
        public Builder locationProvider(@NonNull LocationProvider provider) {
            this.activeProvider = provider;
            return this;
        }

        /**
         * Specify a LocationListener to receive location when it is available,
         * or get knowledge of any other steps in process
         */
        public Builder notify(LocationListener listener) {
            this.listener = listener;
            return this;
        }

        public LocationManager build() {
            if (contextProcessor == null) {
                throw new IllegalStateException("You must set a context to LocationManager.");
            }

            if (configuration == null) {
                throw new IllegalStateException("You must set a configuration object.");
            }

            if (activeProvider == null) {
                locationProvider(new DispatcherLocationProvider());
            }

            this.activeProvider.configure(contextProcessor, configuration, listener);

            return new LocationManager(this);
        }
    }

    /**
     * Returns configuration object which is defined to this manager
     */
    public LocationConfiguration getConfiguration() {
        return configuration;
    }

    /**
     * Google suggests to stop location updates when the activity is no longer in focus
     * http://developer.android.com/training/location/receive-location-updates.html#stop-updates
     */
    public void onPause() {
        activeProvider.onPause();
    }

    /**
     * Restart location updates to keep continue getting locations when activity is back
     */
    public void onResume() {
        activeProvider.onResume();
    }

    /**
     * Release whatever you need to when onDestroy is called
     */
    public void onDestroy() {
        activeProvider.onDestroy();
    }

    /**
     * This is required to check when user handles with Google Play Services error, or enables GPS...
     */
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        activeProvider.onActivityResult(requestCode, resultCode, data);
    }

    /**
     * Provide requestPermissionResult to manager so the it can handle RuntimePermission
     */
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        permissionProvider.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }

    /**
     * To determine whether LocationManager is currently waiting for location or it did already receive one!
     */
    public boolean isWaitingForLocation() {
        return activeProvider.isWaiting();
    }

    /**
     * To determine whether the manager is currently displaying any dialog or not
     */
    public boolean isAnyDialogShowing() {
        return activeProvider.isDialogShowing();
    }

    /**
     * Abort the mission and cancel all location update requests
     */
    public void cancel() {
        activeProvider.cancel();
    }

    /**
     * The only method you need to call to trigger getting location process
     */
    public void get() {
        askForPermission();
    }

    /**
     * Only For Test Purposes
     */
    LocationProvider activeProvider() {
        return activeProvider;
    }

    void askForPermission() {
        if (permissionProvider.hasPermission()) {
            permissionGranted(true);
        } else {
            if (listener != null) {
                listener.onProcessTypeChanged(ProcessType.ASKING_PERMISSIONS);
            }

            if (permissionProvider.requestPermissions()) {
                LogUtils.logI("Waiting until we receive any callback from PermissionProvider...");
            } else {
                LogUtils.logI("Couldn't get permission, Abort!");
                failed(FailType.PERMISSION_DENIED);
            }
        }
    }

    private void permissionGranted(boolean alreadyHadPermission) {
        LogUtils.logI("We got permission!");

        if (listener != null) {
            listener.onPermissionGranted(alreadyHadPermission);
        }

        activeProvider.get();
    }

    private void failed(@FailType int type) {
        if (listener != null) {
            listener.onLocationFailed(type);
        }
    }

    @Override
    public void onPermissionsGranted() {
        permissionGranted(false);
    }

    @Override
    public void onPermissionsDenied() {
        failed(FailType.PERMISSION_DENIED);
    }
}