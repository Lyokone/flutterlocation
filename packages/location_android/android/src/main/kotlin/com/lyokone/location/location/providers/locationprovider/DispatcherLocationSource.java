package com.lyokone.location.location.providers.locationprovider;

import android.app.Activity;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface.OnCancelListener;

import androidx.annotation.Nullable;

import com.google.android.gms.common.GoogleApiAvailability;
import com.lyokone.location.location.helper.continuoustask.ContinuousTask;
import com.lyokone.location.location.helper.continuoustask.ContinuousTask.ContinuousTaskRunner;
import com.lyokone.location.location.listener.FallbackListener;
import com.lyokone.location.location.providers.locationprovider.DefaultLocationProvider;
import com.lyokone.location.location.providers.locationprovider.GooglePlayServicesLocationProvider;

class DispatcherLocationSource {

    static final String GOOGLE_PLAY_SERVICE_SWITCH_TASK = "googlePlayServiceSwitchTask";

    private ContinuousTask gpServicesSwitchTask;

    DispatcherLocationSource(ContinuousTaskRunner continuousTaskRunner) {
        this.gpServicesSwitchTask = new ContinuousTask(GOOGLE_PLAY_SERVICE_SWITCH_TASK, continuousTaskRunner);
    }

    com.lyokone.location.location.providers.locationprovider.DefaultLocationProvider createDefaultLocationProvider() {
        return new DefaultLocationProvider();
    }

    GooglePlayServicesLocationProvider createGooglePlayServicesLocationProvider(FallbackListener fallbackListener) {
        return new GooglePlayServicesLocationProvider(fallbackListener);
    }

    ContinuousTask gpServicesSwitchTask() {
        return gpServicesSwitchTask;
    }

    int isGoogleApiAvailable(Context context) {
        if (context == null) return -1;
        return GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context);
    }

    boolean isGoogleApiErrorUserResolvable(int gpServicesAvailability) {
        return GoogleApiAvailability.getInstance().isUserResolvableError(gpServicesAvailability);
    }

    @Nullable Dialog getGoogleApiErrorDialog(Activity activity, int gpServicesAvailability, int requestCode,
          OnCancelListener onCancelListener) {
        if (activity == null) return null;
        return GoogleApiAvailability.getInstance()
              .getErrorDialog(activity, gpServicesAvailability, requestCode, onCancelListener);
    }

}
