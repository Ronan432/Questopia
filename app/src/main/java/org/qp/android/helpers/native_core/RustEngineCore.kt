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
