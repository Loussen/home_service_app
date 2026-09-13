package az.homeservice.home_service_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Avoid early zero-size frames from edge-to-edge before Flutter lays out.
        WindowCompat.setDecorFitsSystemWindows(window, true)
        createHighImportanceChannel()
        super.onCreate(savedInstanceState)
    }

    /** FCM default channel is too quiet for heads-up; match Manifest + backend channel_id. */
    private fun createHighImportanceChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "My Sancho bildirişlər",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Yeni iş və mesaj bildirişləri"
            enableVibration(true)
            setShowBadge(true)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager?.createNotificationChannel(channel)
    }

    companion object {
        const val CHANNEL_ID = "mysancho_high"
    }
}
