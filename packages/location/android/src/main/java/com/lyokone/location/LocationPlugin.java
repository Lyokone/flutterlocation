package com.lyokone.location;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

/**
 * LocationPlugin
 */
public class LocationPlugin implements FlutterPlugin, ActivityAware {
    private static final String TAG = "LocationPlugin";
    @Nullable
    private MethodCallHandlerImpl methodCallHandler;
    @Nullable
    private StreamHandlerImpl streamHandlerImpl;
    @Nullable
    private FlutterLocationService locationService;
    @Nullable
    private ActivityPluginBinding activityBinding;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        methodCallHandler = new MethodCallHandlerImpl();
        methodCallHandler.startListening(binding.getBinaryMessenger());
        streamHandlerImpl = new StreamHandlerImpl();
        streamHandlerImpl.startListening(binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (methodCallHandler != null) {
            methodCallHandler.stopListening();
            methodCallHandler = null;
        }
        if (streamHandlerImpl != null) {
            streamHandlerImpl.stopListening();
            streamHandlerImpl = null;
        }
    }

    private void attachToActivity(ActivityPluginBinding binding) {
        activityBinding = binding;
        activityBinding.getActivity().bindService(new Intent(binding.getActivity(), FlutterLocationService.class), serviceConnection, Context.BIND_AUTO_CREATE);
    }

    private void detachActivity() {
        dispose();

        activityBinding.getActivity().unbindService(serviceConnection);
        activityBinding = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.attachToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        this.detachActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.detachActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        this.attachToActivity(binding);
    }

    private final ServiceConnection serviceConnection = new ServiceConnection() {

        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            Log.d(TAG, "Service connected: " + name);
            initialize(((FlutterLocationService.LocalBinder) service).getService());
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            Log.d(TAG, "Service disconnected:" + name);
        }
    };

    private void initialize(FlutterLocationService service) {
        locationService = service;

        locationService.setActivity(activityBinding.getActivity());

        activityBinding.addActivityResultListener(locationService.getLocationActivityResultListener());
        activityBinding.addRequestPermissionsResultListener(locationService.getLocationRequestPermissionsResultListener());
        activityBinding.addRequestPermissionsResultListener(locationService.getServiceRequestPermissionsResultListener());

        methodCallHandler.setLocation(locationService.getLocation());
        methodCallHandler.setLocationService(locationService);

        streamHandlerImpl.setLocation(locationService.getLocation());
    }

    private void dispose() {
        streamHandlerImpl.setLocation(null);

        methodCallHandler.setLocationService(null);
        methodCallHandler.setLocation(null);

        activityBinding.removeRequestPermissionsResultListener(locationService.getServiceRequestPermissionsResultListener());
        activityBinding.removeRequestPermissionsResultListener(locationService.getLocationRequestPermissionsResultListener());
        activityBinding.removeActivityResultListener(locationService.getLocationActivityResultListener());

        locationService.setActivity(null);

        locationService = null;
    }
}
