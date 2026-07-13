// plugins/vpn_plugin/android/src/main/kotlin/com/adguard/trusttunnel/vpn_plugin/VpnCore.kt
package com.adguard.trusttunnel.vpn_plugin

import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.service.quicksettings.TileService
import com.adguard.trusttunnel.AppNotifier
import com.adguard.trusttunnel.Logger
import com.adguard.trusttunnel.VpnService
import java.io.File
import java.util.concurrent.CopyOnWriteArrayList

/**
 * Process-wide holder of the native VPN engine.
 *
 * Both the Flutter plugin ([NativeVpnImpl]) and the Quick Settings tile
 * ([VpnTileService]) go through this object, so the engine is initialized
 * exactly once per process and state updates reach every consumer even when
 * the Flutter engine is not running.
 *
 * The last successfully requested configuration is persisted, which allows
 * the Quick Settings tile to reconnect without launching the app.
 */
object VpnCore : AppNotifier {
    private const val PREFS_NAME = "vpn_plugin_core"
    private const val KEY_LAST_CONFIG = "last_config"
    private const val KEY_ACTIVE_SERVICE = "active_service"
    private const val SERVICE_STOCK = "stock"
    private const val SERVICE_SPLIT = "split"

    private val log = Logger("VPN_CORE")
    private val listeners = CopyOnWriteArrayList<AppNotifier>()

    @Volatile
    var currentState: VpnManagerState = VpnManagerState.DISCONNECTED
        private set

    private var initialized = false
    private lateinit var appContext: Context

    @Synchronized
    fun ensureInitialized(context: Context) {
        if (initialized) return
        appContext = context.applicationContext
        VpnService.initialize(appContext)
        val queryLogFile = File(appContext.filesDir, "query_log.dat")
        VpnService.setAppNotifier(queryLogFile, this)
        initialized = true
    }

    fun addListener(listener: AppNotifier) {
        listeners.add(listener)
    }

    fun removeListener(listener: AppNotifier) {
        listeners.remove(listener)
    }

    fun start(ctx: Context, config: String) {
        saveLastConfig(ctx, config)
        val mode = SplitTunnelStore.mode(ctx)
        if (mode == SplitTunnelStore.MODE_ALL_APPS) {
            // Default: use the stock, well-tested engine service.
            log.info("start() -> stock VpnService (all apps)")
            prefs(ctx).edit().putString(KEY_ACTIVE_SERVICE, SERVICE_STOCK).apply()
            VpnService.start(ctx, config)
        } else {
            // Split tunneling enabled: use the per-app capable service.
            log.info("start() -> SplitTunnelVpnService (mode=$mode)")
            prefs(ctx).edit().putString(KEY_ACTIVE_SERVICE, SERVICE_SPLIT).apply()
            SplitTunnelVpnService.start(ctx, config)
        }
    }

    fun stop(ctx: Context) {
        // Stop the service that was actually started to avoid a transient
        // foreground-service flash from the inactive one.
        when (prefs(ctx).getString(KEY_ACTIVE_SERVICE, null)) {
            SERVICE_SPLIT -> SplitTunnelVpnService.stop(ctx)
            SERVICE_STOCK -> VpnService.stop(ctx)
            else -> {
                VpnService.stop(ctx)
                SplitTunnelVpnService.stop(ctx)
            }
        }
    }

    fun lastConfig(ctx: Context): String? = prefs(ctx).getString(KEY_LAST_CONFIG, null)

    override fun onStateChanged(state: Int) {
        currentState = VpnManagerState.entries.getOrElse(state) { VpnManagerState.DISCONNECTED }
        for (listener in listeners) {
            listener.onStateChanged(state)
        }
        requestTileUpdate(appContext)
        VpnWidgetProvider.updateAll(appContext)
    }

    override fun onConnectionInfo(info: String) {
        for (listener in listeners) {
            listener.onConnectionInfo(info)
        }
    }

    fun requestTileUpdate(ctx: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
        try {
            TileService.requestListeningState(
                ctx.applicationContext,
                ComponentName(ctx.applicationContext, VpnTileService::class.java),
            )
        } catch (t: Throwable) {
            log.warn("requestListeningState failed", t)
        }
    }

    private fun saveLastConfig(ctx: Context, config: String) {
        prefs(ctx).edit().putString(KEY_LAST_CONFIG, config).apply()
    }

    private fun prefs(ctx: Context) =
        ctx.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
