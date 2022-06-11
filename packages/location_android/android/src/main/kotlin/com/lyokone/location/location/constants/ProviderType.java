package com.lyokone.location.location.constants;

import androidx.annotation.IntDef;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

@IntDef({ProviderType.NONE, ProviderType.GOOGLE_PLAY_SERVICES,
      ProviderType.GPS, ProviderType.NETWORK, ProviderType.DEFAULT_PROVIDERS})
@Retention(RetentionPolicy.SOURCE)
public @interface ProviderType {

    int NONE = 0;
    int GOOGLE_PLAY_SERVICES = 1;
    int GPS = 2;
    int NETWORK = 3;
    int DEFAULT_PROVIDERS = 4; // Covers both GPS and NETWORK
    
}
