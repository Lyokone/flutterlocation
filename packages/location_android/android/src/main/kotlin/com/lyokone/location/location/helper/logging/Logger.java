package com.lyokone.location.location.helper.logging;

public interface Logger {
    void logD(String className, String message);

    void logE(String className, String message);

    void logI(String className, String message);

    void logV(String className, String message);

    void logW(String className, String message);
}
