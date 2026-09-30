package org.qp.desktop.engine

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.libqsp.jni.QSPLib
import java.io.File

class DesktopQspEngine : QSPLib() {
    var onStateUpdate: (() -> Unit)? = null
    var latestMessage by mutableStateOf<String?>(null)
    var activeInputBoxPrompt by mutableStateOf<String?>(null)
    var inputBoxCallback: ((String) -> Unit)? = null
    var activeMenuOptions by mutableStateOf<List<String>?>(null)
    var menuCallback: ((Int) -> Unit)? = null
    var displayedImageFile by mutableStateOf<String?>(null)

    var isEngineRunning by mutableStateOf(false)
    var activeGameFile: File? = null

    fun ensureEngineInit() {
        if (!isEngineRunning) {
            try {
                init()
                isEngineRunning = true
            } catch (e: Throwable) {
                e.printStackTrace()
            }
        }
    }

    fun startDemoQuest(title: String = "Questopia Başlangıç Macerası"): Boolean {
        ensureEngineInit()
        try {
            restartGame(true)
            // Execute initial demo story code via QSP engine
            execString("'\$ongame' = 'Questopia Demo'", false)
            execString("'# main' \n 'Questopia Masaüstü Macera Motoruna Hoş Geldiniz!' \n 'Bu interaktif macera ortamında QSP oyunlarını çalıştırabilir, kaydedebilir ve envanterinizi yönetebilirsiniz.' \n 'Devam etmek için aşağıdaki eylemlerden birini seçin.'", false)
            execString("act 'Odayı İncele': \n   'Oda sessiz ve loş. Masanın üzerinde eski bir harita ve parlak bir kristal duruyor.' \n   addobj 'Eski Harita' \n   addobj 'Parlak Kristal' \n end", false)
            execString("act 'Kapıyı Aç': \n   'Kapıyı açtın ve geniş bir kütüphaneye adım attın!' \n   'Burada binlerce interaktif hikaye kitabı seni bekliyor.' \n end", false)
            execString("act 'Envanteri Kontrol Et': \n   'Çantanı açtın. Yolculuğa hazır görünüyorsun!' \n end", false)
            execLocationCode("main", true)
            onStateUpdate?.invoke()
            return true
        } catch (e: Throwable) {
            e.printStackTrace()
        }
        return false
    }

    fun loadAndStartGame(file: File?): Boolean {
        ensureEngineInit()
        if (file == null || !file.exists() || !file.isFile || file.length() == 0L) {
            return startDemoQuest()
        }

        try {
            activeGameFile = file
            val bytes = file.readBytes()
            val success = loadGameWorldFromData(bytes, true)
            if (success) {
                restartGame(true)
                onStateUpdate?.invoke()
                return true
            }
        } catch (e: Throwable) {
            e.printStackTrace()
        }
        return false
    }

    fun saveGame(saveFile: File): Boolean {
        try {
            val data = saveGameAsData(false)
            if (data != null && data.isNotEmpty()) {
                saveFile.writeBytes(data)
                return true
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

    fun loadSavedGame(saveFile: File): Boolean {
        try {
            if (saveFile.exists()) {
                val data = saveFile.readBytes()
                val success = openSavedGameFromData(data, true)
                if (success) {
                    onStateUpdate?.invoke()
                    return true
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

    override fun onShowMessage(text: String?) {
        latestMessage = text
        onStateUpdate?.invoke()
    }

    override fun onRefreshInt(isForced: Boolean) {
        onStateUpdate?.invoke()
    }

    override fun onShowImage(file: String?) {
        displayedImageFile = file
        onStateUpdate?.invoke()
    }

    override fun onInputBox(text: String?): String {
        activeInputBoxPrompt = text
        return ""
    }

    override fun onShowMenu(items: Array<out ListItem>?): Int {
        if (items == null) return -1
        activeMenuOptions = items.map { it.name() }
        return -1
    }
}
