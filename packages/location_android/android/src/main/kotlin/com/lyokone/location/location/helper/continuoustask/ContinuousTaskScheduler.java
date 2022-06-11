package com.lyokone.location.location.helper.continuoustask;

import com.lyokone.location.location.helper.continuoustask.ContinuousTask;

class ContinuousTaskScheduler {

    private final static long NONE = Long.MIN_VALUE;

    private final com.lyokone.location.location.helper.continuoustask.ContinuousTask task;

    private long requiredDelay = NONE;
    private long initialTime = NONE;
    private long remainingTime = NONE;

    private boolean isSet = false;

    ContinuousTaskScheduler(ContinuousTask task) {
        this.task = task;
    }

    boolean isSet() {
        return isSet;
    }

    void delayed(long delay) {
        requiredDelay = delay;
        remainingTime = requiredDelay;
        initialTime = task.getCurrentTime();

        set(delay);
    }

    void onPause() {
        if (requiredDelay != NONE) {
            release();
            remainingTime = requiredDelay - (task.getCurrentTime() - initialTime);
        }
    }

    void onResume() {
        if (remainingTime != NONE) {
            set(remainingTime);
        }
    }

    void onStop() {
        release();
        clean();
    }

    void set(long delay) {
        if (!isSet) {
            task.schedule(delay);
            isSet = true;
        }
    }

    void release() {
        task.unregister();
        isSet = false;
    }

    void clean() {
        requiredDelay = NONE;
        initialTime = NONE;
        remainingTime = NONE;
        isSet = false;
    }

}
