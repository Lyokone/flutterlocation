package com.lyokone.location

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

const val kDefaultChannelName: String = "Location background service"
const val kDefaultNotificationTitle: String = "Location background service running"
const val kDefaultNotificationIconName: String = "navigation_empty_icon"

data class NotificationOptions(
    val channelName: String = kDefaultChannelName,
    val title: String = kDefaultNotificationTitle,
    val iconName: String = kDefaultNotificationIconName,
    val subtitle: String? = null,
    val description: String? = null,
    val color: Int? = null,
    val onTapBringToFront: Boolean = false
)

class BackgroundNotification(
    private val context: Context,
    private val channelId: String,
    private val notificationId: Int
) {
    private var options: NotificationOptions = NotificationOptions()
    private var builder: NotificationCompat.Builder = NotificationCompat.Builder(context, channelId)
        .setPriority(NotificationCompat.PRIORITY_HIGH)

    init {
        updateNotification(options, false)
    }

    private fun getDrawableId(iconName: String): Int {
        return context.resources.getIdentifier(iconName, "drawable", context.packageName)
    }

    private fun buildBringToFrontIntent(): PendingIntent? {
        val intent: Intent? = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.setPackage(null)
            ?.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)

        return if (intent != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_MUTABLE)
        } else if (intent != null) {
            PendingIntent.getActivity(context, 0, intent, 0)
        } else {
            null
        }
    }

    private fun updateChannel(channelName: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = NotificationManagerCompat.from(context)
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_NONE
            ).apply {
                lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun updateNotification(
        options: NotificationOptions,
        notify: Boolean
    ) {
        val iconId = getDrawableId(options.iconName).let {
            if (it != 0) it else getDrawableId(kDefaultNotificationIconName)
        }
        builder = builder
            .setContentTitle(options.title)
            .setSmallIcon(iconId)
            .setContentText(options.subtitle)
            .setSubText(options.description)

        builder = if (options.color != null) {
            builder.setColor(options.color).setColorized(true)
        } else {
            builder.setColor(0).setColorized(false)
        }

        builder = if (options.onTapBringToFront) {
            builder.setContentIntent(buildBringToFrontIntent())
        } else {
            builder.setContentIntent(null)
        }

        if (notify) {
            val notificationManager = NotificationManagerCompat.from(context)
            notificationManager.notify(notificationId, builder.build())
        }
    }

    fun updateOptions(options: NotificationOptions, isVisible: Boolean) {
        if (options.channelName != this.options.channelName) {
            updateChannel(options.channelName)
        }

        updateNotification(options, isVisible)

        this.options = options
    }

    fun build(): Notification {
        updateChannel(options.channelName)
        return builder.build()
    }
}
