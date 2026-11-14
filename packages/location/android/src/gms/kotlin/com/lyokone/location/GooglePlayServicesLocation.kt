package com.lyokone.location

import android.app.Activity
import android.content.Context
import android.content.IntentSender
import android.location.Location
import android.os.Looper
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.LocationAvailability
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.LocationSettingsRequest
import com.google.android.gms.location.LocationSettingsStatusCodes

/**
 * Null on devices without GMS (Huawei, some Chinese ROMs, AOSP), where touching
 * LocationServices throws SERVICE_INVALID.
 */
internal fun createPlayServicesLocation(context: Context): PlayServicesLocation? =
    if (GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context) == ConnectionResult.SUCCESS) {
        GooglePlayServicesLocation(context)
    } else {
        null
    }

private class GooglePlayServicesLocation(
    context: Context,
) : PlayServicesLocation {
    private val client = LocationServices.getFusedLocationProviderClient(context)
    private val settingsClient = LocationServices.getSettingsClient(context)
    private var request: LocationRequest? = null
    private var callback: LocationCallback? = null

    override fun configure(
        priority: Int,
        intervalMillis: Long,
        minUpdateIntervalMillis: Long,
        minUpdateDistanceMeters: Float,
    ) {
        request =
            LocationRequest
                .Builder(priority, intervalMillis)
                .setMinUpdateIntervalMillis(minUpdateIntervalMillis)
                .setMinUpdateDistanceMeters(minUpdateDistanceMeters)
                .build()
    }

    override fun requestUpdates(
        onLocation: (Location) -> Unit,
        onAvailabilityChanged: (Boolean) -> Unit,
    ) {
        val request = request ?: return
        removeUpdates()
        val callback =
            object : LocationCallback() {
                override fun onLocationAvailability(availability: LocationAvailability) =
                    onAvailabilityChanged(availability.isLocationAvailable)

                override fun onLocationResult(result: LocationResult) {
                    result.lastLocation?.let(onLocation)
                }
            }
        this.callback = callback
        client.requestLocationUpdates(request, callback, Looper.myLooper())
    }

    override fun removeUpdates() {
        callback?.let { client.removeLocationUpdates(it) }
        callback = null
    }

    override fun getLastLocation(
        onSuccess: (Location?) -> Unit,
        onFailure: (Exception) -> Unit,
    ) {
        client.lastLocation.addOnSuccessListener { onSuccess(it) }.addOnFailureListener { onFailure(it) }
    }

    override fun checkSettings(
        activity: Activity,
        requestCode: Int,
        onSuccess: () -> Unit,
        onFailure: (SettingsFailure, String?) -> Unit,
    ) {
        val request = request ?: return
        settingsClient
            .checkLocationSettings(LocationSettingsRequest.Builder().addLocationRequest(request).build())
            .addOnSuccessListener(activity) { onSuccess() }
            .addOnFailureListener(activity) { e ->
                if (e is ResolvableApiException && e.statusCode == LocationSettingsStatusCodes.RESOLUTION_REQUIRED) {
                    try {
                        e.startResolutionForResult(activity, requestCode)
                    } catch (sie: IntentSender.SendIntentException) {
                        onFailure(SettingsFailure.RESOLUTION_FAILED, sie.message)
                    }
                    return@addOnFailureListener
                }
                when ((e as? ApiException)?.statusCode) {
                    LocationSettingsStatusCodes.SETTINGS_CHANGE_UNAVAILABLE ->
                        onFailure(SettingsFailure.CHANGE_UNAVAILABLE, e.message)
                    ConnectionResult.SERVICE_INVALID,
                    ConnectionResult.SERVICE_MISSING,
                    ConnectionResult.SERVICE_DISABLED,
                    ConnectionResult.SERVICE_VERSION_UPDATE_REQUIRED,
                    CommonStatusCodes.API_NOT_CONNECTED,
                    -> onFailure(SettingsFailure.API_UNAVAILABLE, e.message)
                    else -> onFailure(SettingsFailure.UNEXPECTED, e.message)
                }
            }
    }
}
