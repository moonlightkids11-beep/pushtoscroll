package com.example.earnyourscroll.earn_your_scroll.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.earnyourscroll.earn_your_scroll.MainActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

class AppBlockerService : Service() {
    private val scope = CoroutineScope(Dispatchers.Default + Job())
    private var job: Job? = null
    
    private var restrictedApps: List<String> = emptyList()
    private var remainingTimeSeconds: Int = 0
    private var uncommittedConsumedSeconds: Int = 0
    private var hasShownBlockedScreen: Boolean = false
    private val statePrefs by lazy { getSharedPreferences("app_blocker_state", MODE_PRIVATE) }

    companion object {
        private const val TAG = "AppBlockerService"
        const val CHANNEL_ID = "AppBlockerChannel"
        const val NOTIFICATION_ID = 1

        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        const val ACTION_UPDATE_TIME = "ACTION_UPDATE_TIME"
        const val ACTION_UPDATE_APPS = "ACTION_UPDATE_APPS"

        const val EXTRA_APPS = "EXTRA_APPS"
        const val EXTRA_TIME = "EXTRA_TIME"

        // Expose state to MainActivity to easily pull uncommitted time
        var instance: AppBlockerService? = null
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (intent == null || action == null) {
            restoreState()
            if (restrictedApps.isNotEmpty) {
                startForeground(NOTIFICATION_ID, buildNotification())
                startPolling()
            }
            return START_STICKY
        }

        when (action) {
            ACTION_START -> {
                val apps = intent.getStringArrayListExtra(EXTRA_APPS) ?: emptyList<String>()
                val time = intent.getIntExtra(EXTRA_TIME, 0)
                
                restrictedApps = apps
                remainingTimeSeconds = time
                if (remainingTimeSeconds > 0) hasShownBlockedScreen = false
                persistState()
                
                startForeground(NOTIFICATION_ID, buildNotification())
                startPolling()
            }
            ACTION_UPDATE_TIME -> {
                remainingTimeSeconds = intent.getIntExtra(EXTRA_TIME, remainingTimeSeconds)
                if (remainingTimeSeconds > 0) hasShownBlockedScreen = false
                persistState()
            }
            ACTION_UPDATE_APPS -> {
                val apps = intent.getStringArrayListExtra(EXTRA_APPS) ?: emptyList<String>()
                restrictedApps = apps
                persistState()
            }
            ACTION_STOP -> {
                stopPolling()
                statePrefs.edit().clear().apply()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun persistState() {
        statePrefs.edit()
            .putStringSet("restricted_apps", restrictedApps.toSet())
            .putInt("remaining_time", remainingTimeSeconds)
            .putInt("uncommitted", uncommittedConsumedSeconds)
            .apply()
    }

    private fun restoreState() {
        restrictedApps = statePrefs.getStringSet("restricted_apps", emptySet())?.toList() ?: emptyList()
        remainingTimeSeconds = statePrefs.getInt("remaining_time", 0)
        uncommittedConsumedSeconds = statePrefs.getInt("uncommitted", 0)
    }

    fun getAndResetUncommittedTime(): Int {
        val time = uncommittedConsumedSeconds
        uncommittedConsumedSeconds = 0
        persistState()
        return time
    }

    private fun startPolling() {
        if (job?.isActive == true) return
        job = scope.launch {
            var lastCheckTime = System.currentTimeMillis()
            var lastForegroundApp: String? = null

            while (isActive) {
                delay(1000) // Poll every 1 second
                
                val currentTime = System.currentTimeMillis()
                val elapsedSeconds = ((currentTime - lastCheckTime) / 1000.0).toInt()
                lastCheckTime = currentTime

                val topApp = getTopApp()
                
                if (topApp != null) {
                    if (topApp != lastForegroundApp) {
                        Log.d(TAG, "Foreground app changed to: $topApp")
                        lastForegroundApp = topApp
                    }

                    if (restrictedApps.contains(topApp)) {
                        // We are in a restricted app
                        if (remainingTimeSeconds > 0) {
                            val consume = elapsedSeconds.coerceAtLeast(1)
                            remainingTimeSeconds -= consume
                            uncommittedConsumedSeconds += consume
                            persistState()
                            Log.d(TAG, "Consumed $consume seconds in $topApp. Remaining: $remainingTimeSeconds")
                        }

                        if (remainingTimeSeconds <= 0 && !hasShownBlockedScreen) {
                            Log.d(TAG, "Time is up! Blocking $topApp")
                            hasShownBlockedScreen = true
                            showBlockedScreen()
                        }
                    } else {
                        // A future visit to a restricted app may need a new
                        // intervention, but do not relaunch the activity while
                        // the same blocked app remains foregrounded.
                        hasShownBlockedScreen = false
                    }
                }
            }
        }
    }

    private fun showBlockedScreen() {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("show_blocked_screen", true)
        }
        startActivity(intent)
    }

    private fun getTopApp(): String? {
        return try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val beginTime = endTime - 1000 * 60 // Look back 60 seconds

            val events = usageStatsManager.queryEvents(beginTime, endTime)
            var topPackageName: String? = null
            val event = UsageEvents.Event()

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                    topPackageName = event.packageName
                } else if (event.eventType == UsageEvents.Event.ACTIVITY_PAUSED) {
                    if (topPackageName == event.packageName) {
                        topPackageName = null
                    }
                }
            }
            topPackageName
        } catch (e: SecurityException) {
            Log.w(TAG, "Usage access permission missing", e)
            null
        } catch (e: Exception) {
            Log.w(TAG, "Failed to read foreground app", e)
            null
        }
    }

    private fun stopPolling() {
        job?.cancel()
        job = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "App Blocker Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }

    private fun buildNotification(): android.app.Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Earn Your Scroll")
            .setContentText("Enforcing restricted apps...")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        stopPolling()
    }
}
