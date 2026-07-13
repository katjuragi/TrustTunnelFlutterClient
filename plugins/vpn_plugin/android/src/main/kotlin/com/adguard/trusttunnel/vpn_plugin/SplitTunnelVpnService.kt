// plugins/vpn_plugin/android/src/main/kotlin/com/adguard/trusttunnel/vpn_plugin/SplitTunnelVpnService.kt
package com.adguard.trusttunnel.vpn_plugin

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import com.adguard.trusttunnel.CertificateVerificator
import com.adguard.trusttunnel.Logger
import com.adguard.trusttunnel.PersistentRingBuffer
import com.adguard.trusttunnel.VpnClient
import com.adguard.trusttunnel.VpnClientListener
import com.adguard.trusttunnel.VpnConfigStorage
import com.adguard.trusttunnel.VpnServiceConfig
import com.adguard.trusttunnel.VpnState
import com.adguard.trusttunnel.utils.NetworkUtils
import java.io.File
import java.util.concurrent.Executors

/**
 * VPN service driving the TrustTunnel [VpnClient] with per-app split
 * tunneling.
 *
 * The stock `com.adguard.trusttunnel.VpnService` from the AAR builds the TUN
 * interface internally and offers no way to filter applications, so this
 * service replicates its lifecycle (foreground notification, config parsing,
 * TUN construction, network-change notifications) and additionally applies
 * `addAllowedApplication` / `addDisallowedApplication` rules taken from
 * [SplitTunnelStore].
 *
 * State changes and query-log records are forwarded to [VpnCore].
 */
class SplitTunnelVpnService : android.net.VpnService(), VpnClientListener {

    companion object {
        private val LOG = Logger("SplitTunnelVpnService")

        private const val ACTION_START = "Start"
        private const val ACTION_STOP = "Stop"
        private const val PARAM_CONFIG = "Config Extra"
        private const val NOTIFICATION_ID = 1
        private const val NOTIFICATION_CHANNEL = "ConnectionStatus"

        private val IPV4_NON_ROUTABLE = listOf("0.0.0.0/8", "224.0.0.0/3")
        private val ADGUARD_DNS_SERVERS = listOf(
            "46.243.231.30",
            "46.243.231.31",
            "2a10:50c0::2:ff",
            "2a10:50c0::1:ff",
        )
        private val FAKE_DNS_SERVER = listOf("198.18.53.53")

        private val SYNC = Any()

        @Volatile
        private var vpnClient: VpnClient? = null

        private var connectivityManager: ConnectivityManager? = null
        private var networkCallback: NetworkUtils.Companion.NetworkCollector? = null

        private var configStorage: VpnConfigStorage? = null
        private var queryLog: PersistentRingBuffer? = null

        private var currentStartId = -1

        fun start(context: Context, config: String) {
            try {
                if (android.net.VpnService.prepare(context) != null) {
                    LOG.warn("VPN is not prepared, can't start the service")
                    return
                }
                getConfigStorage(context).save(config)
                val intent = getIntent(context, ACTION_START)
                intent.putExtra(PARAM_CONFIG, config)
                context.startForegroundService(intent)
            } catch (e: Exception) {
                LOG.error("Error occurred while service starting", e)
            }
        }

        fun stop(context: Context) {
            try {
                getConfigStorage(context).clear()
                context.startForegroundService(getIntent(context, ACTION_STOP))
            } catch (e: Exception) {
                LOG.error("Error occurred while service stopping", e)
            }
        }

        private fun getIntent(context: Context, action: String): Intent =
            Intent(context, SplitTunnelVpnService::class.java).setAction(action)

        @Synchronized
        private fun getConfigStorage(context: Context): VpnConfigStorage {
            var storage = configStorage
            if (storage == null) {
                storage = VpnConfigStorage(context.applicationContext)
                configStorage = storage
            }
            return storage
        }

        @Synchronized
        private fun getQueryLog(context: Context): PersistentRingBuffer {
            var log = queryLog
            if (log == null) {
                log = PersistentRingBuffer(File(context.applicationContext.filesDir, "query_log.dat"))
                queryLog = log
            }
            return log
        }

        private fun registerNetworkCallback(context: Context) {
            synchronized(SYNC) {
                if (networkCallback != null) return
                val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                val request = NetworkRequest.Builder()
                    .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                    .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
                    .addTransportType(NetworkCapabilities.TRANSPORT_ETHERNET)
                    .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                    .addTransportType(NetworkCapabilities.TRANSPORT_CELLULAR)
                    .addTransportType(NetworkCapabilities.TRANSPORT_BLUETOOTH)
                    .build()
                val callback = NetworkUtils.Companion.NetworkCollector()
                manager.registerNetworkCallback(request, callback)
                connectivityManager = manager
                networkCallback = callback
            }
        }

        private fun startNetworkNotifications(context: Context, client: VpnClient) {
            registerNetworkCallback(context)
            synchronized(SYNC) {
                networkCallback?.startNotifying(client)
            }
        }

        private fun stopNetworkNotifications() {
            synchronized(SYNC) {
                networkCallback?.stopNotifying()
            }
        }
    }

