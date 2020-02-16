package com.lyokone.location;

import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.PluginRegistry.Registrar;

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

    public static void registerWith(Registrar registrar) {
        MethodCallHandlerImpl handler = new MethodCallHandlerImpl(
                new FlutterLocation(registrar.context(), registrar.activity()));
        handler.startListening(registrar.messenger());

        StreamHandlerImpl streamHandlerImpl = new StreamHandlerImpl(
                new FlutterLocation(registrar.context(), registrar.activity()));
        streamHandlerImpl.startListening(registrar.messenger());
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        location = new FlutterLocation(binding.getApplicationContext(), /* activity= */ null);
        methodCallHandler = new MethodCallHandlerImpl(location);
        methodCallHandler.startListening(binding.getBinaryMessenger());

        streamHandlerImpl = new StreamHandlerImpl(location);
        streamHandlerImpl.startListening(binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (methodCallHandler == null) {
            Log.wtf(TAG, "Already detached from the engine.");
            return;
        }
        methodCallHandler.stopListening();
        methodCallHandler = null;

        if (streamHandlerImpl == null) {
            Log.wtf(TAG, "Already detached from the engine.");
            return;
        }
        streamHandlerImpl.stopListening();
        streamHandlerImpl = null;

        location = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        if (methodCallHandler == null) {
            Log.wtf(TAG, "location was never set.");
            return;
        }

        location.setActivity(binding.getActivity());
    }

    @Override
    public void onDetachedFromActivity() {
        if (methodCallHandler == null) {
            Log.wtf(TAG, "location was never set.");
            return;
        }

        location.setActivity(null);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

}
