package com.lyokone.location;

import android.app.Activity;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import java.util.concurrent.Executor;

public class UnusedTask<T> extends Task<T> {

  @NonNull
  @Override
  public Task<T> addOnFailureListener(@NonNull OnFailureListener onFailureListener) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<T> addOnFailureListener(@NonNull Activity activity,
      @NonNull OnFailureListener onFailureListener) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<T> addOnFailureListener(@NonNull Executor executor,
      @NonNull OnFailureListener onFailureListener) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<T> addOnSuccessListener(@NonNull OnSuccessListener<? super T> onSuccessListener) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<T> addOnSuccessListener(@NonNull Activity activity,
      @NonNull OnSuccessListener<? super T> onSuccessListener) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<T> addOnSuccessListener(@NonNull Executor executor,
      @NonNull OnSuccessListener<? super T> onSuccessListener) {
    throw new RuntimeException("method not implement");
  }

  @Nullable
  @Override
  public Exception getException() {
    throw new RuntimeException("method not implement");
  }

  @Override
  public T getResult() {
    throw new RuntimeException("method not implement");
  }

  @Override
  public <X extends Throwable> T getResult(@NonNull Class<X> aClass) throws X {
    throw new RuntimeException("method not implement");
  }

  @Override
  public boolean isCanceled() {
    return false;
  }

  @Override
  public boolean isComplete() {
    return false;
  }

  @Override
  public boolean isSuccessful() {
    return false;
  }
}
