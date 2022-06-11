package com.lyokone.location.location.helper.logging;

import android.util.Log;

import com.lyokone.location.location.helper.logging.Logger;

public class DefaultLogger implements Logger {
    public void logD(String className, String message) {
        Log.d(className, message);
    }

    public void logE(String className, String message) {
        Log.e(className, message);
    }

    public void logI(String className, String message) {
        Log.i(className, message);
    }

    public void logV(String className, String message) {
        Log.v(className, message);
    }

    public void logW(String className, String message) {
        Log.w(className, message);
    }
}
