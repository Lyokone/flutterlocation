package com.lyokone.location

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.IntentSender
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.location.OnNmeaMessageListener
import android.os.Build
import android.os.Bundle
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationAvailability
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

private const val PREFS_NAME = "flutter_location_prefs"
private const val PREFS_KEY_PERMISSION_REQUESTED = "location_permission_requested"

class FlutterLocation(
    applicationContext: Context,
    activity: Activity?,
) : PluginRegistry.RequestPermissionsResultListener,
    PluginRegistry.ActivityResultListener {
    var activity: Activity? = activity
        set(value) {
            field = value
            if (value != null) {
                // Only wire up the Google Play services fused provider when GMS is
                // actually available. On devices without GMS (Huawei, some Chinese
                // ROMs, AOSP) touching LocationServices throws SERVICE_INVALID, so
                // we fall back to the Android framework LocationManager instead.
                if (isGooglePlayServicesAvailable) {
                    mFusedLocationClient = LocationServices.getFusedLocationProviderClient(value)
                    mSettingsClient = LocationServices.getSettingsClient(value)
                }

                createLocationCallback()
                createLocationRequest()
                buildLocationSettingsRequest()
            } else {
                stopLocationUpdates()
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

    // Number of satellites used in the last fix, parsed from NMEA (see
    // createLocationCallback). Location.extras' "satellites" key is a legacy
    // GPS-provider-only extra that the fused provider never populates, which
    // made satelliteNumber always report 0 (#808).
    private var mLastSatelliteCount: Int? = null

    // Parameters of the request
    private var updateIntervalMilliseconds = 5000L
    private var fastestUpdateIntervalMilliseconds = updateIntervalMilliseconds / 2
    private var locationAccuracy = Priority.PRIORITY_HIGH_ACCURACY
    private var distanceFilter = 0f

    // Optional interval (in milliseconds) to use while the app is in background
    // mode (i.e. the foreground service is running). When null, the regular
    // [updateIntervalMilliseconds] is used in the background as well.
    private var backgroundIntervalMilliseconds: Long? = null

    // Whether the app is currently operating in background mode. Driven by the
    // foreground service being enabled/disabled in [FlutterLocationService].
    private var isInBackground = false

    var events: EventSink? = null

    // Store result until a permission check is resolved
    var result: Result? = null

    // Store the result for the requestService, used in ActivityResult
    private var requestServiceResult: Result? = null

    // Pending getLocation() calls waiting for the next fix. A list rather than
    // a single field: overwriting a single pending Result silently orphaned an
    // earlier concurrent getLocation() call's Future forever when a second one
    // came in before the first resolved (#977). All pending calls resolve
    // together with the same fix/error.
    val getLocationResults: MutableList<Result> = mutableListOf()

    private val locationManager: LocationManager =
        applicationContext.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    private val sharedPreferences =
        applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    // Whether the location permission had already been requested from this app
    // before the request currently in flight. Captured right before calling
    // ActivityCompat.requestPermissions() (#1009): shouldShowRequestPermissionRationale()
    // returns false both before the permission has ever been asked for AND once
    // it has been permanently denied, so it alone can't tell a first-time denial
    // apart from "don't ask again". Persisted so it survives process death.
    private var permissionPreviouslyRequested = false

    /**
     * Whether Google Play services (and therefore the fused location provider) is
     * usable on this device. Computed once: on devices without GMS every access
     * to `LocationServices` fails with SERVICE_INVALID, so this gates the entire
     * fused-provider path and enables the framework [LocationManager] fallback.
     */
    private val isGooglePlayServicesAvailable: Boolean =
        GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(applicationContext) ==
            ConnectionResult.SUCCESS

    /**
     * Framework [LocationManager] listener used only when GMS is unavailable.
     * All four callbacks are overridden explicitly (rather than a SAM lambda) so
     * no `AbstractMethodError` is raised on API levels below 30, where these
     * methods were not yet default on the interface.
     */
    private val mFrameworkLocationListener: LocationListener =
        object : LocationListener {
            override fun onLocationChanged(location: Location) {
                onNewLocation(location)
            }

            @Deprecated("Deprecated in Java")
            override fun onStatusChanged(
                provider: String?,
                status: Int,
                extras: Bundle?,
            ) {
            }

            override fun onProviderEnabled(provider: String) {}

            override fun onProviderDisabled(provider: String) {
                // Only surface an error once every provider is gone (checkServiceEnabled
                // is the same OR-of-providers check used elsewhere); disabling just GPS
                // while network location is still on shouldn't error out an active
                // stream (#535).
                if (!checkServiceEnabled()) {
                    sendError("SERVICE_STATUS_DISABLED", "Location services were disabled", null)
                }
            }
        }

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
                if (getLocationResults.isNotEmpty() || events != null) {
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
                // shouldShowRequestPermissionRationale() returns false both before the
                // permission has ever been requested and once it's permanently denied
                // ("don't ask again"), so on its own it can't distinguish a first-time
                // denial/dismissal from a real "never ask again" (#1009). Only treat it
                // as permanently denied when we know a prior request already happened.
                if (!shouldShowRequestPermissionRationale() && permissionPreviouslyRequested) {
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
                // This resolution dialog is triggered by startRequestingLocation(), on
                // behalf of a pending getLocation() one-shot call and/or an active
                // onLocationChanged stream -- getLocationResult/events, not the
                // requestPermission()-only `result` field this used to (incorrectly)
                // check, which is virtually always null here. Checking the wrong field
                // meant getLocation() hung forever if the user cancelled this dialog,
                // since neither field was ever resolved (#728, #1020).
                if (getLocationResults.isEmpty() && events == null) return false
                if (resultCode == Activity.RESULT_OK) {
                    startRequestingLocation()
                    return true
                }
                sendError("SERVICE_STATUS_DISABLED", "Failed to get location. Location services disabled", null)
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
        backgroundIntervalMilliseconds: Long? = null,
    ) {
        this.locationAccuracy = newLocationAccuracy ?: Priority.PRIORITY_HIGH_ACCURACY
        this.updateIntervalMilliseconds = updateIntervalMilliseconds
        this.fastestUpdateIntervalMilliseconds = fastestUpdateIntervalMilliseconds
        this.distanceFilter = distanceFilter
        this.backgroundIntervalMilliseconds = backgroundIntervalMilliseconds

        createLocationCallback()
        createLocationRequest()
        buildLocationSettingsRequest()
        startRequestingLocation()
    }

    /**
     * Notifies the location request that the app has entered or left background
     * mode. When a distinct [backgroundIntervalMilliseconds] is configured, the
     * location request is rebuilt with the appropriate interval and, if a stream
     * is active, updates are re-registered to take effect immediately.
     */
    fun setBackgroundMode(inBackground: Boolean) {
        if (isInBackground == inBackground) {
            return
        }
        isInBackground = inBackground

        // Nothing to do if no separate background interval was requested.
        if (backgroundIntervalMilliseconds == null) {
            return
        }

        createLocationRequest()
        buildLocationSettingsRequest()

        // Only re-register updates when actively streaming locations.
        if (events != null) {
            startRequestingLocation()
        }
    }

    private fun sendError(
        errorCode: String,
        errorMessage: String,
        errorDetails: Any?,
    ) {
        getLocationResults.forEach { it.error(errorCode, errorMessage, errorDetails) }
        getLocationResults.clear()
        events?.error(errorCode, errorMessage, errorDetails)
        events = null
    }

    /**
     * Delivers a freshly received [location] to the pending one-shot result
     * and/or the active event stream. Shared by both the fused-provider callback
     * and the framework [LocationManager] fallback so both paths emit exactly the
     * same map shape and honour the same one-shot/stream semantics.
     */
    private fun onNewLocation(location: Location) {
        val loc = locationToMap(location)

        getLocationResults.forEach { it.success(loc) }
        getLocationResults.clear()
        val events = this.events
        if (events != null) {
            events.success(loc)
        } else {
            // One-shot request satisfied (no active stream): stop updates.
            stopLocationUpdates()
        }
    }

    /** Removes any active location updates from whichever provider is in use. */
    fun stopLocationUpdates() {
        mLocationCallback?.let { mFusedLocationClient?.removeLocationUpdates(it) }
        locationManager.removeUpdates(mFrameworkLocationListener)
    }

    /** Creates a callback for receiving location events. */
    private fun createLocationCallback() {
        mLocationCallback?.let { mFusedLocationClient?.removeLocationUpdates(it) }
        mLocationCallback =
            object : LocationCallback() {
                override fun onLocationAvailability(locationAvailability: LocationAvailability) {
                    // isLocationAvailable can be false transiently (e.g. no fix yet,
                    // temporarily indoors) without the location service actually being
                    // disabled, so cross-check with checkServiceEnabled() -- the
                    // deterministic "is the system location toggle off" signal -- before
                    // erroring out an active stream (#535).
                    if (!locationAvailability.isLocationAvailable && !checkServiceEnabled()) {
                        sendError("SERVICE_STATUS_DISABLED", "Location services were disabled", null)
                    }
                }

                override fun onLocationResult(locationResult: LocationResult) {
                    val location = locationResult.lastLocation ?: return
                    onNewLocation(location)
                }
            }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            mMessageListener =
                OnNmeaMessageListener { message, _ ->
                    if (message.startsWith("$")) {
                        val tokens = message.split(",")
                        val type = tokens[0]

                        // Parse altitude above sea level and satellites used from the
                        // GGA sentence. Description of NMEA string:
                        // http://aprs.gids.nl/nmea/#gga
                        if (type.startsWith("\$GPGGA") && tokens.size > 9) {
                            if (tokens[7].isNotEmpty()) {
                                mLastSatelliteCount = tokens[7].toIntOrNull()
                            }
                            if (tokens[9].isNotEmpty()) {
                                mLastMslAltitude = tokens[9].toDoubleOrNull()
                            }
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
        // The "satellites" extra is only ever set by the legacy GPS provider;
        // the fused provider never populates it, so fall back to the NMEA-derived
        // count (see createLocationCallback) which works for both (#808).
        val satelliteCount =
            location.extras?.takeIf { it.containsKey("satellites") }?.getInt("satellites")
                ?: mLastSatelliteCount
        satelliteCount?.let { loc["satelliteNumber"] = it }

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
        if (!isGooglePlayServicesAvailable) {
            getLastKnownLocationFramework(result)
            return
        }
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

    /**
     * Framework fallback for [getLastKnownLocation] used when GMS is unavailable.
     * Returns the most recent cached fix across the GPS, network and passive
     * providers, or `null` when none is cached.
     */
    private fun getLastKnownLocationFramework(result: Result) {
        try {
            var best: Location? = null
            val providers =
                listOf(
                    LocationManager.GPS_PROVIDER,
                    LocationManager.NETWORK_PROVIDER,
                    LocationManager.PASSIVE_PROVIDER,
                )
            for (provider in providers) {
                val candidate = locationManager.getLastKnownLocation(provider) ?: continue
                if (best == null || candidate.time > best.time) {
                    best = candidate
                }
            }
            result.success(best?.let { locationToMap(it) })
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", e.message, null)
        } catch (e: IllegalArgumentException) {
            result.error("LAST_KNOWN_LOCATION_ERROR", e.message, null)
        }
    }

    /** Sets up the location request using the modern builder API. */
    private fun createLocationRequest() {
        val backgroundInterval = backgroundIntervalMilliseconds
        val interval: Long
        val fastestInterval: Long
        if (isInBackground && backgroundInterval != null) {
            interval = backgroundInterval
            fastestInterval = backgroundInterval / 2
        } else {
            interval = updateIntervalMilliseconds
            fastestInterval = fastestUpdateIntervalMilliseconds
        }

        mLocationRequest =
            LocationRequest.Builder(locationAccuracy, interval)
                .setMinUpdateIntervalMillis(fastestInterval)
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
        permissionPreviouslyRequested =
            sharedPreferences.getBoolean(PREFS_KEY_PERMISSION_REQUESTED, false)
        sharedPreferences.edit().putBoolean(PREFS_KEY_PERMISSION_REQUESTED, true).apply()
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

        if (!isGooglePlayServicesAvailable) {
            // Without GMS there is no system dialog to enable location from within
            // the app. Report it as disabled so the app can direct the user to the
            // device settings.
            requestServiceResult.error(
                "SERVICE_STATUS_DISABLED",
                "Failed to get location. Location services disabled",
                null,
            )
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
        if (!isGooglePlayServicesAvailable) {
            // No GMS: skip the fused-provider settings check (which would throw
            // SERVICE_INVALID) and request directly from the framework providers.
            registerNmeaListener()
            requestLocationUpdatesFramework()
            return
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
                } else if (isApiUnavailable(e)) {
                    // GMS reported itself as available but the LocationServices API
                    // is not actually connected on this device (e.g. SERVICE_INVALID
                    // on some OEM builds). Engage the framework fallback instead of
                    // throwing (#772, #944, #1015).
                    Log.i(TAG, "Google Play services location API unavailable, using framework provider.")
                    registerNmeaListener()
                    requestLocationUpdatesFramework()
                } else {
                    // This should not happen according to Android documentation but it has
                    // been observed on some phones.
                    sendError("UNEXPECTED_ERROR", e.message ?: "Unexpected error", null)
                }
            }
    }

    /**
     * Returns whether [e] indicates the Google Play services location API is not
     * usable on this device, in which case the framework fallback should engage.
     */
    private fun isApiUnavailable(e: Exception): Boolean {
        val code = (e as? ApiException)?.statusCode ?: return false
        return code == ConnectionResult.SERVICE_INVALID ||
            code == ConnectionResult.SERVICE_MISSING ||
            code == ConnectionResult.SERVICE_DISABLED ||
            code == ConnectionResult.SERVICE_VERSION_UPDATE_REQUIRED ||
            code == CommonStatusCodes.API_NOT_CONNECTED
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

    /**
     * Requests location updates from the Android framework [LocationManager],
     * used when Google Play services is unavailable. Registers on every enabled
     * provider among GPS and network so a fix is delivered whichever is
     * available; a single [mFrameworkLocationListener] receives all of them and
     * [stopLocationUpdates] deregisters it from all providers at once.
     */
    private fun requestLocationUpdatesFramework() {
        val backgroundInterval = backgroundIntervalMilliseconds
        val interval =
            if (isInBackground && backgroundInterval != null) {
                backgroundInterval
            } else {
                updateIntervalMilliseconds
            }
        val looper = Looper.myLooper() ?: Looper.getMainLooper()

        val providers = ArrayList<String>()
        if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
            providers.add(LocationManager.GPS_PROVIDER)
        }
        if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
            providers.add(LocationManager.NETWORK_PROVIDER)
        }
        if (providers.isEmpty()) {
            sendError("UNEXPECTED_ERROR", "No location provider is available", null)
            return
        }

        try {
            for (provider in providers) {
                locationManager.requestLocationUpdates(
                    provider,
                    interval,
                    distanceFilter,
                    mFrameworkLocationListener,
                    looper,
                )
            }
        } catch (e: SecurityException) {
            sendError("PERMISSION_DENIED", e.message ?: "Location permission denied", null)
        }
    }

    private fun isLocationFromMockProvider(location: Location): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            location.isMock
        } else {
            @Suppress("DEPRECATION")
            location.isFromMockProvider
        }
}
