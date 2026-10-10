package com.lyokone.location

import android.app.Activity
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.mockito.Mockito.CALLS_REAL_METHODS
import org.mockito.Mockito.doAnswer
import org.mockito.Mockito.doNothing
import org.mockito.Mockito.doReturn
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.verify

class SharedServiceOwnershipTest {
    // Bypass Android/GMS construction, but run the actual property accessors and
    // ownership code. Sensor registration is outside these JVM lifecycle tests.
    private fun location(): FlutterLocation {
        val location = mock(FlutterLocation::class.java, CALLS_REAL_METHODS)
        field(location, "getLocationResults", ArrayList<Result>())
        doReturn(true).`when`(location).checkPermissions()
        doNothing().`when`(location).startRequestingLocation()
        doNothing().`when`(location).stopLocationUpdates()
        doAnswer { invocation ->
            field(location, "activity", invocation.arguments[0])
            null
        }.`when`(location).activity = org.mockito.ArgumentMatchers.any()
        return location
    }

    private fun service(location: FlutterLocation): FlutterLocationService {
        val service = mock(FlutterLocationService::class.java, CALLS_REAL_METHODS)
        field(service, "location", location)
        return service
    }

    private fun field(
        target: Any,
        name: String,
        value: Any?,
    ) {
        target.javaClass.getDeclaredField(name).apply {
            isAccessible = true
            set(target, value)
        }
    }

    private fun attach(
        service: FlutterLocationService,
        activity: Activity,
    ): LocationPlugin {
        val binding = mock(ActivityPluginBinding::class.java)
        doReturn(activity).`when`(binding).activity
        val plugin = LocationPlugin()
        field(plugin, "activityBinding", binding)
        // The binding callback normally supplies the shared service through its
        // Android Binder. Inject the same service without an Android process.
        LocationPlugin::class.java.getDeclaredMethod("initialize", FlutterLocationService::class.java).apply {
            isAccessible = true
            invoke(plugin, service)
        }
        return plugin
    }

    private fun listen(
        location: FlutterLocation,
        sink: EventSink,
    ): StreamHandlerImpl {
        val handler = StreamHandlerImpl()
        handler.setLocation(location)
        handler.onListen(null, sink)
        return handler
    }

    @Test
    fun oldActivityDetachPreservesNewActivity() {
        val location = location()
        val service = service(location)
        val old = mock(Activity::class.java)
        val fresh = mock(Activity::class.java)
        val oldPlugin = attach(service, old)
        val freshPlugin = attach(service, fresh)

        oldPlugin.onDetachedFromActivity()

        assertTrue(service.hasActivity(fresh))
        assertSame(fresh, location.activity)
        freshPlugin.onDetachedFromActivity()
        assertFalse(service.hasActivity(fresh))
        assertNull(location.activity)
    }

    @Test
    fun nullActivityDoesNotOwnService() {
        val service = service(location())
        assertFalse(service.hasActivity(null))
    }

    @Test
    fun missingOrDeadActivityRecoversWithoutReplacingLiveActivity() {
        val location = location()
        val service = service(location)
        val old = mock(Activity::class.java)
        val fresh = mock(Activity::class.java)

        service.ensureLiveActivity(fresh)
        assertSame(fresh, location.activity)
        service.ensureLiveActivity(old)
        assertSame(fresh, location.activity)
        doReturn(true).`when`(fresh).isFinishing
        service.ensureLiveActivity(old)
        assertSame(old, location.activity)
        doReturn(true).`when`(old).isDestroyed
        service.ensureLiveActivity(null)
        assertSame(old, location.activity)
        service.ensureLiveActivity(fresh)
        assertSame(old, location.activity)
    }

    @Test
    fun methodCallRepairsMissingActivityBeforePermissionCheck() {
        val location = location()
        val service = service(location)
        val fresh = mock(Activity::class.java)
        val handler = MethodCallHandlerImpl()
        handler.setLocation(location)
        handler.setLocationService(service)
        handler.setActivityProvider { fresh }
        doAnswer {
            assertSame(fresh, location.activity)
            true
        }.`when`(location).checkPermissions()

        handler.onMethodCall(MethodCall("getLocation", null), mock(Result::class.java))

        assertSame(fresh, location.activity)
        verify(location).startRequestingLocation()
    }

