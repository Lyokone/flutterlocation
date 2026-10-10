package com.lyokone.location

import android.app.Activity
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler

private const val STREAM_CHANNEL_NAME = "lyokone/locationstream"

internal class StreamHandlerImpl : StreamHandler {
    private var location: FlutterLocation? = null
    private var locationService: FlutterLocationService? = null
    private var channel: EventChannel? = null

    /** The sink this handler registered on the shared [FlutterLocation], if any. */
    private var activeSink: EventSink? = null

    private var activityProvider: (() -> Activity?)? = null

    /** Lets the plugin re-supply its current activity if the shared one was lost. */
    fun setActivityProvider(provider: (() -> Activity?)?) {
        this.activityProvider = provider
    }

    fun setLocationService(locationService: FlutterLocationService?) {
        this.locationService = locationService
    }

    fun setLocation(location: FlutterLocation?) {
        val previous = this.location
        // Detaching while our stream is live: Flutter never sends onCancel when
        // an engine is destroyed, so the shared FlutterLocation would keep
        // delivering fixes to a dead sink and never reach its "no stream, stop
        // updates" branch -- GPS would stay on until the process died. Only
        // touch it if the live sink is ours; another plugin instance may have
        // registered its own by now.
        if (location == null && previous != null) releaseSharedStream(previous)
        if (location == null) activeSink = null
        this.location = location
    }

    /**
     * Drops our sink from the shared [FlutterLocation] and stops updates unless
     * a one-shot getLocation() (possibly from another plugin instance) is still
     * waiting for a fix -- onNewLocation stops updates itself once that is served.
     */
    private fun releaseSharedStream(location: FlutterLocation) {
        val sink = activeSink ?: return
        if (location.events !== sink) return
        location.events = null
        if (location.getLocationResults.isEmpty()) location.stopLocationUpdates()
    }

    /**
     * Registers this instance as a stream events handler on the given [messenger].
     */
    fun startListening(messenger: BinaryMessenger) {
        if (channel != null) {
            Log.wtf(TAG, "Setting a method call handler before the last was disposed.")
            stopListening()
        }

        channel =
            EventChannel(messenger, STREAM_CHANNEL_NAME).apply {
                setStreamHandler(this@StreamHandlerImpl)
            }
    }

    /**
     * Clears this instance from listening to stream events.
     */
    fun stopListening() {
        val channel = this.channel
        if (channel == null) {
            Log.d(TAG, "Tried to stop listening when no EventChannel had been initialized.")
            return
        }

        channel.setStreamHandler(null)
        this.channel = null
    }

    override fun onListen(
        arguments: Any?,
        eventsSink: EventSink,
    ) {
        val location = this.location ?: return
        locationService?.ensureLiveActivity(activityProvider?.invoke())
        location.events = eventsSink
        activeSink = eventsSink
        if (location.activity == null) {
            eventsSink.error("NO_ACTIVITY", null, null)
            return
        }

        if (!location.checkPermissions()) {
            location.requestPermissions()
            return
        }
        location.startRequestingLocation()
    }

    override fun onCancel(arguments: Any?) {
        // Only tear down the shared stream if it is still ours: a newer plugin
        // instance may have registered its own sink since we listened.
        val location = this.location
        if (location != null) releaseSharedStream(location)
        activeSink = null
    }

    companion object {
        private const val TAG = "StreamHandlerImpl"
    }
}
