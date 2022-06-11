package com.lyokone.location.location.providers.permissionprovider;

import androidx.annotation.NonNull;

import com.lyokone.location.location.configuration.Defaults;
import com.lyokone.location.location.providers.permissionprovider.PermissionProvider;

public class StubPermissionProvider extends PermissionProvider {

    public StubPermissionProvider() {
        super(Defaults.LOCATION_PERMISSIONS, null);
    }

    @Override
    public boolean requestPermissions() {
        return false;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, @NonNull int[] grantResults) {
    }
}
