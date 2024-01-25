package com.lyokone.location;

import android.app.PendingIntent;
import android.content.Context;
import android.location.Location;
import android.location.LocationManager;
import android.os.Looper;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.gms.common.api.Api.ApiOptions.NoOptions;
import com.google.android.gms.common.api.internal.ApiKey;
import com.google.android.gms.location.CurrentLocationRequest;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LastLocationRequest;
import com.google.android.gms.location.LocationAvailability;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.tasks.CancellationToken;
import com.google.android.gms.tasks.Task;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.Executor;

public class GPSFusedLocationProviderClient implements FusedLocationProviderClient,
    android.location.LocationListener {

  private final LocationManager locationManager;

  private final List<LocationCallback> locationCallbacks = new LinkedList<>();

  private final Object lock = new Object();

  public static GPSFusedLocationProviderClient getClient(Context context) {
    LocationManager locationManager = (LocationManager) context.getSystemService(
        Context.LOCATION_SERVICE);
    return new GPSFusedLocationProviderClient(locationManager);
  }

  private GPSFusedLocationProviderClient(LocationManager locationManager) {
    this.locationManager = locationManager;
  }

  @NonNull
  @Override
  public Task<Void> flushLocations() {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<Location> getCurrentLocation(int i, @Nullable CancellationToken cancellationToken) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<Location> getCurrentLocation(@NonNull CurrentLocationRequest currentLocationRequest,
      @Nullable CancellationToken cancellationToken) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<Location> getLastLocation() {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<Location> getLastLocation(@NonNull LastLocationRequest lastLocationRequest) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<LocationAvailability> getLocationAvailability() {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<Void> removeLocationUpdates(@NonNull PendingIntent pendingIntent) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<Void> removeLocationUpdates(@NonNull LocationCallback locationCallback) {
    int idx = -1;
    for (int i = 0; i < locationCallbacks.size(); i ++) {
      if (locationCallbacks.get(i) == locationCallback) {
        idx = i;
        break;
      }
    }
    if (idx != -1) {
      synchronized (lock) {
        locationCallbacks.remove(idx);
      }
    }
    return new UnusedTask<>();
  }

  @NonNull
  @Override
  public Task<Void> removeLocationUpdates(@NonNull LocationListener locationListener) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<Void> requestLocationUpdates(@NonNull LocationRequest locationRequest,
      @NonNull PendingIntent pendingIntent) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<Void> requestLocationUpdates(@NonNull LocationRequest locationRequest,
      @NonNull LocationCallback locationCallback, @Nullable Looper looper) {
    synchronized (lock) {
      locationCallbacks.add(locationCallback);
    }
    locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER,
        locationRequest.getMinUpdateIntervalMillis(), locationRequest.getMinUpdateDistanceMeters(),
        this, looper);
    return new UnusedTask<>();
  }

  @NonNull
  @Override
  public Task<Void> requestLocationUpdates(@NonNull LocationRequest locationRequest,
      @NonNull LocationListener locationListener, @Nullable Looper looper) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<Void> requestLocationUpdates(@NonNull LocationRequest locationRequest,
      @NonNull Executor executor, @NonNull LocationCallback locationCallback) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<Void> requestLocationUpdates(@NonNull LocationRequest locationRequest,
      @NonNull Executor executor, @NonNull LocationListener locationListener) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<Void> setMockLocation(@NonNull Location location) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public Task<Void> setMockMode(boolean b) {
    throw new RuntimeException("method not implement");
  }

  @NonNull
  @Override
  public ApiKey<NoOptions> getApiKey() {
    throw new RuntimeException("method not implement");
  }

  @Override
  public void onLocationChanged(@NonNull Location location) {
    List<Location> locations = new ArrayList<>();
    locations.add(location);
    for (LocationCallback callback : locationCallbacks) {
      callback.onLocationResult(LocationResult.create(locations));
    }
  }

  @Override
  public void onLocationChanged(@NonNull List<Location> locations) {
    for (LocationCallback callback : locationCallbacks) {
      callback.onLocationResult(LocationResult.create(locations));
    }
  }
}
