package com.lyokone.location

import android.app.Activity
import android.location.Location

/**
 * The Google Play services fused location provider, kept out of [FlutterLocation]
 * so that apps can leave Play services out of their build with
 * `location.playServices=false` in their `android/gradle.properties`.
 *
 * `src/gms` and `src/nogms` each provide `createPlayServicesLocation(Context)`,
 * which returns null when Play services is left out or unavailable.
 */
internal interface PlayServicesLocation {
    fun configure(
        priority: Int,
        intervalMillis: Long,
        minUpdateIntervalMillis: Long,
        minUpdateDistanceMeters: Float,
    )

    /** @throws SecurityException if the location permission was revoked. */
    fun requestUpdates(
        onLocation: (Location) -> Unit,
        onAvailabilityChanged: (Boolean) -> Unit,
    )

    fun removeUpdates()

    /** @throws SecurityException if the location permission was revoked. */
    fun getLastLocation(
        onSuccess: (Location?) -> Unit,
        onFailure: (Exception) -> Unit,
    )

    /**
     * Checks that the settings allow the configured request. If they don't but
     * can be changed, shows a dialog whose result goes to onActivityResult with
     * [requestCode], without calling either callback.
     */
    fun checkSettings(
        activity: Activity,
        requestCode: Int,
        onSuccess: () -> Unit,
        onFailure: (SettingsFailure, String?) -> Unit,
    )
}

internal enum class SettingsFailure { RESOLUTION_FAILED, CHANGE_UNAVAILABLE, API_UNAVAILABLE, UNEXPECTED }

/** The values of Play services' `Priority` constants. */
internal object Priority {
    const val PRIORITY_HIGH_ACCURACY = 100
    const val PRIORITY_BALANCED_POWER_ACCURACY = 102
    const val PRIORITY_LOW_POWER = 104
    const val PRIORITY_PASSIVE = 105
}
