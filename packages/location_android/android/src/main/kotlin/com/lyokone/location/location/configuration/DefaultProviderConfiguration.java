package com.lyokone.location.location.configuration;

import androidx.annotation.Nullable;

import com.lyokone.location.location.configuration.Defaults;
import com.lyokone.location.location.configuration.LocationConfiguration;
import com.lyokone.location.location.constants.ProviderType;
import com.lyokone.location.location.helper.StringUtils;
import com.lyokone.location.location.providers.dialogprovider.DialogProvider;
import com.lyokone.location.location.providers.dialogprovider.SimpleMessageDialogProvider;

public class DefaultProviderConfiguration {

    private final long requiredTimeInterval;
    private final long requiredDistanceInterval;
    private final float acceptableAccuracy;
    private final long acceptableTimePeriod;
    private final long gpsWaitPeriod;
    private final long networkWaitPeriod;
    private final DialogProvider gpsDialogProvider;

    private DefaultProviderConfiguration(Builder builder) {
        this.requiredTimeInterval = builder.requiredTimeInterval;
        this.requiredDistanceInterval = builder.requiredDistanceInterval;
        this.acceptableAccuracy = builder.acceptableAccuracy;
        this.acceptableTimePeriod = builder.acceptableTimePeriod;
        this.gpsWaitPeriod = builder.gpsWaitPeriod;
        this.networkWaitPeriod = builder.networkWaitPeriod;
        this.gpsDialogProvider = builder.gpsDialogProvider;
    }

    public Builder newBuilder() {
        return new Builder()
              .requiredTimeInterval(requiredTimeInterval)
              .requiredDistanceInterval(requiredDistanceInterval)
              .acceptableAccuracy(acceptableAccuracy)
              .acceptableTimePeriod(acceptableTimePeriod)
              .setWaitPeriod(ProviderType.GPS, gpsWaitPeriod)
              .setWaitPeriod(ProviderType.NETWORK, networkWaitPeriod)
              .gpsDialogProvider(gpsDialogProvider);
    }

    // region Getters
    public long requiredTimeInterval() {
        return requiredTimeInterval;
    }

    public long requiredDistanceInterval() {
        return requiredDistanceInterval;
    }

    public float acceptableAccuracy() {
        return acceptableAccuracy;
    }

    public long acceptableTimePeriod() {
        return acceptableTimePeriod;
    }

    public boolean askForEnableGPS() {
        return gpsDialogProvider != null;
    }

    @Nullable
    public DialogProvider gpsDialogProvider() {
        return gpsDialogProvider;
    }

    public long gpsWaitPeriod() {
        return gpsWaitPeriod;
    }

    public long networkWaitPeriod() {
        return networkWaitPeriod;
    }
    // endregion


    public static class Builder {

        private long requiredTimeInterval = com.lyokone.location.location.configuration.Defaults.LOCATION_INTERVAL;
        private long requiredDistanceInterval = com.lyokone.location.location.configuration.Defaults.LOCATION_DISTANCE_INTERVAL;
        private float acceptableAccuracy = com.lyokone.location.location.configuration.Defaults.MIN_ACCURACY;
        private long acceptableTimePeriod = com.lyokone.location.location.configuration.Defaults.TIME_PERIOD;
        private long gpsWaitPeriod = com.lyokone.location.location.configuration.Defaults.WAIT_PERIOD;
        private long networkWaitPeriod = com.lyokone.location.location.configuration.Defaults.WAIT_PERIOD;
        private DialogProvider gpsDialogProvider;
        private String gpsMessage = com.lyokone.location.location.configuration.Defaults.EMPTY_STRING;

        /**
         * TimeInterval will be used while getting location from default location providers
         * It will define in which period updates need to be delivered and will be used only when
         * {@linkplain com.lyokone.location.location.configuration.LocationConfiguration#keepTracking()} is set to true.
         * Default is {@linkplain com.lyokone.location.location.configuration.Defaults#LOCATION_INTERVAL}
         */
        public Builder requiredTimeInterval(long requiredTimeInterval) {
            if (requiredTimeInterval < 0) {
                throw new IllegalArgumentException("requiredTimeInterval cannot be set to negative value.");
            }

            this.requiredTimeInterval = requiredTimeInterval;
            return this;
        }

