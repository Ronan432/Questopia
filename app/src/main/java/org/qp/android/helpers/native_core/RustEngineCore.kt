package org.qp.android.helpers.native_core

import android.util.Log

object RustEngineCore {
    private const val TAG = "RustEngineCore"
    var isLoaded = false
        private set

    init {
        try {
            System.loadLibrary("questopia_rust")
            isLoaded = true
            Log.i(TAG, "RustEngineCore native library loaded successfully.")
        } catch (t: Throwable) {
            Log.w(TAG, "RustEngineCore native library not available, using standard engine fallback: ${t.message}")
            isLoaded = false
        }
    }

    external fun parseHtml(input: String): String
    external fun parseRepositoryXml(xmlInput: String): String
    external fun convertEncoding(bytes: ByteArray, fromCharset: String): String
    external fun extractArchive(archivePath: String, targetDir: String): Int
    external fun readArchiveFile(archivePath: String, entryPath: String): ByteArray?

    /**
     * Parse HTML with fallback to standard Android / Java parsing if native core is unavailable.
     */
    fun fastParseHtml(input: String): String {
        return if (isLoaded) {
            try {
                parseHtml(input)
            } catch (e: Throwable) {
                Log.w(TAG, "Error in Rust fastParseHtml, falling back: ${e.message}")
                input
            }
        } else {
            input
        }
    }

    /**
     * Parse remote repository stock XML with Rust quick-xml, with fallback.
     */
    fun fastParseRepositoryXml(xmlInput: String): String? {
        if (!isLoaded || xmlInput.isBlank()) return null
        return try {
            val json = parseRepositoryXml(xmlInput)
            if (json.isNotBlank()) json else null
        } catch (e: Throwable) {
            Log.w(TAG, "Error in Rust fastParseRepositoryXml: ${e.message}")
            null
        }
    }

    /**
     * Convert charset with encoding_rs, with fallback to standard Java Charset.
     */
    fun fastConvertEncoding(bytes: ByteArray, charset: String): String {
        if (isLoaded) {
            try {
                val res = convertEncoding(bytes, charset)
                if (res.isNotEmpty()) return res
            } catch (e: Throwable) {
                Log.w(TAG, "Error in Rust fastConvertEncoding: ${e.message}")
            }
        }
        return try {
            String(bytes, java.nio.charset.Charset.forName(charset))
        } catch (e: Exception) {
            String(bytes, java.nio.charset.StandardCharsets.UTF_8)
        }
    }

    /**
     * Extract archive with fallback.
     */
    fun fastExtractArchive(archivePath: String, targetDir: String): Int {
        return if (isLoaded) {
            try {
                extractArchive(archivePath, targetDir)
            } catch (e: Throwable) {
                Log.w(TAG, "Error in Rust fastExtractArchive: ${e.message}")
                -1
            }
        } else {
            -1
        }
    }
}