    private enum class State { Started, Stopped }

    private var state = State.Stopped

    private val singleThread = Executors.newSingleThreadScheduledExecutor()

    @Volatile
    private var certificateVerificator: CertificateVerificator? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            LOG.info("Received a null intent, doing nothing")
            stopSelf()
            return START_NOT_STICKY
        }
        val notification = createNotification(applicationContext)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, 1024 /* systemExempted */)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        singleThread.execute {
            try {
                currentStartId = startId
                val action = intent.action
                val config = intent.getStringExtra(PARAM_CONFIG)
                LOG.info("Start executing action=$action startId=$startId")
                when (action) {
                    ACTION_START -> processStarting(config, startId)
                    ACTION_STOP -> close(startId)
                    else -> {
                        // System-triggered start (Always-On VPN)
                        LOG.info("System-triggered start, loading persisted config")
                        processStarting(getConfigStorage(applicationContext).load(), startId)
                    }
                }
            } catch (e: Exception) {
                LOG.error("Error while executing command", e)
            }
        }
        return START_NOT_STICKY
    }

    private fun processStarting(configStr: String?, startId: Int) {
        if (state == State.Started) {
            LOG.info("VPN service has already been started, do nothing")
            return
        }
        if (configStr == null) {
            LOG.error("Failed to get the VPN interface config settings")
            return
        }
        val config = VpnServiceConfig.parseToml(configStr)
        if (config == null) {
            LOG.error("Failed to parse VPN interface config")
            return
        }
        try {
            certificateVerificator = CertificateVerificator()
        } catch (e: Exception) {
            LOG.error("Failed to create certificate verifier: $e")
            close(null)
            return
        }
        LOG.info("VPN is starting...")
        val tunInterface = createTunInterface(config)
        if (tunInterface == null) {
            close(null)
            return
        }

        val service = this
        val proxyListener = object : VpnClientListener by service {
            override fun onStateChanged(state: Int) {
                try {
                    if (VpnState.getByCode(state) == VpnState.DISCONNECTED) {
                        singleThread.execute { closeIfLast(startId) }
                    }
                } catch (e: Exception) {
                    LOG.warn("Failed to process unknown VPN state $state: $e")
                }
                service.onStateChanged(state)
            }
        }

        val client = VpnClient(configStr, proxyListener)
        vpnClient = client
        startNetworkNotifications(applicationContext, client)
        if (!client.start(tunInterface)) {
            LOG.error("Failed to start VPN client")
            close(null)
            return
        }
        state = State.Started
    }

    private fun createTunInterface(config: VpnServiceConfig): ParcelFileDescriptor? {
        LOG.info("Request 'create tun interface' received")
        val tunConfig = config.listener.tun
        return try {
            val builder = Builder()
                .setSession("Trust Tunnel")
                .setMtu(tunConfig.mtuSize.toInt())
                .addAddress("172.20.2.13", 32)
                .addAddress("fdfd:29::2", 64)

            applySplitTunnelRules(builder)

            val dnsServers = if (config.endpoint.dnsUpstreams.isEmpty()) ADGUARD_DNS_SERVERS else FAKE_DNS_SERVER
            dnsServers.forEach { builder.addDnsServer(it) }

            val routes = VpnClient.excludeCidr(
                tunConfig.includedRoutes,
                tunConfig.excludedRoutes + IPV4_NON_ROUTABLE,
            ) ?: throw Exception("Failed to process routes")

            routes.forEach { route ->
                val pair = NetworkUtils.convertCidrToAddressPrefixPair(route)
                    ?: throw Exception("Wrong syntax for included_routes")
                builder.addRoute(pair.first, pair.second)
            }
            builder.establish()
        } catch (e: Exception) {
            LOG.error("Error while building the TUN interface", e)
            null
        }
    }

    /**
     * Applies per-app rules from [SplitTunnelStore].
     *
     * Allowed and disallowed applications cannot be mixed on one builder, so in
     * "only selected" mode the own package is simply filtered out of the list
     * (VPN traffic is protected via [protectSocket] anyway).
     */
    private fun applySplitTunnelRules(builder: Builder) {
        val ctx = applicationContext
        val ownPackage = ctx.packageName
        val mode = SplitTunnelStore.mode(ctx)
        val packages = SplitTunnelStore.packages(ctx)

        when (mode) {
            SplitTunnelStore.MODE_ONLY_SELECTED -> {
                val allowed = packages.filter { it != ownPackage && isPackageInstalled(it) }
                if (allowed.isEmpty()) {
                    LOG.info("Split tunneling: no selected apps installed, tunneling everything")
                    builder.addDisallowedApplication(ownPackage)
                    return
                }
                LOG.info("Split tunneling: VPN only for ${allowed.size} app(s)")
                allowed.forEach { builder.addAllowedApplication(it) }
            }

            SplitTunnelStore.MODE_ALL_EXCEPT_SELECTED -> {
                LOG.info("Split tunneling: VPN for all apps except ${packages.size} selected")
                builder.addDisallowedApplication(ownPackage)
                packages.filter { it != ownPackage && isPackageInstalled(it) }
                    .forEach { builder.addDisallowedApplication(it) }
            }

            else -> builder.addDisallowedApplication(ownPackage)
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean = try {
        packageManager.getApplicationInfo(packageName, 0)
        true
    } catch (_: Exception) {
        false
    }

    override fun onRevoke() {
        singleThread.execute {
            LOG.info("Revoking the VPN service")
            close(null)
        }
    }

    private fun closeIfLast(startId: Int): Boolean {
        if (startId < currentStartId) return false
        return close(startId)
    }

    private fun close(startId: Int?): Boolean {
        if (state != State.Stopped) {
            LOG.info("Closing VPN service")
            stopNetworkNotifications()
            vpnClient?.stop()
            vpnClient?.close()
            vpnClient = null
            state = State.Stopped
            LOG.info("VPN service closed!")
        } else {
            LOG.info("VPN service is not running")
        }
        if (startId != null) stopSelf(startId) else stopSelf()
        return true
    }

    override fun protectSocket(socket: Int): Boolean {
        return if (protect(socket)) {
            LOG.info("The socket $socket has been protected successfully")
            true
        } else {
            LOG.info("Failed to protect socket $socket")
            false
        }
    }

    override fun verifyCertificate(certificate: ByteArray?, rawChain: List<ByteArray?>?): Boolean =
        certificateVerificator?.verifyCertificate(certificate, rawChain) ?: false

    override fun onStateChanged(state: Int) {
        VpnCore.onStateChanged(state)
    }

    override fun onConnectionInfo(info: String) {
        val log = getQueryLog(applicationContext)
        if (!log.append(info)) {
            log.clear()
        }
        VpnCore.onConnectionInfo(info)
    }

    private fun createNotification(context: Context): Notification {
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL,
            "ConnectionStatus",
            NotificationManager.IMPORTANCE_LOW,
        ).apply { description = "VPN connection status" }
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
        return NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
            .setContentTitle("trusttennel")
            .setContentText("VPN is running in foreground")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
}
