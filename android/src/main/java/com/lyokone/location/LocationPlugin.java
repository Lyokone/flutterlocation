package com.lyokone.location;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter;
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

    private FlutterPluginBinding pluginBinding;
    private ActivityPluginBinding activityBinding;
    private Application application;
    private Activity activity;
    // This is null when not using v2 embedding;
    private Lifecycle lifecycle;
    private LifeCycleObserver observer;

    private class LifeCycleObserver implements Application.ActivityLifecycleCallbacks, DefaultLifecycleObserver {
        private final Activity thisActivity;

        LifeCycleObserver(Activity activity) {
            this.thisActivity = activity;
        }

        @Override
        public void onCreate(@NonNull LifecycleOwner owner) {
        }

        @Override
        public void onStart(@NonNull LifecycleOwner owner) {
        }

        @Override
        public void onResume(@NonNull LifecycleOwner owner) {
        }

        @Override
        public void onPause(@NonNull LifecycleOwner owner) {
        }

        @Override
        public void onStop(@NonNull LifecycleOwner owner) {
            onActivityStopped(thisActivity);
        }

        @Override
        public void onDestroy(@NonNull LifecycleOwner owner) {
            onActivityDestroyed(thisActivity);
        }

        @Override
        public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
        }

        @Override
        public void onActivityStarted(Activity activity) {
        }

        @Override
        public void onActivityResumed(Activity activity) {
        }

        @Override
        public void onActivityPaused(Activity activity) {
        }

        @Override
        public void onActivitySaveInstanceState(Activity activity, Bundle outState) {
        }

        @Override
        public void onActivityDestroyed(Activity activity) {
            if (thisActivity == activity && activity.getApplicationContext() != null) {
                ((Application) activity.getApplicationContext()).unregisterActivityLifecycleCallbacks(this);
            }
        }

        @Override
        public void onActivityStopped(Activity activity) {
        }
    }

    public static void registerWith(Registrar registrar) {
        FlutterLocation flutterLocation = new FlutterLocation(registrar.context(), registrar.activity());

        MethodCallHandlerImpl handler = new MethodCallHandlerImpl(flutterLocation);
        handler.startListening(registrar.messenger());

        StreamHandlerImpl streamHandlerImpl = new StreamHandlerImpl(flutterLocation);
        streamHandlerImpl.startListening(registrar.messenger());
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        pluginBinding = binding;

        location = new FlutterLocation(binding.getApplicationContext(), /* activity= */ null);
        methodCallHandler = new MethodCallHandlerImpl(location);
        methodCallHandler.startListening(binding.getBinaryMessenger());

        streamHandlerImpl = new StreamHandlerImpl(location);
        streamHandlerImpl.startListening(binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        pluginBinding = null;

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

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        location.setActivity(binding.getActivity());

        activityBinding = binding;
        setup(pluginBinding.getBinaryMessenger(), (Application) pluginBinding.getApplicationContext(),
                activityBinding.getActivity(), null, activityBinding);
    }

    @Override
    public void onDetachedFromActivity() {
        tearDown();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    private void setup(final BinaryMessenger messenger, final Application application, final Activity activity,
            final PluginRegistry.Registrar registrar, final ActivityPluginBinding activityBinding) {
        this.activity = activity;
        this.application = application;
        observer = new LifeCycleObserver(activity);
        if (registrar != null) {
            // V1 embedding setup for activity listeners.
            application.registerActivityLifecycleCallbacks(observer);
            registrar.addActivityResultListener(location);
            registrar.addRequestPermissionsResultListener(location);
        } else {
            // V2 embedding setup for activity listeners.
            activityBinding.addActivityResultListener(location);
            activityBinding.addRequestPermissionsResultListener(location);
            lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(activityBinding);
            lifecycle.addObserver(observer);
        }
    }

    private void tearDown() {
        activityBinding.removeActivityResultListener(location);
        activityBinding.removeRequestPermissionsResultListener(location);
        activityBinding = null;
        lifecycle.removeObserver(observer);
        lifecycle = null;
        location = null;
        application.unregisterActivityLifecycleCallbacks(observer);
        application = null;
    }

}
