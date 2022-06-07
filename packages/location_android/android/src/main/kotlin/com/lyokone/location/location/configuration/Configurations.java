package com.lyokone.location.location.configuration;

import androidx.annotation.NonNull;

import com.lyokone.location.location.listener.LocationListener;

public final class Configurations {

    /**
     * Pre-Defined Configurations
     */
    private Configurations() {
        // No instance
    }

    /**
     * Returns a LocationConfiguration that keeps tracking,
     * see also {@linkplain Configurations#silentConfiguration(boolean)}
     */
    public static LocationConfiguration silentConfiguration() {
        return silentConfiguration(true);
    }

    /**
     * Returns a LocationConfiguration that will never ask user anything and will try to use whatever possible options
     * that application has to obtain location. If there is no sufficient permission, provider, etc... then
     * LocationManager will call {@linkplain LocationListener#onLocationFailed(int)} silently
     * <p>
     * # Best use case of this configuration is within Service implementations
     */
    public static LocationConfiguration silentConfiguration(boolean keepTracking) {
        return new LocationConfiguration.Builder()
                .keepTracking(keepTracking)
                .useGooglePlayServices(new GooglePlayServicesConfiguration.Builder().askForSettingsApi(false).build())
                .useDefaultProviders(new DefaultProviderConfiguration.Builder().build())
                .build();
    }

    /**
     * Returns a LocationConfiguration which tights to default definitions with given messages. Since this method is
     * basically created in order to be used in Activities, User needs to be asked for permission and enabling gps.
     *
     * @return
     */
    public static LocationConfiguration.Builder defaultConfiguration(@NonNull String rationalMessage, @NonNull String gpsMessage) {
        return new LocationConfiguration.Builder()
                .askForPermission(new PermissionConfiguration.Builder().rationaleMessage(rationalMessage).build())
                .useDefaultProviders(new DefaultProviderConfiguration.Builder().requiredTimeInterval(2 * 1000).gpsMessage(gpsMessage).build());
    }
}
