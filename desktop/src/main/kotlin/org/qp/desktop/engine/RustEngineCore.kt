package org.qp.desktop.engine

object RustEngineCore {
    var isLoaded = false
        private set

    init {
        try {
            System.loadLibrary("questopia_rust")
            isLoaded = true
            println("[RustEngineCore] questopia_rust native library loaded successfully.")
        } catch (t: Throwable) {
            println("[RustEngineCore] questopia_rust native library not available, fallback active: ${t.message}")
            isLoaded = false
        }
    }

    external fun parseHtml(input: String): String
    external fun extractArchive(archivePath: String, targetDir: String): Int
    external fun readArchiveFile(archivePath: String, entryPath: String): ByteArray?

    fun fastParseHtml(input: String): String {
        return if (isLoaded) {
            try {
                parseHtml(input)
            } catch (e: Throwable) {
                input
            }
        } else {
            input
        }
    }

    fun fastExtractArchive(archivePath: String, targetDir: String): Int {
        return if (isLoaded) {
            try {
                extractArchive(archivePath, targetDir)
            } catch (e: Throwable) {
                -1
            }
        } else {
            -1
        }
    }
}
