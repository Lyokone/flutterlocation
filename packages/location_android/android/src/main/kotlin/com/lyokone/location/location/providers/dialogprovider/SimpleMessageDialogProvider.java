package com.lyokone.location.location.providers.dialogprovider;

import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;

import com.lyokone.location.location.providers.dialogprovider.DialogProvider;

public class SimpleMessageDialogProvider extends DialogProvider implements DialogInterface.OnClickListener {

    private String message;

    public SimpleMessageDialogProvider(String message) {
        this.message = message;
    }

    public String message() {
        return message;
    }

    @Override
    public Dialog getDialog(@NonNull Context context) {
        return new AlertDialog.Builder(context)
              .setMessage(message)
              .setCancelable(false)
              .setPositiveButton(android.R.string.ok, this)
              .setNegativeButton(android.R.string.cancel, this)
              .create();
    }

    @Override
    public void onClick(DialogInterface dialog, int which) {
        switch (which) {
            case DialogInterface.BUTTON_POSITIVE: {
                if (getDialogListener() != null) getDialogListener().onPositiveButtonClick();
                break;
            }
            case DialogInterface.BUTTON_NEGATIVE: {
                if (getDialogListener() != null) getDialogListener().onNegativeButtonClick();
                break;
            }
        }
    }
}
