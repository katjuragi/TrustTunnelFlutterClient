// plugins/vpn_plugin/android/src/main/kotlin/com/adguard/trusttunnel/vpn_plugin/VpnTileService.kt
package com.adguard.trusttunnel.vpn_plugin

import android.annotation.TargetApi
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import com.adguard.trusttunnel.Logger

/**
 * Quick Settings tile that toggles the VPN connection.
 *
 * If a connection was made at least once, the last configuration is reused,
 * so the tile can connect without launching the app. When there is no stored
 * configuration or the system VPN consent is missing, the app is opened
 * instead.
 */
@TargetApi(Build.VERSION_CODES.N)
class VpnTileService : TileService() {

    private val log = Logger("VPN_TILE")

    override fun onStartListening() {
        super.onStartListening()
        VpnCore.ensureInitialized(this)
        updateTile()
    }

    override fun onClick() {
        super.onClick()
        if (isLocked) {
            unlockAndRun { toggle() }
        } else {
            toggle()
        }
    }

    private fun toggle() {
        VpnCore.ensureInitialized(this)
        if (VpnCore.currentState == VpnManagerState.DISCONNECTED) {
            startVpn()
        } else {
            log.info("Tile click -> stop VPN")
            VpnCore.stop(applicationContext)
        }
        updateTile()
    }

    private fun startVpn() {
        val ctx = applicationContext
        val config = VpnCore.lastConfig(ctx)
        val prepared = android.net.VpnService.prepare(ctx) == null
        if (config == null || !prepared) {
            log.info("Tile click -> no config or VPN consent, opening app")
            openApp()
            return
        }
        log.info("Tile click -> start VPN with last config")
        VpnCore.start(ctx, config)
    }

    private fun openApp() {
        val launch = packageManager.getLaunchIntentForPackage(packageName) ?: return
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pending = PendingIntent.getActivity(
                this,
                0,
                launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION", "StartActivityAndCollapseDeprecated")
            startActivityAndCollapse(launch)
        }
    }

    private fun updateTile() {
        val tile = qsTile ?: return
        val state = VpnCore.currentState
        tile.state = when (state) {
            VpnManagerState.DISCONNECTED -> Tile.STATE_INACTIVE
            else -> Tile.STATE_ACTIVE
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = when (state) {
                VpnManagerState.CONNECTED -> getString(R.string.vpn_tile_connected)
                VpnManagerState.DISCONNECTED -> getString(R.string.vpn_tile_disconnected)
                else -> getString(R.string.vpn_tile_connecting)
            }
        }
        tile.updateTile()
    }
}
