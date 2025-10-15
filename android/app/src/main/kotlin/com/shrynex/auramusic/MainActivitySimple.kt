package com.shrynex.auramusic

import android.content.Intent
import android.media.audiofx.AudioEffect
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivitySimple : FlutterActivity() {
    private val EQUALIZER_CHANNEL = "com.auramusic/equalizer"
    private val NEWPIPE_CHANNEL = "com.myapp/newpipe_data_source"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EQUALIZER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openEqualizer") {
                try {
                    val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL)
                    intent.putExtra(AudioEffect.EXTRA_PACKAGE_NAME, packageName)
                    intent.putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
                    
                    val audioSessionId = call.argument<Int>("audioSessionId")
                    if (audioSessionId != null) {
                        intent.putExtra(AudioEffect.EXTRA_AUDIO_SESSION, audioSessionId)
                    }
                    
                    if (intent.resolveActivity(packageManager) != null) {
                        startActivityForResult(intent, 0)
                        result.success(true)
                    } else {
                        result.error("NO_EQUALIZER", "No equalizer found", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NEWPIPE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "search" -> {
                    result.success(listOf(
                        mapOf(
                            "id" to "test123",
                            "title" to "Test Song",
                            "artist" to "Test Artist",
                            "album" to "",
                            "thumbnailUrl" to ""
                        )
                    ))
                }
                "getStreamUrl" -> {
                    result.success("https://example.com/test.mp3")
                }
                else -> result.notImplemented()
            }
        }
    }
}
