package com.lyokone.location

import android.Manifest
import android.app.*
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class FlutterLocationService : Service(), PluginRegistry.RequestPermissionsResultListener {
    companion object {
        private const val TAG = "FlutterLocationService"

        private const val REQUEST_PERMISSIONS_REQUEST_CODE: Int = 641

        private const val ONGOING_NOTIFICATION_ID = 75418
        private const val CHANNEL_ID = "flutter_location_channel_01"
        private const val CHANNEL_NAME = "Location background service"
    }

    // Binder given to clients
    private val binder = LocalBinder()

    // Service is foreground
    private var isForeground = false

    private var activity: Activity? = null

    var location: FlutterLocation? = null
        private set

    // Store result until a permission check is resolved
    var result: MethodChannel.Result? = null

    val locationActivityResultListener: PluginRegistry.ActivityResultListener?
        get() = location

    val locationRequestPermissionsResultListener: PluginRegistry.RequestPermissionsResultListener?
        get() = location

    val serviceRequestPermissionsResultListener: PluginRegistry.RequestPermissionsResultListener?
        get() = this

    inner class LocalBinder : Binder() {
        fun getService(): FlutterLocationService = this@FlutterLocationService
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Creating service.")

        location = FlutterLocation(applicationContext, null)
    }

    override fun onBind(intent: Intent?): IBinder? {
        Log.d(TAG, "Binding to location service.")
        return binder
    }

    override fun onUnbind(intent: Intent?): Boolean {
        Log.d(TAG, "Unbinding from location service.")
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        Log.d(TAG, "Destroying service.")

        location = null

        super.onDestroy()
    }

    fun checkBackgroundPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            activity?.let {
                val locationPermissionState = ActivityCompat.checkSelfPermission(it,
                        Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                locationPermissionState == PackageManager.PERMISSION_GRANTED
            } ?: throw ActivityNotFoundException()
        } else {
            location?.checkPermissions() ?: false
        }
    }

    fun requestBackgroundPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            activity?.let {
                ActivityCompat.requestPermissions(it, arrayOf(
                        Manifest.permission.ACCESS_FINE_LOCATION,
                        Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                        REQUEST_PERMISSIONS_REQUEST_CODE)
            } ?: throw ActivityNotFoundException()
        } else {
            location?.result = this.result
            location?.requestPermissions()
            // result passed to Location reference here won't be needed
            this.result = null
        }
    }

    fun isInForegroundMode(): Boolean = isForeground

    fun enableBackgroundMode() {
        if (isForeground) {
            Log.d(TAG, "Service already in foreground mode.")
        } else {
            Log.d(TAG, "Start service in foreground mode.")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val notificationManager = NotificationManagerCompat.from(this)
                val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_NONE).apply {
                    lockscreenVisibility = Notification.VISIBILITY_PRIVATE
                }
                notificationManager.createNotificationChannel(channel)
            }

            val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
                    .setContentTitle(getText(R.string.notification_title))
                    .setSmallIcon(R.drawable.navigation_empty_icon)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .build()

            startForeground(ONGOING_NOTIFICATION_ID, notification)

            isForeground = true
        }
    }

    fun disableBackgroundMode() {
        Log.d(TAG, "Stop service in foreground.")
        stopForeground(true)

        isForeground = false
    }

    fun setActivity(activity: Activity?) {
        this.activity = activity
        location?.setActivity(activity)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>?, grantResults: IntArray?): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && requestCode == REQUEST_PERMISSIONS_REQUEST_CODE && permissions!!.size == 2 &&
                permissions[0] == Manifest.permission.ACCESS_FINE_LOCATION && permissions[1] == Manifest.permission.ACCESS_BACKGROUND_LOCATION) {
            if (grantResults!![0] == PackageManager.PERMISSION_GRANTED && grantResults[1] == PackageManager.PERMISSION_GRANTED) {
                // Permissions granted, background mode can be enabled
                enableBackgroundMode()
                result?.success(1)
                result = null
            } else {
                if (!shouldShowRequestBackgroundPermissionRationale()) {
                    result?.error("PERMISSION_DENIED_NEVER_ASK",
                            "Background location permission denied forever - please open app settings", null)
                } else {
                    result?.error("PERMISSION_DENIED", "Background location permission denied", null)
                }
                result = null
            }
        }
        return false
    }

    private fun shouldShowRequestBackgroundPermissionRationale(): Boolean =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                activity?.let {
                    ActivityCompat.shouldShowRequestPermissionRationale(it, Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                } ?: throw ActivityNotFoundException()
            } else {
                false
            }
}
