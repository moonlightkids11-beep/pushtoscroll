package com.example.earnyourscroll.earn_your_scroll

import android.Manifest
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), MethodChannel.MethodCallHandler {
    private val permissionChannelName = "com.example.earnyourscroll/permissions"
    private val appRestrictionChannelName = "com.example.earnyourscroll/app_restriction"
    private val cameraPermissionCode = 1001
    private var pendingCameraResult: MethodChannel.Result? = null
    private var appChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.getBooleanExtra("show_blocked_screen", false) == true) {
            appChannel?.invokeMethod("showBlockedScreen", null)
            intent.removeExtra("show_blocked_screen")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val permChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, permissionChannelName)
        permChannel.setMethodCallHandler(this)

        appChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appRestrictionChannelName)
        handleIntent(intent)
        
        appChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    try {
                        val apps = getInstalledLaunchableApps()
                        result.success(apps)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to retrieve installed apps: ${e.message}", null)
                    }
                }
                "startEnforcementService" -> {
                    val apps = call.argument<List<String>>("apps") ?: emptyList()
                    val time = call.argument<Int>("time") ?: 0
                    val intent = Intent(this, com.example.earnyourscroll.earn_your_scroll.services.AppBlockerService::class.java).apply {
                        action = com.example.earnyourscroll.earn_your_scroll.services.AppBlockerService.ACTION_START
                        putStringArrayListExtra(com.example.earnyourscroll.earn_your_scroll.services.AppBlockerService.EXTRA_APPS, ArrayList(apps))
                        putExtra(com.example.earnyourscroll.earn_your_scroll.services.AppBlockerService.EXTRA_TIME, time)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "stopEnforcementService" -> {
                    val intent = Intent(this, com.example.earnyourscroll.earn_your_scroll.services.AppBlockerService::class.java).apply {
                        action = com.example.earnyourscroll.earn_your_scroll.services.AppBlockerService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(null)
                }
                "updateEnforcementTime" -> {
                    val time = call.argument<Int>("time") ?: 0
                    val intent = Intent(this, com.example.earnyourscroll.earn_your_scroll.services.AppBlockerService::class.java).apply {
                        action = com.example.earnyourscroll.earn_your_scroll.services.AppBlockerService.ACTION_UPDATE_TIME
                        putExtra(com.example.earnyourscroll.earn_your_scroll.services.AppBlockerService.EXTRA_TIME, time)
                    }
                    startService(intent)
                    result.success(null)
                }
                "updateRestrictedApps" -> {
                    val apps = call.argument<List<String>>("apps") ?: emptyList()
                    val intent = Intent(this, com.example.earnyourscroll.earn_your_scroll.services.AppBlockerService::class.java).apply {
                        action = com.example.earnyourscroll.earn_your_scroll.services.AppBlockerService.ACTION_UPDATE_APPS
                        putStringArrayListExtra(com.example.earnyourscroll.earn_your_scroll.services.AppBlockerService.EXTRA_APPS, ArrayList(apps))
                    }
                    startService(intent)
                    result.success(null)
                }
                "getUncommittedTime" -> {
                    val time = com.example.earnyourscroll.earn_your_scroll.services.AppBlockerService.instance?.getAndResetUncommittedTime() ?: 0
                    result.success(time)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledLaunchableApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(intent, 0)
        }

        val appList = mutableListOf<Map<String, Any?>>()
        val seenPackages = mutableSetOf<String>()

        for (resolveInfo in resolveInfos) {
            val pkgName = resolveInfo.activityInfo.packageName ?: continue
            if (pkgName == packageName) continue // Skip our own app
            if (seenPackages.contains(pkgName)) continue
            seenPackages.add(pkgName)

            val appName = resolveInfo.loadLabel(pm).toString()
            var iconBytes: ByteArray? = null
            try {
                val drawable = resolveInfo.loadIcon(pm)
                val bitmap = drawableToBitmap(drawable)
                if (bitmap != null) {
                    val stream = java.io.ByteArrayOutputStream()
                    bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
                    iconBytes = stream.toByteArray()
                }
            } catch (e: Exception) {
                // Icon conversion failed; proceed without icon
            }

            appList.add(
                mapOf(
                    "packageName" to pkgName,
                    "name" to appName,
                    "icon" to iconBytes
                )
            )
        }

        appList.sortBy { (it["name"] as? String)?.lowercase() ?: "" }
        return appList
    }

    private fun drawableToBitmap(drawable: android.graphics.drawable.Drawable): android.graphics.Bitmap? {
        if (drawable is android.graphics.drawable.BitmapDrawable) {
            return drawable.bitmap
        }
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 72
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 72
        val bitmap = android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkPermission" -> {
                val permission = call.argument<String>("permission")
                val status = checkPermissionStatus(permission)
                result.success(status)
            }
            "requestPermission" -> {
                val permission = call.argument<String>("permission")
                requestPermissionStatus(permission, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun checkPermissionStatus(permission: String?): String {
        return when (permission) {
            "camera" -> {
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                    "granted"
                } else {
                    "denied"
                }
            }
            "usageAccess" -> {
                if (hasUsageStatsPermission()) "granted" else "denied"
            }
            "accessibility" -> {
                if (hasAccessibilityPermission()) "granted" else "denied"
            }
            else -> "denied"
        }
    }

    private fun requestPermissionStatus(permission: String?, result: MethodChannel.Result) {
        when (permission) {
            "camera" -> {
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                    result.success("granted")
                } else {
                    pendingCameraResult = result
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.CAMERA),
                        cameraPermissionCode
                    )
                }
            }
            "usageAccess" -> {
                if (hasUsageStatsPermission()) {
                    result.success("granted")
                } else {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                    } catch (e: Exception) {
                        val fallbackIntent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        startActivity(fallbackIntent)
                    }
                    result.success(if (hasUsageStatsPermission()) "granted" else "denied")
                }
            }
            "accessibility" -> {
                if (hasAccessibilityPermission()) {
                    result.success("granted")
                } else {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(if (hasAccessibilityPermission()) "granted" else "denied")
                }
            }
            else -> result.success("denied")
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun hasAccessibilityPermission(): Boolean {
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.contains(packageName)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == cameraPermissionCode) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingCameraResult?.success(if (granted) "granted" else "denied")
            pendingCameraResult = null
        }
    }
}
