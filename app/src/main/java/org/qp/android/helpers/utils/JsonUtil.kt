package org.qp.android.helpers.utils

import android.net.Uri
import org.json.JSONArray
import org.json.JSONObject
import org.qp.android.dto.stock.GameData
import java.io.File
import java.io.OutputStream
import java.nio.charset.StandardCharsets

object JsonUtil {

    @JvmStatic
    fun objectToJson(out: OutputStream, o: Any) {
        val jsonStr = objectToJsonString(o)
        out.write(jsonStr.toByteArray(StandardCharsets.UTF_8))
        out.flush()
    }

    @JvmStatic
    fun objectToJson(file: File, o: Any) {
        val jsonStr = objectToJsonString(o)
        file.writeText(jsonStr, StandardCharsets.UTF_8)
    }

    @JvmStatic
    fun objectToJsonString(o: Any): String {
        return when (o) {
            is GameData -> gameDataToJson(o).toString(2)
            is Map<*, *> -> {
                val jsonObj = JSONObject()
                for ((k, v) in o) {
                    if (k != null && v != null) {
                        jsonObj.put(k.toString(), v.toString())
                    }
                }
                jsonObj.toString(2)
            }
            else -> o.toString()
        }
    }

    @JvmStatic
    @Suppress("UNCHECKED_CAST")
    fun <T> jsonToObject(json: String, clazz: Class<T>): T? {
        if (json.isBlank()) return null
        if (clazz == GameData::class.java) {
            return jsonToGameData(JSONObject(json)) as T
        }
        if (Map::class.java.isAssignableFrom(clazz) || HashMap::class.java.isAssignableFrom(clazz)) {
            return jsonToMap(JSONObject(json)) as T
        }
        return null
    }

    @JvmStatic
    fun <T> jsonToObject(file: File, clazz: Class<T>): T? {
        if (!file.exists() || file.length() == 0L) return null
        return jsonToObject(file.readText(StandardCharsets.UTF_8), clazz)
    }

    @JvmStatic
    @Suppress("UNCHECKED_CAST")
    fun <T> jsonToObject(file: File, ignoredRef: Any?): T? {
        if (!file.exists() || file.length() == 0L) return null
        val content = file.readText(StandardCharsets.UTF_8).trim()
        if (content.isEmpty()) return null
        val jsonObj = JSONObject(content)
        return jsonToMap(jsonObj) as T
    }

    private fun gameDataToJson(data: GameData): JSONObject {
        return JSONObject().apply {
            put("id", data.id)
            put("listId", data.listId)
            put("author", data.author ?: "")
            put("portedBy", data.portedBy ?: "")
            put("version", data.version ?: "")
            put("title", data.title ?: "")
            put("lang", data.lang ?: "")
            put("player", data.player ?: "")
            put("iconUrl", data.iconUrl?.toString() ?: "")
            put("fileUrl", data.fileUrl ?: "")
            put("fileSize", data.fileSize)
            put("fileExt", data.fileExt ?: "")
            put("descUrl", data.descUrl ?: "")
            put("pubDate", data.pubDate ?: "")
            put("modDate", data.modDate ?: "")
            put("gameDirUri", data.gameDirUri?.toString() ?: "")
            val filesArr = JSONArray()
            data.gameFilesUri?.forEach { uri ->
                if (uri != null && uri != Uri.EMPTY) filesArr.put(uri.toString())
            }
            put("gameFilesUri", filesArr)
        }
    }

    private fun jsonToGameData(obj: JSONObject): GameData {
        val data = GameData()
        data.id = obj.optLong("id", 0L)
        data.listId = obj.optInt("listId", 1)
        data.author = obj.optString("author", "")
        data.portedBy = obj.optString("portedBy", "")
        data.version = obj.optString("version", "")
        data.title = obj.optString("title", "")
        data.lang = obj.optString("lang", "")
        data.player = obj.optString("player", "")
        val iconStr = obj.optString("iconUrl", "")
        data.iconUrl = if (iconStr.isNotEmpty()) Uri.parse(iconStr) else Uri.EMPTY
        data.fileUrl = obj.optString("fileUrl", "")
        data.fileSize = obj.optLong("fileSize", 0L)
        data.fileExt = obj.optString("fileExt", "")
        data.descUrl = obj.optString("descUrl", "")
        data.pubDate = obj.optString("pubDate", "")
        data.modDate = obj.optString("modDate", "")
        val dirStr = obj.optString("gameDirUri", "")
        data.gameDirUri = if (dirStr.isNotEmpty()) Uri.parse(dirStr) else Uri.EMPTY

        val filesArr = obj.optJSONArray("gameFilesUri")
        if (filesArr != null) {
            val list = mutableListOf<Uri>()
            for (i in 0 until filesArr.length()) {
                val uStr = filesArr.optString(i)
                if (!uStr.isNullOrEmpty()) {
                    list.add(Uri.parse(uStr))
                }
            }
            data.gameFilesUri = list
        }
        return data
    }

    private fun jsonToMap(obj: JSONObject): HashMap<String, String> {
        val map = HashMap<String, String>()
        val keys = obj.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            map[key] = obj.optString(key, "")
        }
        return map
    }
}
