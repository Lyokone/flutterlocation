package com.lyokone.location.location.helper;

import androidx.annotation.NonNull;

import com.lyokone.location.location.helper.logging.DefaultLogger;
import com.lyokone.location.location.helper.logging.Logger;

public final class LogUtils {

    private static boolean isEnabled = false;

    private static Logger activeLogger = new DefaultLogger();

    private LogUtils() {
        // No instance
    }

    public static void enable(boolean isEnabled) {
        LogUtils.isEnabled = isEnabled;
    }

    public static void setLogger(@NonNull Logger logger) {
        activeLogger = logger;
    }

    public static void logD(String message) {
        if (isEnabled) activeLogger.logD(getClassName(), message);
    }

    public static void logE(String message) {
        if (isEnabled) activeLogger.logE(getClassName(), message);
    }

    public static void logI(String message) {
        if (isEnabled) activeLogger.logI(getClassName(), message);
    }

    public static void logV(String message) {
        if (isEnabled) activeLogger.logV(getClassName(), message);
    }

    public static void logW(String message) {
        if (isEnabled) activeLogger.logW(getClassName(), message);
    }

    private static String getClassName() {
        StackTraceElement[] trace = Thread.currentThread().getStackTrace();
        StackTraceElement relevantTrace = trace[4];
        String className = relevantTrace.getClassName();
        int lastIndex = className.lastIndexOf('.');
        return className.substring(lastIndex + 1);
    }
}