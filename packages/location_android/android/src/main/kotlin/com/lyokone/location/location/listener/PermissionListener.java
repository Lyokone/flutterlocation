package com.lyokone.location.location.listener;

public interface PermissionListener {

    /**
     * Notify when user is granted all required permissions
     */
    void onPermissionsGranted();

    /**
     * Notify when user is denied any one of required permissions
     */
    void onPermissionsDenied();
}
