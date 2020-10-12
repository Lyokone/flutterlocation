package com.lyokone.location;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

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
    private FlutterLocation location;
    @Nullable
    private ActivityPluginBinding activityBinding;
    @Nullable
    private PluginRegistry.Registrar registrar;

    public static void registerWith(Registrar registrar) {
        LocationPlugin instance = new LocationPlugin();
        instance.registrar = registrar;
        instance.location = new FlutterLocation(registrar);
        instance.location.setActivity(registrar.activity());
        instance.setup();
        instance.initInstance(registrar.messenger());
    }

    private void initInstance(BinaryMessenger binaryMessenger) {
        methodCallHandler = new MethodCallHandlerImpl(location);
        methodCallHandler.startListening(binaryMessenger);
        streamHandlerImpl = new StreamHandlerImpl(location);
        streamHandlerImpl.startListening(binaryMessenger);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        location = new FlutterLocation(binding.getApplicationContext(), /* activity= */ null);
        this.initInstance(binding.getBinaryMessenger());
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
        location = null;
    }

    private void attachToActivity(ActivityPluginBinding binding) {
        activityBinding = binding;
        try {
            location.setActivity(binding.getActivity());
            this.setup();
        } catch(Exception e) {
            e.printStackTrace();
        }
    }

    private void detachActivity() {
        activityBinding.removeActivityResultListener(location);
        activityBinding.removeRequestPermissionsResultListener(location);
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

    private void setup() {
        if (registrar != null) {
            // V1 embedding setup for activity listeners.
            registrar.addActivityResultListener(location);
            registrar.addRequestPermissionsResultListener(location);
        } else {
            // V2 embedding setup for activity listeners.
            activityBinding.addActivityResultListener(location);
            activityBinding.addRequestPermissionsResultListener(location);
        }
    }
}
