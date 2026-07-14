package com.lyokone.location

import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler

private const val STREAM_CHANNEL_NAME = "lyokone/locationstream"

internal class StreamHandlerImpl : StreamHandler {
    private var location: FlutterLocation? = null
    private var channel: EventChannel? = null

    fun setLocation(location: FlutterLocation?) {
        this.location = location
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
        location.events = eventsSink
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
        val location = this.location ?: return
        location.mFusedLocationClient?.removeLocationUpdates(location.mLocationCallback)
        location.events = null
    }

    companion object {
        private const val TAG = "StreamHandlerImpl"
    }
}
