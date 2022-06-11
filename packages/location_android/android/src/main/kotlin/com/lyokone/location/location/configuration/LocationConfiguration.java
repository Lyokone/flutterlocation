package com.lyokone.location.location.configuration;

import androidx.annotation.Nullable;

import com.lyokone.location.location.configuration.DefaultProviderConfiguration;
import com.lyokone.location.location.configuration.Defaults;
import com.lyokone.location.location.configuration.GooglePlayServicesConfiguration;
import com.lyokone.location.location.configuration.PermissionConfiguration;
import com.lyokone.location.location.providers.permissionprovider.StubPermissionProvider;

public class LocationConfiguration {

    private final boolean keepTracking;
    private final PermissionConfiguration permissionConfiguration;
    private final GooglePlayServicesConfiguration googlePlayServicesConfiguration;
    private final DefaultProviderConfiguration defaultProviderConfiguration;

    private LocationConfiguration(Builder builder) {
        this.keepTracking = builder.keepTracking;
        this.permissionConfiguration = builder.permissionConfiguration;
        this.googlePlayServicesConfiguration = builder.googlePlayServicesConfiguration;
        this.defaultProviderConfiguration = builder.defaultProviderConfiguration;
    }

    public Builder newBuilder() {
        return new Builder()
              .keepTracking(keepTracking)
              .askForPermission(permissionConfiguration)
              .useGooglePlayServices(googlePlayServicesConfiguration)
              .useDefaultProviders(defaultProviderConfiguration);
    }

    // region Getters
    public boolean keepTracking() {
        return keepTracking;
    }

    public PermissionConfiguration permissionConfiguration() {
        return permissionConfiguration;
    }

    @Nullable
    public GooglePlayServicesConfiguration googlePlayServicesConfiguration() {
        return googlePlayServicesConfiguration;
    }

    @Nullable public DefaultProviderConfiguration defaultProviderConfiguration() {
        return defaultProviderConfiguration;
    }
    // endregion

    public static class Builder {

        private boolean keepTracking = com.lyokone.location.location.configuration.Defaults.KEEP_TRACKING;
        private PermissionConfiguration permissionConfiguration;
        private GooglePlayServicesConfiguration googlePlayServicesConfiguration;
        private DefaultProviderConfiguration defaultProviderConfiguration;

        /**
         * If you need to keep receiving location updates, then you need to set this as true.
         * Otherwise manager will be aborted after any location received.
         * Default is False.
         */
        public Builder keepTracking(boolean keepTracking) {
            this.keepTracking = keepTracking;
            return this;
        }

        /**
         * This configuration is required in order to configure Permission Request process.
         * If this is not set, then no permission will be requested from user and
         * if {@linkplain Defaults#LOCATION_PERMISSIONS} permissions are not granted already,
         * then getting location will fail silently.
         */
        public Builder askForPermission(PermissionConfiguration permissionConfiguration) {
            this.permissionConfiguration = permissionConfiguration;
            return this;
        }

        /**
         * This configuration is required in order to configure GooglePlayServices Api.
         * If this is not set, then GooglePlayServices will not be used.
         */
        public Builder useGooglePlayServices(GooglePlayServicesConfiguration googlePlayServicesConfiguration) {
            this.googlePlayServicesConfiguration = googlePlayServicesConfiguration;
            return this;
        }

        /**
         * This configuration is required in order to configure Default Location Providers.
         * If this is not set, then they will not be used.
         */
        public Builder useDefaultProviders(DefaultProviderConfiguration defaultProviderConfiguration) {
            this.defaultProviderConfiguration = defaultProviderConfiguration;
            return this;
        }

        public LocationConfiguration build() {
            if (googlePlayServicesConfiguration == null && defaultProviderConfiguration == null) {
                throw new IllegalStateException("You need to specify one of the provider configurations."
                      + " Please see GooglePlayServicesConfiguration and DefaultProviderConfiguration");
            }

            if (permissionConfiguration == null) {
                permissionConfiguration = new PermissionConfiguration.Builder()
                      .permissionProvider(new StubPermissionProvider())
                      .build();
            }

            return new LocationConfiguration(this);
        }

    }
}
