package com.lyokone.location

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** LocationPlugin */
class LocationPlugin : FlutterPlugin, ActivityAware {
    private var methodCallHandler: MethodCallHandlerImpl? = null
    private var streamHandlerImpl: StreamHandlerImpl? = null
    private var locationService: FlutterLocationService? = null
    private var activityBinding: ActivityPluginBinding? = null

    private val serviceConnection =
        object : ServiceConnection {
            override fun onServiceConnected(
                name: ComponentName?,
                service: IBinder?,
            ) {
                Log.d(TAG, "Service connected: $name")
                if (service is FlutterLocationService.LocalBinder) {
                    initialize(service.getService())
                }
            }

            override fun onServiceDisconnected(name: ComponentName?) {
                Log.d(TAG, "Service disconnected: $name")
            }
        }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodCallHandler =
            MethodCallHandlerImpl().apply {
                startListening(binding.binaryMessenger)
            }
        streamHandlerImpl =
            StreamHandlerImpl().apply {
                startListening(binding.binaryMessenger)
            }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodCallHandler?.stopListening()
        methodCallHandler = null
        streamHandlerImpl?.stopListening()
        streamHandlerImpl = null
    }

    private fun attachToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.activity.bindService(
            Intent(binding.activity, FlutterLocationService::class.java),
            serviceConnection,
            Context.BIND_AUTO_CREATE,
        )
    }

    private fun detachActivity() {
        dispose()

        activityBinding?.activity?.unbindService(serviceConnection)
        activityBinding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attachToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        attachToActivity(binding)
    }

    private fun initialize(service: FlutterLocationService) {
        locationService = service

        service.setActivity(activityBinding?.activity)

        activityBinding?.let { binding ->
            service.locationActivityResultListener?.let(binding::addActivityResultListener)
            service.locationRequestPermissionsResultListener?.let(binding::addRequestPermissionsResultListener)
            binding.addRequestPermissionsResultListener(service.serviceRequestPermissionsResultListener)
        }

        methodCallHandler?.setLocation(service.location)
        methodCallHandler?.setLocationService(service)

        streamHandlerImpl?.setLocation(service.location)
    }

    private fun dispose() {
        streamHandlerImpl?.setLocation(null)

        methodCallHandler?.setLocationService(null)
        methodCallHandler?.setLocation(null)

        val service = locationService ?: return
        activityBinding?.let { binding ->
            binding.removeRequestPermissionsResultListener(service.serviceRequestPermissionsResultListener)
            service.locationRequestPermissionsResultListener?.let(binding::removeRequestPermissionsResultListener)
            service.locationActivityResultListener?.let(binding::removeActivityResultListener)
        }

        service.setActivity(null)
        locationService = null
    }

    companion object {
        private const val TAG = "LocationPlugin"
    }
}
