package org.qp.desktop.model

import kotlinx.serialization.Serializable

@Serializable
data class DesktopGameItem(
    val id: String,
    val title: String,
    val author: String = "",
    val version: String = "1.0.0",
    val description: String = "",
    val iconPath: String? = null,
    val gameFilePath: String,
    val folderPath: String = "",
    val fileSizeBytes: Long = 0,
    val lastPlayedTime: Long = 0
)

@Serializable
data class DesktopAppSettings(
    val themeMode: String = "dark",       // "dark", "light", "amoled"
    val themeColor: String = "monochrome", // "monochrome", "blue", "green", "purple", "orange", "red", "pink", "teal", "amber"
    val language: String = "tr",          // "tr", "en", "ru"
    val fontStyle: String = "Default",
    val fontSize: String = "16",
    val textColor: Long = 0xFFFFFFFF,
    val isUseGameFont: Boolean = false,
    val isAudioPlay: Boolean = true,
    val isMuteVideo: Boolean = false,
    val autoscroll: Boolean = true,
    val separator: Boolean = false,
    val disableImage: Boolean = false,
    val permImgDialog: Boolean = false
)