    @Test
    fun streamListenRepairsMissingActivity() {
        val location = location()
        val service = service(location)
        val fresh = mock(Activity::class.java)
        val handler = StreamHandlerImpl()
        handler.setLocation(location)
        handler.setLocationService(service)
        handler.setActivityProvider { fresh }

        handler.onListen(null, mock(EventSink::class.java))

        assertSame(fresh, location.activity)
        verify(location).startRequestingLocation()
    }

    @Test
    fun oldStreamCancelAndDetachPreserveNewSink() {
        val location = location()
        field(location, "activity", mock(Activity::class.java))
        val oldHandler = listen(location, mock(EventSink::class.java))
        val freshSink = mock(EventSink::class.java)
        listen(location, freshSink)

        oldHandler.onCancel(null)
        oldHandler.setLocation(null)

        assertSame(freshSink, location.events)
        verify(location, never()).stopLocationUpdates()
    }

    @Test
    fun engineDetachReleasesOwnedStreamWithoutOnCancel() {
        val location = location()
        field(location, "activity", mock(Activity::class.java))
        val handler = listen(location, mock(EventSink::class.java))

        val plugin = LocationPlugin()
        field(plugin, "streamHandlerImpl", handler)
        plugin.onDetachedFromEngine(mock(FlutterPluginBinding::class.java))

        assertNull(location.events)
        verify(location).stopLocationUpdates()
    }

    @Test
    fun cancellingOwnedStreamPreservesConcurrentOneShot() {
        val location = location()
        field(location, "activity", mock(Activity::class.java))
        val handler = listen(location, mock(EventSink::class.java))
        location.getLocationResults.add(mock(Result::class.java))

        handler.onCancel(null)

        assertNull(location.events)
        assertTrue(location.getLocationResults.isNotEmpty())
        verify(location, never()).stopLocationUpdates()
    }

    @Test
    fun detachingOwnedStreamPreservesConcurrentOneShot() {
        val location = location()
        field(location, "activity", mock(Activity::class.java))
        val handler = listen(location, mock(EventSink::class.java))
        location.getLocationResults.add(mock(Result::class.java))

        handler.setLocation(null)

        assertNull(location.events)
        verify(location, never()).stopLocationUpdates()
    }

    @Test
    fun cancellingLastOwnedStreamStopsUpdatesOnce() {
        val location = location()
        field(location, "activity", mock(Activity::class.java))
        val handler = listen(location, mock(EventSink::class.java))

        handler.onCancel(null)
        handler.setLocation(null)

        assertNull(location.events)
        verify(location).stopLocationUpdates()
    }

    @Test
    fun engineDetachPreservesNewSink() {
        val location = location()
        field(location, "activity", mock(Activity::class.java))
        val oldHandler = listen(location, mock(EventSink::class.java))
        val freshSink = mock(EventSink::class.java)
        listen(location, freshSink)
        val plugin = LocationPlugin()
        field(plugin, "streamHandlerImpl", oldHandler)

        plugin.onDetachedFromEngine(mock(FlutterPluginBinding::class.java))

        assertSame(freshSink, location.events)
        verify(location, never()).stopLocationUpdates()
    }

    @Test
    fun engineDetachPreservesConcurrentOneShot() {
        val location = location()
        field(location, "activity", mock(Activity::class.java))
        val handler = listen(location, mock(EventSink::class.java))
        location.getLocationResults.add(mock(Result::class.java))
        val plugin = LocationPlugin()
        field(plugin, "streamHandlerImpl", handler)

        plugin.onDetachedFromEngine(mock(FlutterPluginBinding::class.java))

        assertNull(location.events)
        assertTrue(location.getLocationResults.isNotEmpty())
        verify(location, never()).stopLocationUpdates()
    }
}
