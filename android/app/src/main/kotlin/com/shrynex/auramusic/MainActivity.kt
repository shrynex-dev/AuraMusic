package com.shrynex.auramusic

import android.content.Intent
import android.media.audiofx.AudioEffect
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.search.SearchExtractor
import org.schabi.newpipe.extractor.services.youtube.extractors.YoutubeStreamExtractor
import org.schabi.newpipe.extractor.stream.StreamInfoItem

class MainActivity : AudioServiceActivity() {
    private val EQUALIZER_CHANNEL = "com.auramusic/equalizer"
    private val NEWPIPE_CHANNEL = "com.myapp/newpipe_data_source"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        NewPipe.init(DownloaderImpl.getInstance())
        
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
                    val query = call.argument<String>("query") ?: ""
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val searchResults = performSearch(query)
                            withContext(Dispatchers.Main) {
                                result.success(searchResults)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("SEARCH_ERROR", e.message, null)
                            }
                        }
                    }
                }
                "getStreamUrl" -> {
                    val videoId = call.argument<String>("id") ?: ""
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val streamUrl = getStreamUrl(videoId)
                            withContext(Dispatchers.Main) {
                                result.success(streamUrl)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("STREAM_ERROR", e.message, null)
                            }
                        }
                    }
                }
                "getChannelVideos" -> {
                    val channelUrl = call.argument<String>("channelUrl") ?: ""
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val videos = getChannelVideos(channelUrl)
                            withContext(Dispatchers.Main) {
                                result.success(videos)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("CHANNEL_ERROR", e.message, null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun performSearch(query: String): List<Map<String, String>> {
        val extractor = ServiceList.YouTube.getSearchExtractor(query)
        extractor.fetchPage()
        
        return extractor.initialPage.items
            .filterIsInstance<StreamInfoItem>()
            .take(20)
            .map { item ->
                mapOf(
                    "id" to item.url.substringAfter("watch?v="),
                    "title" to item.name,
                    "artist" to item.uploaderName,
                    "album" to "",
                    "thumbnailUrl" to item.thumbnails.firstOrNull()?.url.orEmpty()
                )
            }
    }
    
    private fun getChannelVideos(channelUrl: String): Map<String, Any> {
        try {
            val artistName = channelUrl.substringAfterLast("/")
            val extractor = ServiceList.YouTube.getSearchExtractor(artistName)
            extractor.fetchPage()
            
            val allItems = extractor.initialPage.items
            val videos = allItems
                .filterIsInstance<StreamInfoItem>()
                .filter { it.uploaderName.equals(artistName, ignoreCase = true) }
                .take(50)
                .map { item ->
                    mapOf(
                        "id" to item.url.substringAfter("watch?v="),
                        "title" to item.name,
                        "artist" to item.uploaderName,
                        "album" to "",
                        "thumbnailUrl" to item.thumbnails.firstOrNull()?.url.orEmpty(),
                        "views" to "0"
                    )
                }
            
            return mapOf(
                "name" to artistName,
                "subscriberCount" to "0",
                "avatarUrl" to "",
                "videos" to videos
            )
        } catch (e: Exception) {
            android.util.Log.e("NewPipe", "Channel extraction error: ${e.message}", e)
            throw e
        }
    }
    
    private fun getStreamUrl(videoId: String): String {
        val url = "https://www.youtube.com/watch?v=$videoId"
        android.util.Log.d("NewPipe", "Getting stream for: $url")
        
        try {
            val extractor = ServiceList.YouTube.getStreamExtractor(url)
            extractor.fetchPage()
            
            val audioStreams = extractor.audioStreams
            android.util.Log.d("NewPipe", "Audio streams count: ${audioStreams.size}")
            
            if (audioStreams.isEmpty()) {
                val videoStreams = extractor.videoStreams
                android.util.Log.d("NewPipe", "Video streams count: ${videoStreams.size}")
                throw Exception("Could not get audio streams")
            }
            
            val bestStream = audioStreams.maxByOrNull { it.averageBitrate ?: 0 }
            val streamUrl = bestStream?.url ?: bestStream?.content
            android.util.Log.d("NewPipe", "Stream URL: $streamUrl")
            
            return streamUrl ?: throw Exception("No stream URL available")
        } catch (e: Exception) {
            android.util.Log.e("NewPipe", "Error getting stream: ${e.message}", e)
            throw e
        }
    }
}