package io.fynza.app.autocapture

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

object AutoCaptureQueue {
    private const val QUEUE_FILENAME = "autocapture_queue.json"
    private const val STAGING_FILENAME = "autocapture_staging.json"
    private const val MAX_ENTRIES = 500
    private val lock = Any()

    fun enqueue(
        context: Context,
        key: String,
        packageName: String,
        title: String,
        text: String,
        postTime: Long
    ) {
        synchronized(lock) {
            try {
                val file = File(context.filesDir, QUEUE_FILENAME)
                val jsonArray = if (file.exists()) {
                    try {
                        JSONArray(file.readText())
                    } catch (e: Exception) {
                        JSONArray()
                    }
                } else {
                    JSONArray()
                }

                val item = JSONObject().apply {
                    put("key", key)
                    put("packageName", packageName)
                    put("title", title)
                    put("text", text)
                    put("postTime", postTime)
                }

                jsonArray.put(item)

                // Enforce bounded max entries (drop oldest)
                val trimmedArray = if (jsonArray.length() > MAX_ENTRIES) {
                    val result = JSONArray()
                    val startIndex = jsonArray.length() - MAX_ENTRIES
                    for (i in startIndex until jsonArray.length()) {
                        result.put(jsonArray.get(i))
                    }
                    result
                } else {
                    jsonArray
                }

                file.writeText(trimmedArray.toString())
            } catch (e: Exception) {
                // Never crash service
            }
        }
    }

    fun drain(context: Context): List<Map<String, Any>> {
        synchronized(lock) {
            val queueFile = File(context.filesDir, QUEUE_FILENAME)
            val stagingFile = File(context.filesDir, STAGING_FILENAME)

            if (!queueFile.exists() || queueFile.length() == 0L) {
                return emptyList()
            }

            // Atomic rename to staging file
            if (!queueFile.renameTo(stagingFile)) {
                // If rename fails, try manual copy and clear
                try {
                    stagingFile.writeBytes(queueFile.readBytes())
                    queueFile.delete()
                } catch (e: Exception) {
                    return emptyList()
                }
            }

            val list = mutableListOf<Map<String, Any>>()
            try {
                if (stagingFile.exists()) {
                    val content = stagingFile.readText()
                    val jsonArray = JSONArray(content)
                    for (i in 0 until jsonArray.length()) {
                        val obj = jsonArray.getJSONObject(i)
                        val map = mutableMapOf<String, Any>(
                            "key" to obj.optString("key", ""),
                            "packageName" to obj.optString("packageName", ""),
                            "title" to obj.optString("title", ""),
                            "text" to obj.optString("text", ""),
                            "postTime" to obj.optLong("postTime", System.currentTimeMillis())
                        )
                        list.add(map)
                    }
                    stagingFile.delete()
                }
            } catch (e: Exception) {
                stagingFile.delete()
            }

            return list
        }
    }
}