        /**
         * DistanceInterval will be used while getting location from default location providers
         * It will define in which distance changes that we should receive an update and will be used only when
         * {@linkplain LocationConfiguration#keepTracking()} is set to true.
         * Default is {@linkplain com.lyokone.location.location.configuration.Defaults#LOCATION_DISTANCE_INTERVAL}
         */
        public Builder requiredDistanceInterval(long requiredDistanceInterval) {
            if (requiredDistanceInterval < 0) {
                throw new IllegalArgumentException("requiredDistanceInterval cannot be set to negative value.");
            }

            this.requiredDistanceInterval = requiredDistanceInterval;
            return this;
        }

        /**
         * Minimum Accuracy that you seek location to be
         * Default is {@linkplain com.lyokone.location.location.configuration.Defaults#MIN_ACCURACY}
         */
        public Builder acceptableAccuracy(float acceptableAccuracy) {
            if (acceptableAccuracy < 0) {
                throw new IllegalArgumentException("acceptableAccuracy cannot be set to negative value.");
            }

            this.acceptableAccuracy = acceptableAccuracy;
            return this;
        }

        /**
         * Indicates time period that can be count as usable location,
         * this needs to be considered such as "last 5 minutes"
         * Default is {@linkplain com.lyokone.location.location.configuration.Defaults#TIME_PERIOD}
         */
        public Builder acceptableTimePeriod(long acceptableTimePeriod) {
            if (acceptableTimePeriod < 0) {
                throw new IllegalArgumentException("acceptableTimePeriod cannot be set to negative value.");
            }

            this.acceptableTimePeriod = acceptableTimePeriod;
            return this;
        }

        /**
         * Indicates what to display to user while asking to turn GPS on.
         * If you do not set this, user will not be asked to enable GPS.
         */
        public Builder gpsMessage(String gpsMessage) {
            this.gpsMessage = gpsMessage;
            return this;
        }

        /**
         * If you need to display a custom dialog to ask user to enable GPS, you can provide your own
         * implementation of {@linkplain DialogProvider} and manager will use that implementation to display the dialog.
         * Important, if you set your own implementation, please make sure to handle gpsMessage as well.
         * Because {@linkplain Builder#gpsMessage} will be ignored in that case.
         *
         * If you don't specify any dialogProvider implementation {@linkplain SimpleMessageDialogProvider} will be used with
         * given {@linkplain Builder#gpsMessage}
         */
        public Builder gpsDialogProvider(DialogProvider dialogProvider) {
            this.gpsDialogProvider = dialogProvider;
            return this;
        }

        /**
         * Indicates waiting time period before switching to next possible provider.
         * Possible to set provider wait periods separately by passing providerType as one of the
         * {@linkplain ProviderType} values.
         * Default values are {@linkplain Defaults#WAIT_PERIOD}
         */
        public Builder setWaitPeriod(@ProviderType int providerType, long milliseconds) {
            if (milliseconds < 0) {
                throw new IllegalArgumentException("waitPeriod cannot be set to negative value.");
            }

            switch (providerType) {
                case ProviderType.GOOGLE_PLAY_SERVICES: {
                    throw new IllegalStateException("GooglePlayServices waiting time period should be set on "
                          + "GooglePlayServicesConfiguration");
                }
                case ProviderType.NETWORK: {
                    this.networkWaitPeriod = milliseconds;
                    break;
                }
                case ProviderType.GPS: {
                    this.gpsWaitPeriod = milliseconds;
                    break;
                }
                case ProviderType.DEFAULT_PROVIDERS: {
                    this.gpsWaitPeriod = milliseconds;
                    this.networkWaitPeriod = milliseconds;
                    break;
                }
                case ProviderType.NONE: {
                    // ignored
                }
            }

            return this;
        }

        public DefaultProviderConfiguration build() {
            if (gpsDialogProvider == null && StringUtils.isNotEmpty(gpsMessage)) {
                gpsDialogProvider = new SimpleMessageDialogProvider(gpsMessage);
            }

            return new DefaultProviderConfiguration(this);
        }
    }
}
