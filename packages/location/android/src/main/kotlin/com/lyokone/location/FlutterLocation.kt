package com.lyokone.location

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.IntentSender
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.location.OnNmeaMessageListener
import android.os.Build
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.LocationSettingsRequest
import com.google.android.gms.location.LocationSettingsStatusCodes
import com.google.android.gms.location.Priority
import com.google.android.gms.location.SettingsClient
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

private const val TAG = "FlutterLocation"

private const val REQUEST_PERMISSIONS_REQUEST_CODE = 34
private const val REQUEST_CHECK_SETTINGS = 0x1
private const val GPS_ENABLE_REQUEST = 0x1001

class FlutterLocation(
    applicationContext: Context,
    activity: Activity?,
) : PluginRegistry.RequestPermissionsResultListener,
    PluginRegistry.ActivityResultListener {
    var activity: Activity? = activity
        set(value) {
            field = value
            if (value != null) {
                mFusedLocationClient = LocationServices.getFusedLocationProviderClient(value)
                mSettingsClient = LocationServices.getSettingsClient(value)

                createLocationCallback()
                createLocationRequest()
                buildLocationSettingsRequest()
            } else {
                mLocationCallback?.let { mFusedLocationClient?.removeLocationUpdates(it) }
                mFusedLocationClient = null
                mSettingsClient = null
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    mMessageListener?.let { locationManager.removeNmeaListener(it) }
                    mMessageListener = null
                }
            }
        }

    var mFusedLocationClient: FusedLocationProviderClient? = null
    private var mSettingsClient: SettingsClient? = null
    private var mLocationRequest: LocationRequest? = null
    private var mLocationSettingsRequest: LocationSettingsRequest? = null
    var mLocationCallback: LocationCallback? = null

    private var mMessageListener: OnNmeaMessageListener? = null

    private var mLastMslAltitude: Double? = null

    // Parameters of the request
    private var updateIntervalMilliseconds = 5000L
    private var fastestUpdateIntervalMilliseconds = updateIntervalMilliseconds / 2
    private var locationAccuracy = Priority.PRIORITY_HIGH_ACCURACY
    private var distanceFilter = 0f

    var events: EventSink? = null

    // Store result until a permission check is resolved
    var result: Result? = null

    // Store the result for the requestService, used in ActivityResult
    private var requestServiceResult: Result? = null

    // Store result until a location is getting resolved
    var getLocationResult: Result? = null

    private val locationManager: LocationManager =
        applicationContext.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    val mapFlutterAccuracy: Map<Int, Int> =
        mapOf(
            0 to Priority.PRIORITY_PASSIVE,
            1 to Priority.PRIORITY_LOW_POWER,
            2 to Priority.PRIORITY_BALANCED_POWER_ACCURACY,
            3 to Priority.PRIORITY_HIGH_ACCURACY,
            4 to Priority.PRIORITY_HIGH_ACCURACY,
            5 to Priority.PRIORITY_LOW_POWER,
        )

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode == REQUEST_PERMISSIONS_REQUEST_CODE && permissions.size == 2 &&
            grantResults.size == 2 &&
            permissions[0] == Manifest.permission.ACCESS_FINE_LOCATION &&
            permissions[1] == Manifest.permission.ACCESS_COARSE_LOCATION
        ) {
            val fineGranted = grantResults[0] == PackageManager.PERMISSION_GRANTED
            val coarseGranted = grantResults[1] == PackageManager.PERMISSION_GRANTED
            if (fineGranted || coarseGranted) {
                // Either precise or approximate location was granted.
                // Checks if this permission was automatically triggered by a location request
                if (getLocationResult != null || events != null) {
                    startRequestingLocation()
                }
                // Approximate-only (coarse without fine) on Android 12+ maps to
                // grantedLimited (3); precise access maps to granted (1) (#736).
                val code =
                    if (!fineGranted && coarseGranted && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        3
                    } else {
                        1
                    }
                result?.success(code)
                result = null
            } else {
                if (!shouldShowRequestPermissionRationale()) {
                    sendError(
                        "PERMISSION_DENIED_NEVER_ASK",
                        "Location permission denied forever - please open app settings",
                        null,
                    )
                    result?.success(2)
                    result = null
                } else {
                    sendError("PERMISSION_DENIED", "Location permission denied", null)
                    result?.success(0)
                    result = null
                }
            }
            return true
        }
        return false
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ): Boolean {
        when (requestCode) {
            GPS_ENABLE_REQUEST -> {
                val requestServiceResult = this.requestServiceResult ?: return false
                requestServiceResult.success(if (resultCode == Activity.RESULT_OK) 1 else 0)
                this.requestServiceResult = null
                return true
            }
            REQUEST_CHECK_SETTINGS -> {
                val result = this.result ?: return false
                if (resultCode == Activity.RESULT_OK) {
                    startRequestingLocation()
                    return true
                }
                result.error("SERVICE_STATUS_DISABLED", "Failed to get location. Location services disabled", null)
                this.result = null
                return true
            }
            else -> return false
        }
    }

    fun changeSettings(
        newLocationAccuracy: Int?,
        updateIntervalMilliseconds: Long,
        fastestUpdateIntervalMilliseconds: Long,
        distanceFilter: Float,
    ) {
        this.locationAccuracy = newLocationAccuracy ?: Priority.PRIORITY_HIGH_ACCURACY
        this.updateIntervalMilliseconds = updateIntervalMilliseconds
        this.fastestUpdateIntervalMilliseconds = fastestUpdateIntervalMilliseconds
        this.distanceFilter = distanceFilter

        createLocationCallback()
        createLocationRequest()
        buildLocationSettingsRequest()
        startRequestingLocation()
    }

    private fun sendError(
        errorCode: String,
        errorMessage: String,
        errorDetails: Any?,
    ) {
        getLocationResult?.error(errorCode, errorMessage, errorDetails)
        getLocationResult = null
        events?.error(errorCode, errorMessage, errorDetails)
        events = null
    }

    /** Creates a callback for receiving location events. */
    private fun createLocationCallback() {
        mLocationCallback?.let { mFusedLocationClient?.removeLocationUpdates(it) }
        mLocationCallback =
            object : LocationCallback() {
                override fun onLocationResult(locationResult: LocationResult) {
                    val location = locationResult.lastLocation ?: return
                    val loc = locationToMap(location)

                    getLocationResult?.success(loc)
                    getLocationResult = null
                    val events = this@FlutterLocation.events
                    if (events != null) {
                        events.success(loc)
                    } else {
                        mLocationCallback?.let { mFusedLocationClient?.removeLocationUpdates(it) }
                    }
                }
            }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            mMessageListener =
                OnNmeaMessageListener { message, _ ->
                    if (message.startsWith("$")) {
                        val tokens = message.split(",")
                        val type = tokens[0]

                        // Parse altitude above sea level. Description of NMEA string:
                        // http://aprs.gids.nl/nmea/#gga
                        if (type.startsWith("\$GPGGA") && tokens.size > 9 && tokens[9].isNotEmpty()) {
                            mLastMslAltitude = tokens[9].toDoubleOrNull()
                        }
                    }
                }
        }
    }

    /**
     * Serializes an Android [Location] into the map shape shared by the
     * location stream, the one-shot `getLocation` and `getLastKnownLocation`.
     */
    private fun locationToMap(location: Location): HashMap<String, Any?> {
        val loc = HashMap<String, Any?>()
        loc["latitude"] = location.latitude
        loc["longitude"] = location.longitude
        loc["accuracy"] = location.accuracy.toDouble()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            loc["verticalAccuracy"] = location.verticalAccuracyMeters.toDouble()
            loc["headingAccuracy"] = location.bearingAccuracyDegrees.toDouble()
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            loc["elapsedRealtimeUncertaintyNanos"] = location.elapsedRealtimeUncertaintyNanos
        }

        loc["provider"] = location.provider
        location.extras?.let { loc["satelliteNumber"] = it.getInt("satellites") }

        loc["elapsedRealtimeNanos"] = location.elapsedRealtimeNanos.toDouble()
        if (isLocationFromMockProvider(location)) {
            loc["isMock"] = 1.0
        }

        // Using NMEA data to get MSL level altitude
        val lastMslAltitude = mLastMslAltitude
        if (lastMslAltitude == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            loc["altitude"] = location.altitude
        } else {
            loc["altitude"] = lastMslAltitude
        }

        loc["speed"] = location.speed.toDouble()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            loc["speed_accuracy"] = location.speedAccuracyMetersPerSecond.toDouble()
        }
        loc["heading"] = location.bearing.toDouble()
        loc["time"] = location.time.toDouble()
        return loc
    }

    /**
     * Returns the last known location cached by the fused location provider
     * without waiting for a fresh fix. Succeeds with `null` when no cached
     * location is available.
     */
    fun getLastKnownLocation(result: Result) {
        val client = mFusedLocationClient
        if (client == null) {
            result.error("MISSING_ACTIVITY", "Location is not attached to an activity.", null)
            return
        }
        try {
            client.lastLocation
                .addOnSuccessListener { location ->
                    result.success(location?.let { locationToMap(it) })
                }
                .addOnFailureListener { e ->
                    result.error("LAST_KNOWN_LOCATION_ERROR", e.message, null)
                }
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", e.message, null)
        }
    }

    /** Sets up the location request using the modern builder API. */
    private fun createLocationRequest() {
        mLocationRequest =
            LocationRequest.Builder(locationAccuracy, updateIntervalMilliseconds)
                .setMinUpdateIntervalMillis(fastestUpdateIntervalMilliseconds)
                .setMinUpdateDistanceMeters(distanceFilter)
                .build()
    }

    /**
     * Builds a [LocationSettingsRequest] used for checking if a device has the
     * needed location settings.
     */
    private fun buildLocationSettingsRequest() {
        val request = mLocationRequest ?: return
        mLocationSettingsRequest =
            LocationSettingsRequest.Builder()
                .addLocationRequest(request)
                .build()
    }

    /** Returns the current state of the permissions needed. */
    fun checkPermissions(): Boolean {
        val activity = this.activity
        if (activity == null) {
            result?.error("MISSING_ACTIVITY", "You should not checkPermissions activation outside of an activity.", null)
            throw ActivityNotFoundException()
        }
        // Approximate (coarse) location counts as granted: a user who only
        // allows approximate location should still receive updates (#991).
        val fineState =
            ActivityCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION)
        val coarseState =
            ActivityCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_COARSE_LOCATION)
        return fineState == PackageManager.PERMISSION_GRANTED ||
            coarseState == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Returns whether background ("Allow all the time") location access has been
     * granted.
     *
     * On API 29+ (Android 10) background access is a dedicated runtime
     * permission, [Manifest.permission.ACCESS_BACKGROUND_LOCATION], distinct
     * from the foreground fine/coarse permissions. On older versions there is no
     * separate background permission — a foreground grant already allows
     * background access — so this mirrors [checkPermissions].
     */
    fun checkBackgroundPermissions(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return checkPermissions()
        }
        val activity = this.activity
        if (activity == null) {
            result?.error("MISSING_ACTIVITY", "You should not checkPermissions activation outside of an activity.", null)
            throw ActivityNotFoundException()
        }
        return ActivityCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_BACKGROUND_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun hasFineLocationPermission(): Boolean {
        val activity = this.activity ?: return false
        return ActivityCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun hasCoarseLocationPermission(): Boolean {
        val activity = this.activity ?: return false
        return ActivityCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
    }

    /**
     * Computes the permission status code sent to Dart:
     * 1 = granted (precise), 3 = grantedLimited (approximate-only), 0 = denied.
     *
     * On Android 12+ (API 31+) a user can grant only ACCESS_COARSE_LOCATION
     * (approximate) without ACCESS_FINE_LOCATION. That case maps to
     * grantedLimited, mirroring iOS reduced accuracy (#736).
     */
    fun permissionStatusCode(): Int {
        if (hasFineLocationPermission()) {
            return 1
        }
        if (hasCoarseLocationPermission()) {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) 3 else 1
        }
        return 0
    }

    fun requestPermissions() {
        val activity = this.activity
        if (activity == null) {
            result?.error("MISSING_ACTIVITY", "You should not requestPermissions activation outside of an activity.", null)
            throw ActivityNotFoundException()
        }
        if (checkPermissions()) {
            result?.success(permissionStatusCode())
            return
        }
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ),
            REQUEST_PERMISSIONS_REQUEST_CODE,
        )
    }

    fun shouldShowRequestPermissionRationale(): Boolean {
        val activity = this.activity ?: return false
        return ActivityCompat.shouldShowRequestPermissionRationale(
            activity,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) ||
            ActivityCompat.shouldShowRequestPermissionRationale(
                activity,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            )
    }

    /** Checks whether location services are enabled. */
    fun checkServiceEnabled(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            return locationManager.isLocationEnabled
        }
        val gpsEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        val networkEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        return gpsEnabled || networkEnabled
    }

    fun requestService(requestServiceResult: Result) {
        val activity = this.activity
        if (activity == null) {
            requestServiceResult.error("MISSING_ACTIVITY", "You should not requestService activation outside of an activity.", null)
            throw ActivityNotFoundException()
        }
        try {
            if (checkServiceEnabled()) {
                requestServiceResult.success(1)
                return
            }
        } catch (e: Exception) {
            requestServiceResult.error("SERVICE_STATUS_ERROR", "Location service status couldn't be determined", null)
            return
        }

        this.requestServiceResult = requestServiceResult
        val settingsRequest = mLocationSettingsRequest ?: return
        mSettingsClient?.checkLocationSettings(settingsRequest)?.addOnFailureListener(activity) { e ->
            if (e is ResolvableApiException) {
                when (e.statusCode) {
                    LocationSettingsStatusCodes.RESOLUTION_REQUIRED ->
                        try {
                            // Show the dialog by calling startResolutionForResult(), and check
                            // the result in onActivityResult().
                            e.startResolutionForResult(activity, GPS_ENABLE_REQUEST)
                        } catch (sie: IntentSender.SendIntentException) {
                            requestServiceResult.error("SERVICE_STATUS_ERROR", "Could not resolve location request", null)
                        }
                    LocationSettingsStatusCodes.SETTINGS_CHANGE_UNAVAILABLE ->
                        requestServiceResult.error(
                            "SERVICE_STATUS_DISABLED",
                            "Failed to get location. Location services disabled",
                            null,
                        )
                }
            } else {
                // This should not happen according to Android documentation but it has
                // been observed on some phones.
                requestServiceResult.error("SERVICE_STATUS_ERROR", "Unexpected error type received", null)
            }
        }
    }

    fun startRequestingLocation() {
        val activity = this.activity
        if (activity == null) {
            result?.error("MISSING_ACTIVITY", "You should not requestLocation activation outside of an activity.", null)
            throw ActivityNotFoundException()
        }
        val settingsRequest = mLocationSettingsRequest ?: return
        mSettingsClient?.checkLocationSettings(settingsRequest)
            ?.addOnSuccessListener(activity) {
                registerNmeaListener()
                requestLocationUpdates()
            }
            ?.addOnFailureListener(activity) { e ->
                if (e is ResolvableApiException) {
                    if (e.statusCode == LocationSettingsStatusCodes.RESOLUTION_REQUIRED) {
                        try {
                            // Show the dialog by calling startResolutionForResult(), and check
                            // the result in onActivityResult().
                            e.startResolutionForResult(activity, REQUEST_CHECK_SETTINGS)
                        } catch (sie: IntentSender.SendIntentException) {
                            Log.i(TAG, "PendingIntent unable to execute request.")
                        }
                    }
                } else if (e is ApiException &&
                    e.statusCode == LocationSettingsStatusCodes.SETTINGS_CHANGE_UNAVAILABLE
                ) {
                    // This error code happens during airplane mode.
                    registerNmeaListener()
                    requestLocationUpdates()
                } else {
                    // This should not happen according to Android documentation but it has
                    // been observed on some phones.
                    sendError("UNEXPECTED_ERROR", e.message ?: "Unexpected error", null)
                }
            }
    }

    private fun registerNmeaListener() {
        // NMEA messages are only delivered with precise (fine) location access.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && hasFineLocationPermission()) {
            mMessageListener?.let { locationManager.addNmeaListener(it, null) }
        }
    }

    private fun requestLocationUpdates() {
        val request = mLocationRequest ?: return
        val callback = mLocationCallback ?: return
        mFusedLocationClient?.requestLocationUpdates(request, callback, Looper.myLooper())
    }

    private fun isLocationFromMockProvider(location: Location): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            location.isMock
        } else {
            @Suppress("DEPRECATION")
            location.isFromMockProvider
        }
}
