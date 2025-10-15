package com.shrynex.auramusic

import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Request
import org.schabi.newpipe.extractor.downloader.Response
import org.schabi.newpipe.extractor.exceptions.ReCaptchaException
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

class DownloaderImpl private constructor() : Downloader() {
    companion object {
        private var instance: DownloaderImpl? = null
        
        fun getInstance(): DownloaderImpl {
            if (instance == null) {
                instance = DownloaderImpl()
            }
            return instance!!
        }
    }

    override fun execute(request: Request): Response {
        val url = URL(request.url())
        val connection = url.openConnection() as HttpURLConnection
        
        connection.requestMethod = request.httpMethod()
        connection.connectTimeout = 30000
        connection.readTimeout = 30000
        
        request.headers().forEach { (key, values) ->
            values.forEach { value ->
                connection.addRequestProperty(key, value)
            }
        }
        
        request.dataToSend()?.let { data ->
            connection.doOutput = true
            connection.outputStream.use { it.write(data) }
        }
        
        val responseCode = connection.responseCode
        if (responseCode == 429) {
            throw ReCaptchaException("reCaptcha Challenge requested", request.url())
        }
        
        val responseBody = try {
            connection.inputStream.bufferedReader().use { it.readText() }
        } catch (e: IOException) {
            connection.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
        }
        
        val responseHeaders = connection.headerFields
            .filterKeys { it != null }
            .mapKeys { it.key }
            .mapValues { it.value }
        
        return Response(responseCode, null, responseHeaders, responseBody, request.url())
    }
}
