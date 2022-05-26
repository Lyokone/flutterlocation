package com.lyokone.location

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import com.google.android.gms.location.LocationRequest
import com.lyokone.location.location.LocationManager
import com.lyokone.location.location.configuration.*
import com.lyokone.location.location.constants.ProcessType
import com.lyokone.location.location.listener.LocationListener
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry


class LocationPlugin : FlutterPlugin, ActivityAware, LocationListener,
    PluginRegistry.RequestPermissionsResultListener,
    PluginRegistry.ActivityResultListener, GeneratedAndroidLocation.LocationHostApi {
    private var context: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var globalLocationConfigurationBuilder: LocationConfiguration.Builder? = null
    private var locationManager: LocationManager? = null

    private var resultsNeedingLocation: MutableList<GeneratedAndroidLocation.Result<GeneratedAndroidLocation.LocationData>?> =
        mutableListOf()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        GeneratedAndroidLocation.LocationHostApi.setup(flutterPluginBinding.binaryMessenger, this)
        context = flutterPluginBinding.applicationContext

    }


    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        GeneratedAndroidLocation.LocationHostApi.setup(binding.binaryMessenger, null)
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        activityBinding?.addActivityResultListener(this)
        activityBinding?.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        activityBinding?.removeActivityResultListener(this)
        activityBinding?.removeRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
        activityBinding?.removeActivityResultListener(this)
        activityBinding?.removeRequestPermissionsResultListener(this)
    }

    override fun onProcessTypeChanged(processType: Int) {
        Log.d("Location", "onProcessTypeChanged")
        when (processType) {
            ProcessType.ASKING_PERMISSIONS -> {
                Log.d("Location", "ASKING_PERMISSIONS")
            }
            ProcessType.GETTING_LOCATION_FROM_CUSTOM_PROVIDER -> {
                Log.d("Location", "GETTING_LOCATION_FROM_CUSTOM_PROVIDER")
            }
            ProcessType.GETTING_LOCATION_FROM_GOOGLE_PLAY_SERVICES -> {
                Log.d("Location", "GETTING_LOCATION_FROM_GOOGLE_PLAY_SERVICES")
            }
            ProcessType.GETTING_LOCATION_FROM_GPS_PROVIDER -> {
                Log.d("Location", "GETTING_LOCATION_FROM_GPS_PROVIDER")
            }
            ProcessType.GETTING_LOCATION_FROM_NETWORK_PROVIDER -> {
                Log.d("Location", "GETTING_LOCATION_FROM_NETWORK_PROVIDER")
            }
        }
    }

    override fun onLocationChanged(location: Location?) {
        Log.d("LOCATION", location?.latitude.toString() + " " + location?.longitude.toString())
        for (result in resultsNeedingLocation) {
            if (result == null) {
                return
            }
            result.success(
                GeneratedAndroidLocation.LocationData.Builder().setLatitude(location!!.latitude)
                    .setLongitude(location.longitude).build()
            )
        }
        resultsNeedingLocation = mutableListOf()
    }

    override fun onLocationFailed(type: Int) {
        Log.d("Location", "onLocationFailed")
    }

    override fun onPermissionGranted(alreadyHadPermission: Boolean) {
        Log.d("Location", "onPermissionGranted")
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {
        Log.d("Location", "onStatusChanged")
    }

    override fun onProviderEnabled(provider: String?) {
        Log.d("Location", "onProviderEnabled")
    }

    override fun onProviderDisabled(provider: String?) {
        Log.d("Location", "onProviderDisabled")
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        Log.d("Location", "onRequestPermissionsResult")
        locationManager?.onRequestPermissionsResult(requestCode, permissions, grantResults)
        return true
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        Log.d("Location", "onActivityResult")
        locationManager?.onActivityResult(requestCode, resultCode, data)
        return true
    }

    override fun getLocation(result: GeneratedAndroidLocation.Result<GeneratedAndroidLocation.LocationData>?) {
        resultsNeedingLocation.add(result)

        Defaults.createDefaultLocationRequest()


        globalLocationConfigurationBuilder = LocationConfiguration.Builder()
            .keepTracking(false)
            .askForPermission(PermissionConfiguration.Builder().rationaleMessage("Hey").build())
            .useGooglePlayServices(
                GooglePlayServicesConfiguration.Builder().build()
            )
            .useDefaultProviders(
                DefaultProviderConfiguration.Builder().requiredTimeInterval(2 * 1000)
                    .gpsMessage("Gimme").build()
            )

        locationManager = LocationManager.Builder(context!!)
            .activity(activity) // Only required to ask permission and/or GoogleApi - SettingsApi
            .configuration(globalLocationConfigurationBuilder!!.build())
            .notify(this)
            .build()

        locationManager?.get()

    }

    private fun getPriorityFromAccuracy(accuracy: GeneratedAndroidLocation.LocationAccuracy): Int {
        return when (accuracy) {
            GeneratedAndroidLocation.LocationAccuracy.powerSave -> LocationRequest.PRIORITY_NO_POWER
            GeneratedAndroidLocation.LocationAccuracy.low -> LocationRequest.PRIORITY_LOW_POWER
            GeneratedAndroidLocation.LocationAccuracy.balanced -> LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY
            GeneratedAndroidLocation.LocationAccuracy.high -> LocationRequest.PRIORITY_HIGH_ACCURACY
            GeneratedAndroidLocation.LocationAccuracy.navigation -> LocationRequest.PRIORITY_HIGH_ACCURACY
        }
    }

    override fun setLocationSettings(settings: GeneratedAndroidLocation.LocationSettings) {
        val locationConfiguration = LocationConfiguration.Builder()

        if (settings.askForPermission) {
            val permissionConfiguration = PermissionConfiguration.Builder()
                .rationaleMessage(settings.rationaleMessageForPermissionRequest)

            locationConfiguration.askForPermission(permissionConfiguration.build())
        }

        if (settings.useGooglePlayServices) {
            val googlePlayServices = GooglePlayServicesConfiguration.Builder()
            googlePlayServices.askForGooglePlayServices(settings.askForGooglePlayServices)
                .askForSettingsApi(settings.askForGPS)
                .fallbackToDefault(settings.fallbackToGPS)
                .ignoreLastKnowLocation(settings.ignoreLastKnownPosition)


            val locationRequest = LocationRequest.create()

            if (settings.expirationDuration != null) {
                locationRequest.setExpirationDuration(settings.expirationDuration!!.toLong())
            }
            if (settings.expirationTime != null) {
                locationRequest.expirationTime = settings.expirationTime!!.toLong()
            }
            locationRequest.fastestInterval = (settings.fastestInterval.toLong())
            locationRequest.interval = settings.interval.toLong()
            locationRequest.priority = getPriorityFromAccuracy(settings.accuracy)

            if (settings.maxWaitTime != null) {
                locationRequest.maxWaitTime = settings.maxWaitTime!!.toLong()
            }
            if (settings.numUpdates != null) {
                locationRequest.numUpdates = settings.numUpdates!!.toInt()
            }
            locationRequest.smallestDisplacement = settings.smallestDisplacement.toFloat()
            locationRequest.isWaitForAccurateLocation = settings.waitForAccurateLocation

            googlePlayServices.locationRequest(locationRequest)

            locationConfiguration.useGooglePlayServices(googlePlayServices.build())
        }

        globalLocationConfigurationBuilder = locationConfiguration
    }
}