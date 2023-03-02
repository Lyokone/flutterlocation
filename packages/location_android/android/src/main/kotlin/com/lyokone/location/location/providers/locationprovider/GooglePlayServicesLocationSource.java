package com.lyokone.location.location.providers.locationprovider;

import android.app.Activity;
import android.content.Context;
import android.content.IntentSender.SendIntentException;
import android.location.Location;
import android.os.Looper;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.gms.common.api.ResolvableApiException;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.LocationSettingsRequest;
import com.google.android.gms.location.LocationSettingsResponse;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.lyokone.location.location.constants.RequestCode;

class GooglePlayServicesLocationSource extends LocationCallback {

    private final FusedLocationProviderClient fusedLocationProviderClient;
    private final LocationRequest locationRequest;
    private final SourceListener sourceListener;
    private final Context context;

    interface SourceListener extends OnSuccessListener<LocationSettingsResponse>, OnFailureListener {
        void onSuccess(LocationSettingsResponse locationSettingsResponse);

        void onFailure(@NonNull Exception exception);

        void onLocationResult(@Nullable LocationResult locationResult);

        void onLastKnowLocationTaskReceived(@NonNull Task<Location> task);
    }

    GooglePlayServicesLocationSource(Context context, LocationRequest locationRequest, SourceListener sourceListener) {
        this.sourceListener = sourceListener;
        this.locationRequest = locationRequest;
        this.fusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(context);
        this.context = context;
    }

    void checkLocationSettings() {
        LocationServices.getSettingsClient(context)
                .checkLocationSettings(
                        new LocationSettingsRequest.Builder()
                                .addLocationRequest(locationRequest)
                                .build()
                )
                .addOnSuccessListener(new OnSuccessListener<LocationSettingsResponse>() {
                    @Override
                    public void onSuccess(LocationSettingsResponse locationSettingsResponse) {
                        if (sourceListener != null)
                            sourceListener.onSuccess(locationSettingsResponse);
                    }
                })
                .addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception exception) {
                        if (sourceListener != null) sourceListener.onFailure(exception);
                    }
                });
    }

    void startSettingsApiResolutionForResult(@NonNull ResolvableApiException resolvable, Activity activity) throws SendIntentException {
        resolvable.startResolutionForResult(activity, RequestCode.SETTINGS_API);
    }

    @SuppressWarnings("ResourceType")
    void requestLocationUpdate() {
        // This method is suited for the foreground use cases
        fusedLocationProviderClient.requestLocationUpdates(locationRequest, this, Looper.myLooper());
    }

    @NonNull
    Task<Void> removeLocationUpdates() {
        return fusedLocationProviderClient.removeLocationUpdates(this);
    }

    @SuppressWarnings("ResourceType")
    void requestLastLocation() {
        fusedLocationProviderClient.getLastLocation()
                .addOnCompleteListener(new OnCompleteListener<Location>() {
                    @Override
                    public void onComplete(@NonNull Task<Location> task) {
                        if (sourceListener != null)
                            sourceListener.onLastKnowLocationTaskReceived(task);
                    }
                });
    }

    @Override
    public void onLocationResult(@Nullable LocationResult locationResult) {
        if (sourceListener != null) sourceListener.onLocationResult(locationResult);
    }

}
