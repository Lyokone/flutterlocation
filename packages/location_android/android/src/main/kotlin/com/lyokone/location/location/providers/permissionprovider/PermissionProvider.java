package com.lyokone.location.location.providers.permissionprovider;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;

import androidx.annotation.CallSuper;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;

import com.lyokone.location.location.LocationManager;
import com.lyokone.location.location.helper.LogUtils;
import com.lyokone.location.location.listener.PermissionListener;
import com.lyokone.location.location.providers.dialogprovider.DialogProvider;
import com.lyokone.location.location.view.ContextProcessor;

import java.lang.ref.WeakReference;

public abstract class PermissionProvider {

    private WeakReference<ContextProcessor> weakContextProcessor;
    private WeakReference<PermissionListener> weakPermissionListener;
    private final String[] requiredPermissions;
    private DialogProvider rationalDialogProvider;

    /**
     * This class is responsible to get required permissions, and notify {@linkplain LocationManager}.
     *
     * @param requiredPermissions are required, setting this field empty will {@throws IllegalStateException}
     * @param rationaleDialogProvider will be used to display rationale dialog when it is necessary. If this field is set
     * to null, then rationale dialog will not be displayed to user at all.
     */
    public PermissionProvider(String[] requiredPermissions, @Nullable DialogProvider rationaleDialogProvider) {
        if (requiredPermissions == null || requiredPermissions.length == 0) {
            throw new IllegalStateException("You cannot create PermissionProvider without any permission required.");
        }

        this.requiredPermissions = requiredPermissions;
        this.rationalDialogProvider = rationaleDialogProvider;
    }

    /**
     * Return true if it is possible to ask permission, false otherwise
     */
    public abstract boolean requestPermissions();

    /**
     * This method needs to be called when permission results are received
     */
    public abstract void onRequestPermissionsResult(int requestCode,
          @Nullable String[] permissions, @NonNull int[] grantResults);

    public String[] getRequiredPermissions() {
        return requiredPermissions;
    }

    @Nullable public DialogProvider getDialogProvider() {
        return rationalDialogProvider;
    }

    @Nullable public PermissionListener getPermissionListener() {
        return weakPermissionListener.get();
    }

    @Nullable protected Context getContext() {
        return weakContextProcessor.get() == null ? null : weakContextProcessor.get().getContext();
    }

    @Nullable protected Activity getActivity() {
        return weakContextProcessor.get() == null ? null : weakContextProcessor.get().getActivity();
    }

    @Nullable protected Activity getFragment() {
        return weakContextProcessor.get() == null ? null : weakContextProcessor.get().getFragment().getActivity();
    }

    /**
     * This will be set internally by {@linkplain LocationManager} before any call is executed on PermissionProvider
     */
    @CallSuper
    public void setContextProcessor(ContextProcessor contextProcessor) {
        this.weakContextProcessor = new WeakReference<>(contextProcessor);
    }

    /**
     * This will be set internally by {@linkplain LocationManager} before any call is executed on PermissionProvider
     */
    @CallSuper public void setPermissionListener(PermissionListener permissionListener) {
        this.weakPermissionListener = new WeakReference<>(permissionListener);
    }

    /**
     * Return true if required permissions are granted, false otherwise
     */
    public boolean hasPermission() {
        if (getContext() == null) {
            LogUtils.logE("Couldn't check whether permissions are granted or not "
                  + "because of PermissionProvider doesn't contain any context.");
            return false;
        }

        for (String permission : getRequiredPermissions()) {
            if (checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }

    // For test purposes
    protected int checkSelfPermission(String permission) {
        return ContextCompat.checkSelfPermission(getContext(), permission);
    }

}
