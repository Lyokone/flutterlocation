package com.lyokone.location;
import io.flutter.plugin.common.EventChannel;

public class LocationPermissionStreamHandler implements EventChannel.StreamHandler {
    EventChannel.EventSink sink;

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        sink = eventSink;
    }

    @Override
    public void onCancel(Object o) {
        sink = null;
    }

    public void sendPermissionData(boolean didGivePermission) {
        if(sink != null) {
            sink.success(didGivePermission);
        }
    }
}
