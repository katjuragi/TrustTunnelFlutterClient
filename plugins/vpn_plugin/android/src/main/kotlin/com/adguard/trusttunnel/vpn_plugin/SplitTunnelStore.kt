// plugins/vpn_plugin/android/src/main/kotlin/com/adguard/trusttunnel/vpn_plugin/SplitTunnelStore.kt
package com.adguard.trusttunnel.vpn_plugin

import android.content.Context

/**
 * Persistence for split-tunneling settings.
 *
 * Written from Flutter through the `vpn_plugin_split_tunnel` method channel and
 * read by [SplitTunnelVpnService] when the TUN interface is built.
 */
object SplitTunnelStore {
    const val MODE_ALL_APPS = 0
    const val MODE_ONLY_SELECTED = 1
    const val MODE_ALL_EXCEPT_SELECTED = 2

    private const val PREFS_NAME = "vpn_plugin_split_tunnel"
    private const val KEY_MODE = "mode"
    private const val KEY_PACKAGES = "packages"

    fun mode(ctx: Context): Int =
        sanitizeMode(prefs(ctx).getInt(KEY_MODE, MODE_ALL_APPS))

    fun packages(ctx: Context): Set<String> =
        prefs(ctx).getStringSet(KEY_PACKAGES, emptySet())?.toSet() ?: emptySet()

    fun save(ctx: Context, mode: Int, packages: Set<String>): Boolean =
        prefs(ctx).edit()
            .putInt(KEY_MODE, sanitizeMode(mode))
            .putStringSet(KEY_PACKAGES, packages.toSet())
            .commit()

    private fun sanitizeMode(mode: Int): Int = when (mode) {
        MODE_ALL_APPS, MODE_ONLY_SELECTED, MODE_ALL_EXCEPT_SELECTED -> mode
        else -> MODE_ALL_APPS
    }

    private fun prefs(ctx: Context) =
        ctx.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
