package org.qp.android.helpers.utils

import org.qp.android.dto.stock.RemoteDataList
import org.qp.android.dto.stock.RemoteGameData
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory
import java.io.File
import java.io.InputStream

object XmlUtil {

    @JvmStatic
    fun <T> xmlToObject(file: File, clazz: Class<T>): T? {
        if (!file.exists() || file.length() == 0L) return null
        return file.inputStream().use { stream ->
            parseXml(stream, clazz)
        }
    }

    @JvmStatic
    fun <T> xmlToObject(xml: String, clazz: Class<T>): T? {
        if (xml.isBlank()) return null
        return xml.byteInputStream().use { stream ->
            parseXml(stream, clazz)
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun <T> parseXml(stream: InputStream, clazz: Class<T>): T? {
        if (clazz != RemoteDataList::class.java) return null

        val factory = XmlPullParserFactory.newInstance()
        factory.isNamespaceAware = false
        val parser = factory.newPullParser()
        parser.setInput(stream, "UTF-8")

        val dataList = RemoteDataList()
        var currentGame: RemoteGameData? = null
        var currentTag = ""

        var eventType = parser.eventType
        while (eventType != XmlPullParser.END_DOCUMENT) {
            when (eventType) {
                XmlPullParser.START_TAG -> {
                    currentTag = parser.name ?: ""
                    if (currentTag.equals("game", ignoreCase = true)) {
                        currentGame = RemoteGameData()
                    }
                }
                XmlPullParser.TEXT -> {
                    val text = parser.text?.trim() ?: ""
                    if (text.isNotEmpty()) {
                        val game = currentGame
                        if (game != null) {
                            when (currentTag.lowercase()) {
                                "id" -> game.id = text.toLongOrNull() ?: 0L
                                "list_id" -> game.listId = text.toIntOrNull() ?: 0
                                "author" -> game.author = text
                                "ported_by" -> game.portedBy = text
                                "version" -> game.version = text
                                "title" -> game.title = text
                                "lang" -> game.lang = text
                                "player" -> game.player = text
                                "icon" -> game.icon = text
                                "image" -> game.image = text
                                "file_url" -> game.fileUrl = text
                                "file_size" -> game.fileSize = text.toLongOrNull() ?: 0L
                                "file_ext" -> game.fileExt = text
                                "desc_url" -> game.descUrl = text
                                "pub_date" -> game.pubDate = text
                                "mod_date" -> game.modDate = text
                            }
                        } else {
                            when (currentTag.lowercase()) {
                                "version" -> dataList.version = text
                                "id" -> dataList.id = text
                                "title" -> dataList.title = text
                                "text" -> dataList.text = text
                            }
                        }
                    }
                }
                XmlPullParser.END_TAG -> {
                    val tagName = parser.name ?: ""
                    if (tagName.equals("game", ignoreCase = true) && currentGame != null) {
                        dataList.game.add(currentGame)
                        currentGame = null
                    }
                    currentTag = ""
                }
            }
            eventType = parser.next()
        }

        return dataList as T
    }
}
