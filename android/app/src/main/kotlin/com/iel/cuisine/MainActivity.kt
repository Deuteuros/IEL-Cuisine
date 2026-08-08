package com.iel.cuisine

import android.os.Bundle
import android.util.Log
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), SessionManagerListener<CastSession> {

    companion object {
        private const val TAG = "CastChannel"
        private const val CHANNEL_NAME = "com.iel.cuisine/cast"
        private const val CAST_NAMESPACE = "urn:x-cast:com.iel.cuisine.cast"
        private const val CATEGORY_CAST = "com.google.android.gms.cast.CATEGORY_CAST"
    }

    private lateinit var channel: MethodChannel
    private var mediaRouter: MediaRouter? = null
    private var routerCallback: MediaRouter.Callback? = null
    private var castSession: CastSession? = null
    private val routesByDeviceId = mutableMapOf<String, MediaRouter.RouteInfo>()
    private var isCasting = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isCastAvailable" -> result.success(isCastAvailable())
                "startDiscovery" -> {
                    startDiscovery()
                    result.success(null)
                }
                "stopDiscovery" -> {
                    stopDiscovery()
                    result.success(null)
                }
                "connect" -> result.success(connect(call.argument("deviceId")))
                "disconnect" -> {
                    disconnect()
                    result.success(null)
                }
                "startCast" -> {
                    startCast()
                    result.success(null)
                }
                "stopCast" -> {
                    stopCast()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        if (isCastAvailable()) {
            try {
                CastContext.getSharedInstance(this).sessionManager
                    .addSessionManagerListener(this, CastSession::class.java)
            } catch (e: Exception) {
                Log.w(TAG, "onResume: ${e.message}")
            }
        }
    }

    override fun onPause() {
        stopDiscovery()
        if (isCastAvailable()) {
            try {
                CastContext.getSharedInstance(this).sessionManager
                    .removeSessionManagerListener(this, CastSession::class.java)
            } catch (e: Exception) {
                Log.w(TAG, "onPause: ${e.message}")
            }
        }
        super.onPause()
    }

    override fun onDestroy() {
        stopDiscovery()
        channel.setMethodCallHandler(null)
        super.onDestroy()
    }

    private fun isCastAvailable(): Boolean {
        return try {
            val availability =
                GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(this)
            availability == ConnectionResult.SUCCESS && CastContext.getSharedInstance(this) != null
        } catch (e: Exception) {
            Log.w(TAG, "isCastAvailable: ${e.message}")
            false
        }
    }

    private fun startDiscovery() {
        if (!isCastAvailable()) return
        try {
            val router = mediaRouter ?: MediaRouter.getInstance(this).also { mediaRouter = it }
            if (routerCallback == null) {
                routerCallback = createRouterCallback()
            }
            val selector = MediaRouteSelector.Builder()
                .addControlCategory(CATEGORY_CAST)
                .build()
            routerCallback?.let { router.addCallback(selector, it, MediaRouter.CALLBACK_FLAG_REQUEST_DISCOVERY) }
            Log.d(TAG, "Découverte Cast démarrée")
        } catch (e: Exception) {
            Log.e(TAG, "startDiscovery: ${e.message}")
        }
    }

    private fun stopDiscovery() {
        try {
            routerCallback?.let { mediaRouter?.removeCallback(it) }
        } catch (e: Exception) {
            Log.w(TAG, "stopDiscovery: ${e.message}")
        }
    }

    private fun createRouterCallback(): MediaRouter.Callback {
        return object : MediaRouter.Callback() {
            override fun onRouteAdded(router: MediaRouter, route: MediaRouter.RouteInfo) {
                if (!route.supportsControlCategory(CATEGORY_CAST)) return
                routesByDeviceId[route.id] = route
                channel.invokeMethod(
                    "onDeviceFound",
                    mapOf(
                        "id" to route.id,
                        "name" to (route.name ?: "Appareil Cast"),
                        "ipAddress" to (route.description ?: ""),
                    ),
                )
                Log.d(TAG, "Appareil Cast découvert: ${route.name}")
            }

            override fun onRouteRemoved(router: MediaRouter, route: MediaRouter.RouteInfo) {
                if (!route.supportsControlCategory(CATEGORY_CAST)) return
                routesByDeviceId.remove(route.id)
                channel.invokeMethod("onDeviceLost", route.id)
                Log.d(TAG, "Appareil Cast retiré: ${route.name}")
            }
        }
    }

    private fun connect(deviceId: String?): Boolean {
        if (!isCastAvailable()) return false
        val route = deviceId?.let { routesByDeviceId[it] } ?: return false
        return try {
            val sessionManager = CastContext.getSharedInstance(this).sessionManager
            sessionManager.endCurrentSession(false)
            mediaRouter?.selectRoute(route)
            true
        } catch (e: Exception) {
            Log.e(TAG, "connect: ${e.message}")
            false
        }
    }

    private fun disconnect() {
        try {
            if (isCastAvailable()) {
                CastContext.getSharedInstance(this).sessionManager.endCurrentSession(true)
            }
        } catch (e: Exception) {
            Log.w(TAG, "disconnect: ${e.message}")
        }
        castSession = null
        isCasting = false
    }

    private fun startCast() {
        val session = currentSession() ?: return
        try {
            session.sendMessage(
                CAST_NAMESPACE,
                """{"action":"START","type":"KDS","timestamp":${System.currentTimeMillis()}}""",
            )
            isCasting = true
            Log.d(TAG, "Cast démarré (message envoyé)")
        } catch (e: Exception) {
            Log.e(TAG, "startCast: ${e.message}")
        }
    }

    private fun stopCast() {
        try {
            currentSession()?.sendMessage(CAST_NAMESPACE, """{"action":"STOP"}""")
        } catch (e: Exception) {
            Log.w(TAG, "stopCast: ${e.message}")
        }
        isCasting = false
    }

    private fun currentSession(): CastSession? {
        return castSession ?: try {
            CastContext.getSharedInstance(this).sessionManager.currentCastSession
        } catch (e: Exception) {
            Log.w(TAG, "currentSession: ${e.message}")
            null
        }
    }

    // SessionManagerListener<CastSession>

    override fun onSessionStarted(session: CastSession, sessionId: String) {
        castSession = session
        try {
            session.setMessageReceivedCallbacks(CAST_NAMESPACE) { _, _, message ->
                Log.d(TAG, "Message Cast reçu: $message")
            }
        } catch (e: Exception) {
            Log.w(TAG, "setMessageReceivedCallbacks: ${e.message}")
        }
        Log.d(TAG, "Session Cast démarrée: $sessionId")
    }

    override fun onSessionEnded(session: CastSession, error: Int) {
        castSession = null
        isCasting = false
        Log.d(TAG, "Session Cast terminée")
    }

    override fun onSessionEnding(session: CastSession) {
        isCasting = false
    }

    override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
        castSession = session
    }

    override fun onSessionResuming(session: CastSession, sessionId: String) {
        // No-op : requise par l'interface SessionManagerListener
    }

    override fun onSessionStarting(session: CastSession) {
        // No-op : requise par l'interface SessionManagerListener
    }

    override fun onSessionStartFailed(session: CastSession, error: Int) {
        castSession = null
        Log.w(TAG, "Démarrage de session Cast échoué: $error")
    }

    override fun onSessionResumeFailed(session: CastSession, error: Int) {
        // No-op : requise par l'interface SessionManagerListener
    }

    override fun onSessionSuspended(session: CastSession, reason: Int) {
        // No-op : requise par l'interface SessionManagerListener
    }
}
