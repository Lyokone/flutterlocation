package com.lyokone.location.location.configuration;

import com.lyokone.location.location.configuration.Defaults;
import com.lyokone.location.location.helper.StringUtils;
import com.lyokone.location.location.providers.dialogprovider.DialogProvider;
import com.lyokone.location.location.providers.dialogprovider.SimpleMessageDialogProvider;
import com.lyokone.location.location.providers.permissionprovider.DefaultPermissionProvider;
import com.lyokone.location.location.providers.permissionprovider.PermissionProvider;

public class PermissionConfiguration {

    private final PermissionProvider permissionProvider;

    private PermissionConfiguration(Builder builder) {
        this.permissionProvider = builder.permissionProvider;
    }

    public PermissionProvider permissionProvider() {
        return permissionProvider;
    }

    public static class Builder {

        private String rationaleMessage = com.lyokone.location.location.configuration.Defaults.EMPTY_STRING;
        private String[] requiredPermissions = com.lyokone.location.location.configuration.Defaults.LOCATION_PERMISSIONS;
        private DialogProvider rationaleDialogProvider;
        private PermissionProvider permissionProvider;

        /**
         * Indicates what to display when user needs to see a rational dialog for RuntimePermission.
         * There is no default value, so if you do not set this, user will not see any rationale dialog.
         *
         * And if you set {@linkplain Builder#rationaleDialogProvider(DialogProvider)} then this
         * field will be ignored. Please make sure you handled in your custom dialogProvider implementation.
         */
        public Builder rationaleMessage(String rationaleMessage) {
            this.rationaleMessage = rationaleMessage;
            return this;
        }

        /**
         * If you need to ask any other permissions beside {@linkplain Defaults#LOCATION_PERMISSIONS}
         * or you may not need both of those permissions, you can change permissions
         * by calling this method with new permissions' array.
         */
        public Builder requiredPermissions(String[] permissions) {
            if (permissions == null || permissions.length == 0) {
                throw new IllegalArgumentException("requiredPermissions cannot be empty.");
            }

            this.requiredPermissions = permissions;
            return this;
        }

        /**
         * If you need to display a custom dialog to display rationale to user, you can provide your own
         * implementation of {@linkplain DialogProvider} and manager will use that implementation to display the dialog.
         * Important, if you set your own implementation, please make sure to handle rationaleMessage as well.
         * Because {@linkplain Builder#rationaleMessage} will be ignored in that case.
         *
         * If you don't specify any dialogProvider implementation {@linkplain SimpleMessageDialogProvider} will be used with
         * given {@linkplain Builder#rationaleMessage}
         */
        public Builder rationaleDialogProvider(DialogProvider dialogProvider) {
            this.rationaleDialogProvider = dialogProvider;
            return this;
        }

        /**
         * If you already have a mechanism to handle runtime permissions, you can provide your own implementation of
         * {@linkplain PermissionProvider} and manager will use that implementation to ask required permissions.
         * Important, if you set your own implementation, please make sure to handle dialogProvider as well.
         * Because {@linkplain Builder#rationaleDialogProvider} will be ignored in that case.
         *
         * If you don't specify any permissionProvider implementation {@linkplain DefaultPermissionProvider} will be used
         * with given {@linkplain Builder#rationaleDialogProvider}
         */
        public Builder permissionProvider(PermissionProvider permissionProvider) {
            this.permissionProvider = permissionProvider;
            return this;
        }

        public PermissionConfiguration build() {
            if (rationaleDialogProvider == null && StringUtils.isNotEmpty(rationaleMessage)) {
                rationaleDialogProvider = new SimpleMessageDialogProvider(rationaleMessage);
            }

            if (permissionProvider == null) {
                permissionProvider = new DefaultPermissionProvider(requiredPermissions, rationaleDialogProvider);
            }

            return new PermissionConfiguration(this);
        }
    }
}
