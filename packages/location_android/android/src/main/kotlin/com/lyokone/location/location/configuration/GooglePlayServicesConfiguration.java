package com.lyokone.location.location.configuration;

import androidx.annotation.NonNull;

import com.google.android.gms.location.LocationRequest;
import com.lyokone.location.location.configuration.Defaults;
import com.lyokone.location.location.providers.locationprovider.DefaultLocationProvider;
import com.lyokone.location.location.providers.locationprovider.GooglePlayServicesLocationProvider;

public class GooglePlayServicesConfiguration {

    private final LocationRequest locationRequest;
    private final boolean fallbackToDefault;
    private final boolean askForGooglePlayServices;
    private final boolean askForSettingsApi;
    private final boolean failOnSettingsApiSuspended;
    private final boolean ignoreLastKnowLocation;
    private final long googlePlayServicesWaitPeriod;

    private GooglePlayServicesConfiguration(Builder builder) {
        this.locationRequest = builder.locationRequest;
        this.fallbackToDefault = builder.fallbackToDefault;
        this.askForGooglePlayServices = builder.askForGooglePlayServices;
        this.askForSettingsApi = builder.askForSettingsApi;
        this.failOnSettingsApiSuspended = builder.failOnSettingsApiSuspended;
        this.ignoreLastKnowLocation = builder.ignoreLastKnowLocation;
        this.googlePlayServicesWaitPeriod = builder.googlePlayServicesWaitPeriod;
    }

    public Builder newBuilder() {
        return new Builder()
              .locationRequest(locationRequest)
              .fallbackToDefault(fallbackToDefault)
              .askForGooglePlayServices(askForGooglePlayServices)
              .askForSettingsApi(askForSettingsApi)
              .failOnSettingsApiSuspended(failOnSettingsApiSuspended)
              .ignoreLastKnowLocation(ignoreLastKnowLocation)
              .setWaitPeriod(googlePlayServicesWaitPeriod);
    }

    // region Getters
    public LocationRequest locationRequest() {
        return locationRequest;
    }

    public boolean fallbackToDefault() {
        return fallbackToDefault;
    }

    public boolean askForGooglePlayServices() {
        return askForGooglePlayServices;
    }

    public boolean askForSettingsApi() {
        return askForSettingsApi;
    }

    public boolean failOnSettingsApiSuspended() {
        return failOnSettingsApiSuspended;
    }

    public boolean ignoreLastKnowLocation() {
        return ignoreLastKnowLocation;
    }

    public long googlePlayServicesWaitPeriod() {
        return googlePlayServicesWaitPeriod;
    }

    // endregion

    public static class Builder {

        private LocationRequest locationRequest = com.lyokone.location.location.configuration.Defaults.createDefaultLocationRequest();
        private boolean fallbackToDefault = com.lyokone.location.location.configuration.Defaults.FALLBACK_TO_DEFAULT;
        private boolean askForGooglePlayServices = com.lyokone.location.location.configuration.Defaults.ASK_FOR_GP_SERVICES;
        private boolean askForSettingsApi = com.lyokone.location.location.configuration.Defaults.ASK_FOR_SETTINGS_API;
        private boolean failOnSettingsApiSuspended = com.lyokone.location.location.configuration.Defaults.FAIL_ON_SETTINGS_API_SUSPENDED;
        private boolean ignoreLastKnowLocation = com.lyokone.location.location.configuration.Defaults.IGNORE_LAST_KNOW_LOCATION;
        private long googlePlayServicesWaitPeriod = com.lyokone.location.location.configuration.Defaults.WAIT_PERIOD;

        /**
         * LocationRequest object that you specified to use while getting location from Google Play Services
         * Default is {@linkplain com.lyokone.location.location.configuration.Defaults#createDefaultLocationRequest()}
         */
        public Builder locationRequest(@NonNull LocationRequest locationRequest) {
            this.locationRequest = locationRequest;
            return this;
        }

        /**
         * In case of getting location from {@linkplain GooglePlayServicesLocationProvider} fails,
         * library will fallback to {@linkplain DefaultLocationProvider} as a default behaviour.
         * If you set this to false, then library will notify fail as soon as GooglePlayServicesLocationProvider fails.
         */
        public Builder fallbackToDefault(boolean fallbackToDefault) {
            this.fallbackToDefault = fallbackToDefault;
            return this;
        }

        /**
         * Set true to ask user handle when there is some resolvable error
         * on connection GooglePlayServices, if you don't want to bother user
         * to configure Google Play Services to receive location then set this as false.
         *
         * Default is False.
         */
        public Builder askForGooglePlayServices(boolean askForGooglePlayServices) {
            this.askForGooglePlayServices = askForGooglePlayServices;
            return this;
        }

        /**
         * While trying to get location via GooglePlayServices LocationApi,
         * manager will check whether GPS, Wifi and Cell networks are available or not.
         * Then if this flag is on it will ask user to turn them on, again, via GooglePlayServices
         * by displaying a system dialog if not it will directly try to receive location
         * -which probably not going to return any values.
         *
         * Default is True.
         */
        public Builder askForSettingsApi(boolean askForSettingsApi) {
            this.askForSettingsApi = askForSettingsApi;
            return this;
        }

        /**
         * This flag will be checked when it is not possible to display user a settingsApi dialog
         * to switch necessary providers on, or when there is an error displaying the dialog.
         * If the flag is on, then manager will setDialogListener listener as location failed,
         * otherwise it will try to get location anyway -which probably not gonna happen.
         *
         * Default is False. -Because after GooglePlayServices Provider it might switch
         * to default providers, if we fail here then those provider will never trigger.
         */
        public Builder failOnSettingsApiSuspended(boolean failOnSettingsApiSuspended) {
            this.failOnSettingsApiSuspended = failOnSettingsApiSuspended;
            return this;
        }

        /**
         * GooglePlayServices Api returns the best most recent location currently available. It is highly recommended to
         * use this functionality unless your requirements are really specific and precise.
         *
         * Default is False. So GooglePlayServices Api will return immediately if there is location already.
         *
         * https://developers.google.com/android/reference/com/google/android/gms/location/FusedLocationProviderApi.html
         * #getLastLocation(com.google.android.gms.common.api.GoogleApiClient)
         */
        public Builder ignoreLastKnowLocation(boolean ignore) {
            this.ignoreLastKnowLocation = ignore;
            return this;
        }

        /**
         * Indicates waiting time period for GooglePlayServices before switching to next possible provider.
         *
         * Default values are {@linkplain Defaults#WAIT_PERIOD}
         */
        public Builder setWaitPeriod(long milliseconds) {
            if (milliseconds < 0) {
                throw new IllegalArgumentException("waitPeriod cannot be set to negative value.");
            }

            this.googlePlayServicesWaitPeriod = milliseconds;
            return this;
        }

        public GooglePlayServicesConfiguration build() {
            return new GooglePlayServicesConfiguration(this);
        }
    }
}
