package org.qp.android.model.archive

import android.content.Context
import android.util.Log
import androidx.annotation.WorkerThread
import org.qp.android.helpers.utils.FileUtil.findOrCreateFolder
import org.qp.android.helpers.utils.ThreadUtil.assertNonUiThread
import java.io.File
import java.io.FileOutputStream
import java.nio.charset.Charset
import java.nio.charset.StandardCharsets
import java.util.zip.ZipFile

class ArchiveUnpack(
    private val context: Context,
    private val targetArchive: File,
    private var destFolder: File
) {
    companion object {
        private const val TAG = "ArchiveUnpack"
        private val EXT_PATTERN = Regex("\\.(?:r\\d{2,3}|rar|zip|aqsp)$", RegexOption.IGNORE_CASE)
    }

    @JvmField
    var unpackFolder: File? = null

    @WorkerThread
    fun extractArchiveEntries() {
        assertNonUiThread()
        if (!targetArchive.exists() || !targetArchive.isFile) {
            Log.e(TAG, "Archive file does not exist: ${targetArchive.absolutePath}")
            return
        }

        var zipFile: ZipFile? = null
        val encodings = listOf(StandardCharsets.UTF_8, Charset.forName("CP1251"), Charset.forName("CP866"))
        for (charset in encodings) {
            try {
                zipFile = ZipFile(targetArchive, charset)
                break
            } catch (_: Exception) {
                // ignore and try next charset
            }
        }

        if (zipFile == null) {
            try {
                zipFile = ZipFile(targetArchive)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to open archive: ${targetArchive.absolutePath}", e)
                return
            }
        }

        zipFile.use { zip ->
            val entries = zip.entries().asSequence().toList()

            var hasRootQsp = false
            var firstTopDir: String? = null

            for (entry in entries) {
                val name = entry.name.replace('\\', '/')
                val segments = name.split('/').filter { it.isNotEmpty() }
                if (segments.isEmpty()) continue

                if (name.endsWith(".qsp", ignoreCase = true) || name.endsWith(".gam", ignoreCase = true)) {
                    if (segments.size == 1) {
                        hasRootQsp = true
                    }
                }
                if (firstTopDir == null && segments.isNotEmpty()) {
                    firstTopDir = segments[0]
                }
            }

            var extractionTargetDir = destFolder
            if (hasRootQsp) {
                val archiveName = targetArchive.name
                val folderName = EXT_PATTERN.replace(archiveName, "")
                extractionTargetDir = findOrCreateFolder(context, destFolder, folderName) ?: File(destFolder, folderName).apply { mkdirs() }
                unpackFolder = extractionTargetDir
            } else if (firstTopDir != null) {
                unpackFolder = File(destFolder, firstTopDir)
            } else {
                unpackFolder = destFolder
            }

            val canonicalTargetDirPath = extractionTargetDir.canonicalPath

            for (entry in entries) {
                val entryName = entry.name.replace('\\', '/')
                val outputFile = File(extractionTargetDir, entryName)

                // Zip Slip protection
                val canonicalOutputFile = outputFile.canonicalPath
                if (!canonicalOutputFile.startsWith(canonicalTargetDirPath + File.separator) &&
                    canonicalOutputFile != canonicalTargetDirPath
                ) {
                    Log.w(TAG, "Zip Slip detected in entry: $entryName")
                    continue
                }

                if (entry.isDirectory) {
                    outputFile.mkdirs()
                } else {
                    outputFile.parentFile?.mkdirs()
                    zip.getInputStream(entry).use { input ->
                        FileOutputStream(outputFile).use { output ->
                            input.copyTo(output)
                        }
                    }
                }
            }
        }
    }
}
