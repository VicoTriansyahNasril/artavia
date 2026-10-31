package id.artavia.app

import android.app.UiModeManager
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity is required by local_auth (BiometricPrompt).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // While the app lock is on: hide content in Recents and block
        // screenshots/screen recording (FLAG_SECURE).
        MethodChannel(messenger, "artavia/secure_screen")
            .setMethodCallHandler { call, result ->
                if (call.method == "set") {
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }

        // The app's own theme choice, saved by Android (12+) so the system
        // splash on the next launch is drawn in that theme too.
        MethodChannel(messenger, "artavia/theme")
            .setMethodCallHandler { call, result ->
                if (call.method == "setNightMode") {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val mode = when (call.arguments as? String) {
                            "dark" -> UiModeManager.MODE_NIGHT_YES
                            "light" -> UiModeManager.MODE_NIGHT_NO
                            else -> UiModeManager.MODE_NIGHT_AUTO
                        }
                        getSystemService(UiModeManager::class.java)
                            ?.setApplicationNightMode(mode)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
