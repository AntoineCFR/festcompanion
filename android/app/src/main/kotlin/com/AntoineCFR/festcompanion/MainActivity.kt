package com.AntoineCFR.festcompanion

import android.app.NotificationChannel
import android.app.NotificationManager
import android.graphics.Color
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        createNotificationChannels()
    }

    /**
     * Crée les canaux de notification Android (requis pour Android 8+ / API 26+).
     * Les canaux doivent exister avant qu'une notification puisse être affichée.
     * FCM utilise le channel_id spécifié dans le payload pour choisir le canal.
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager =
                getSystemService(NotificationManager::class.java) ?: return

            // ── Canal SOS ────────────────────────────────────────────────────────
            // Priorité maximale, vibration longue répétée, lumière rouge.
            // channel_id = "sos_channel" (doit correspondre au payload FCM backend).
            val sosVibrationPattern = longArrayOf(0, 1000, 300, 1000, 300, 1000, 300, 1000)
            val sosChannel = NotificationChannel(
                "sos_channel",
                "SOS & Urgences",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alertes SOS — vibration longue pour attirer l'attention"
                enableVibration(true)
                vibrationPattern = sosVibrationPattern
                enableLights(true)
                lightColor = Color.RED
            }

            // ── Canal Festival ────────────────────────────────────────────────────
            // Pour les événements "perdu" et "hype".
            // channel_id = "festival_channel".
            val festivalChannel = NotificationChannel(
                "festival_channel",
                "Événements Festival",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications pour les événements du festival (perdu, hype…)"
                enableVibration(true)
            }

            notificationManager.createNotificationChannels(
                listOf(sosChannel, festivalChannel)
            )
        }
    }
}
