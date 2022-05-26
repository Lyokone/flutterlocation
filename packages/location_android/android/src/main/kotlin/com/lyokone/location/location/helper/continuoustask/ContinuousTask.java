package com.lyokone.location.location.helper.continuoustask;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;


public class ContinuousTask extends Handler implements Runnable {

    private final String taskId;
    private final ContinuousTaskScheduler continuousTaskScheduler;
    private final ContinuousTaskRunner continuousTaskRunner;

    public interface ContinuousTaskRunner {
        /**
         * Callback to take action when scheduled time is arrived.
         * Called with given taskId in order to distinguish which task should be run,
         * in case of same {@linkplain ContinuousTaskRunner} passed to multiple Tasks
         */
        void runScheduledTask(@NonNull String taskId);
    }

    public ContinuousTask(@NonNull String taskId, @NonNull ContinuousTaskRunner continuousTaskRunner) {
        super(Looper.getMainLooper());
        this.taskId = taskId;
        continuousTaskScheduler = new ContinuousTaskScheduler(this);
        this.continuousTaskRunner = continuousTaskRunner;
    }

    public void delayed(long delay) {
        continuousTaskScheduler.delayed(delay);
    }

    public void pause() {
        continuousTaskScheduler.onPause();
    }

    public void resume() {
        continuousTaskScheduler.onResume();
    }

    public void stop() {
        continuousTaskScheduler.onStop();
    }

    @Override
    public void run() {
        continuousTaskRunner.runScheduledTask(taskId);
    }

    void schedule(long delay) {
        postDelayed(this, delay);
    }

    void unregister() {
        removeCallbacks(this);
    }

    long getCurrentTime() {
        return System.currentTimeMillis();
    }
}
