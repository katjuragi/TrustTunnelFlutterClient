// plugins/vpn_plugin/android/src/main/kotlin/com/adguard/trusttunnel/vpn_plugin/VpnWidgetProvider.kt
package com.adguard.trusttunnel.vpn_plugin

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.VpnService as AndroidVpnService
import android.widget.RemoteViews
import com.adguard.trusttunnel.Logger

/**
 * Home screen widget with a single VPN on/off toggle.
 *
 * Tapping the button toggles the tunnel through [VpnCore] using the last saved
 * configuration. When the VPN has never been prepared (system consent missing)
 * or no config is stored yet, the app is opened instead.
 *
 * The widget is refreshed whenever the VPN state changes (see
 * [VpnCore.requestWidgetUpdate]).
 */
class VpnWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE = "com.adguard.trusttunnel.vpn_plugin.WIDGET_TOGGLE"

        private val log = Logger("VPN_WIDGET")

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context) ?: return
            val ids = manager.getAppWidgetIds(
                ComponentName(context, VpnWidgetProvider::class.java),
            )
            for (id in ids) {
                render(context, manager, id)
            }
        }

        private fun render(context: Context, manager: AppWidgetManager, widgetId: Int) {
            val state = VpnCore.currentState
            val connected = state != VpnManagerState.DISCONNECTED
            val pending = state != VpnManagerState.DISCONNECTED && state != VpnManagerState.CONNECTED

            val views = RemoteViews(context.packageName, R.layout.vpn_widget)
            views.setTextViewText(R.id.vpn_widget_title, "trusttennel")
            views.setTextViewText(
                R.id.vpn_widget_status,
                when {
                    pending -> "Connecting…"
                    connected -> "Connected"
                    else -> "Disconnected"
                },
            )
            views.setImageViewResource(
                R.id.vpn_widget_button,
                if (connected) R.drawable.ic_widget_power_on else R.drawable.ic_widget_power_off,
            )
            views.setOnClickPendingIntent(R.id.vpn_widget_button, togglePendingIntent(context))
            manager.updateAppWidget(widgetId, views)
        }

        private fun togglePendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, VpnWidgetProvider::class.java).setAction(ACTION_TOGGLE)
            return PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        VpnCore.ensureInitialized(context)
        for (id in appWidgetIds) {
            render(context, appWidgetManager, id)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != ACTION_TOGGLE) return

        VpnCore.ensureInitialized(context)
        val appContext = context.applicationContext
        if (VpnCore.currentState == VpnManagerState.DISCONNECTED) {
            val config = VpnCore.lastConfig(appContext)
            val prepared = AndroidVpnService.prepare(appContext) == null
            if (config == null || !prepared) {
                log.info("Widget toggle -> no config or consent, opening app")
                openApp(appContext)
            } else {
                log.info("Widget toggle -> start VPN")
                VpnCore.start(appContext, config)
            }
        } else {
            log.info("Widget toggle -> stop VPN")
            VpnCore.stop(appContext)
        }
        updateAll(appContext)
    }

    private fun openApp(context: Context) {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(launch)
    }
}
