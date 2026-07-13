// plugins/vpn_plugin/android/src/main/kotlin/com/adguard/trusttunnel/vpn_plugin/VpnPlugin.kt
package com.adguard.trusttunnel.vpn_plugin

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.VpnService as AndroidVpnService
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class VpnPlugin :
    FlutterPlugin,
    ActivityAware,
    PluginRegistry.ActivityResultListener,
    IVpnManager {

    companion object {
        private const val REQ_VPN_PREPARE = 1001
        private const val STATE_CHANNEL_NAME = "vpn_plugin_event_channel"
        private const val QUERY_LOG_CHANNEL_NAME = "vpn_plugin_event_channel_query_log"
        private const val SPLIT_TUNNEL_CHANNEL_NAME = "vpn_plugin_split_tunnel"
    }

    private lateinit var appContext: Context
    private var activity: Activity? = null

    private var stateChannel: EventChannel? = null
    private var queryLogChannel: EventChannel? = null
    private var splitTunnelChannel: MethodChannel? = null

    private val backgroundExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private lateinit var vpnImpl: NativeVpnImpl

    private lateinit var deepLinkImpl: DeepLinkImpl

    private var pendingConfig: String? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        val messenger: BinaryMessenger = binding.binaryMessenger

        vpnImpl = NativeVpnImpl(appContext)

        IVpnManager.setUp(messenger, this)

        deepLinkImpl = DeepLinkImpl()

        IDeepLink.setUp(messenger, deepLinkImpl)

        stateChannel = EventChannel(messenger, STATE_CHANNEL_NAME).apply {
            setStreamHandler(vpnImpl)
        }

        queryLogChannel = EventChannel(messenger, QUERY_LOG_CHANNEL_NAME).apply {
            setStreamHandler(vpnImpl.queryLogHandler)
        }

        splitTunnelChannel = MethodChannel(messenger, SPLIT_TUNNEL_CHANNEL_NAME).apply {
            setMethodCallHandler(::onSplitTunnelMethodCall)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stateChannel?.setStreamHandler(null)
        queryLogChannel?.setStreamHandler(null)
        splitTunnelChannel?.setMethodCallHandler(null)
        stateChannel = null
        queryLogChannel = null
        splitTunnelChannel = null
    }

    private fun onSplitTunnelMethodCall(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "getInstalledApps" -> backgroundExecutor.execute {
                try {
                    val apps = loadInstalledApps()
                    mainHandler.post { result.success(apps) }
                } catch (t: Throwable) {
                    mainHandler.post { result.error("apps_error", t.message, null) }
                }
            }

            "getSettings" -> result.success(
                mapOf(
                    "mode" to SplitTunnelStore.mode(appContext),
                    "packages" to SplitTunnelStore.packages(appContext).toList(),
                ),
            )

            "setSettings" -> {
                val mode = call.argument<Int>("mode") ?: SplitTunnelStore.MODE_ALL_APPS
                val packages = call.argument<List<String>>("packages") ?: emptyList()
                SplitTunnelStore.save(appContext, mode, packages.toSet())
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    /// Returns launchable applications: name, package and a small PNG icon.
    private fun loadInstalledApps(): List<Map<String, Any>> {
        val pm = appContext.packageManager
        val ownPackage = appContext.packageName

        return pm.getInstalledApplications(0)
            .asSequence()
            .filter { it.packageName != ownPackage }
            .filter { pm.getLaunchIntentForPackage(it.packageName) != null }
            .map { info ->
                mapOf(
                    "name" to (pm.getApplicationLabel(info)?.toString() ?: info.packageName),
                    "package" to info.packageName,
                    "system" to (info.flags and ApplicationInfo.FLAG_SYSTEM != 0),
                    "icon" to renderIcon(info),
                )
            }
            .sortedBy { (it["name"] as String).lowercase() }
            .toList()
    }

    private fun renderIcon(info: ApplicationInfo): ByteArray {
        val pm = appContext.packageManager
        return try {
            val drawable = pm.getApplicationIcon(info)
            val size = 96
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(canvas)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
            bitmap.recycle()
            stream.toByteArray()
        } catch (_: Throwable) {
            ByteArray(0)
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQ_VPN_PREPARE) {
            val cfg = pendingConfig
            pendingConfig = null
            if (cfg != null && resultCode == Activity.RESULT_OK) {
                val ctx = activity ?: appContext
                vpnImpl.startPrepared(ctx, cfg)
            }
            return true
        }
        return false
    }

    override fun start(config: String) {
        val act = activity
        if (act != null) {
            val prepare = AndroidVpnService.prepare(act)
            if (prepare == null) {
                vpnImpl.startPrepared(act, config)
            } else {
                pendingConfig = config
                act.startActivityForResult(prepare, REQ_VPN_PREPARE)
            }
        } else {
            val prepare = AndroidVpnService.prepare(appContext)
            if (prepare == null) {
                vpnImpl.startPrepared(appContext, config)
            }
        }
    }

    override fun stop() {
        vpnImpl.stop()
    }

    override fun updateConfiguration(config: String?) {
        // Do nothing, this is iOS specific
    }

    override fun getCurrentState(): VpnManagerState {
        return vpnImpl.getCurrentState()
    }

    override fun exportLogs(): List<String> {
        return vpnImpl.exportLogs()
    }

    override fun clearLogs() {
        vpnImpl.clearLogs()
    }
}
