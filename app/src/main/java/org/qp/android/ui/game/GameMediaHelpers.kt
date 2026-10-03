package org.qp.android.ui.game

import android.content.Context
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.preference.PreferenceManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.qp.android.R
import org.qp.android.ui.common.CustomDrawerHandle

fun copyImageToClipboard(context: Context, imageUriStr: String) {
    try {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
        val uri = Uri.parse(imageUriStr)
        val clip = android.content.ClipData.newUri(context.contentResolver, "Image", uri)
        clipboard.setPrimaryClip(clip)
        android.widget.Toast.makeText(context, R.string.imageCopied, android.widget.Toast.LENGTH_SHORT).show()
    } catch (e: Exception) {
        Log.e("GameActivity", "Failed to copy image", e)
    }
}

fun saveImageToGallery(context: Context, imageUriStr: String) {
    kotlinx.coroutines.CoroutineScope(Dispatchers.IO).launch {
        try {
            val uri = Uri.parse(imageUriStr)
            val inputStream = if (imageUriStr.startsWith("http://") || imageUriStr.startsWith("https://")) {
                java.net.URL(imageUriStr).openStream()
            } else {
                context.contentResolver.openInputStream(uri)
            }
            if (inputStream != null) {
                val fileName = "Questopia_${System.currentTimeMillis()}.jpg"
                val values = android.content.ContentValues().apply {
                    put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, fileName)
                    put(android.provider.MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        put(android.provider.MediaStore.Images.Media.RELATIVE_PATH, android.os.Environment.DIRECTORY_PICTURES + "/Questopia")
                        put(android.provider.MediaStore.Images.Media.IS_PENDING, 1)
                    }
                }
                val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    android.provider.MediaStore.Images.Media.getContentUri(android.provider.MediaStore.VOLUME_EXTERNAL_PRIMARY)
                } else {
                    android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                }
                val itemUri = context.contentResolver.insert(collection, values)
                if (itemUri != null) {
                    context.contentResolver.openOutputStream(itemUri)?.use { out ->
                        inputStream.copyTo(out)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        values.clear()
                        values.put(android.provider.MediaStore.Images.Media.IS_PENDING, 0)
                        context.contentResolver.update(itemUri, values, null, null)
                    }
                    withContext(Dispatchers.Main) {
                        android.widget.Toast.makeText(context, R.string.imageSaved, android.widget.Toast.LENGTH_SHORT).show()
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("GameActivity", "Failed to save image", e)
        }
    }
}

fun performYandexImageSearch(context: Context, imageUriStr: String) {
    kotlinx.coroutines.CoroutineScope(Dispatchers.IO).launch {
        try {
            if (imageUriStr.startsWith("http://") || imageUriStr.startsWith("https://")) {
                val searchUrl = "https://yandex.com/images/search?rpt=imageview&url=" + java.net.URLEncoder.encode(imageUriStr, "UTF-8")
                val intent = android.content.Intent(android.content.Intent.ACTION_VIEW, Uri.parse(searchUrl)).apply {
                    flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
            } else {
                val uri = Uri.parse(imageUriStr)
                val bytes = if (imageUriStr.startsWith("file://")) {
                    java.io.File(uri.path ?: "").readBytes()
                } else {
                    context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                }

                if (bytes != null && bytes.isNotEmpty()) {
                    val boundary = "Boundary" + System.currentTimeMillis()
                    val uploadUrl = "https://yandex.com/images/search?rpt=imageview&format=json&request=%7B%22blocks%22%3A%5B%7B%22block%22%3A%22b-page_type_search-by-image__link%22%7D%5D%7D"
                    val conn = (java.net.URL(uploadUrl).openConnection() as java.net.HttpURLConnection).apply {
                        requestMethod = "POST"
                        doOutput = true
                        doInput = true
                        connectTimeout = 15000
                        readTimeout = 15000
                        setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")
                        setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                        setRequestProperty("Accept", "application/json, text/javascript, */*; q=0.01")
                        setRequestProperty("X-Requested-With", "XMLHttpRequest")
                    }
                    val out = conn.outputStream
                    val writer = java.io.PrintWriter(java.io.OutputStreamWriter(out, "UTF-8"), true)
                    writer.append("--").append(boundary).append("\r\n")
                    writer.append("Content-Disposition: form-data; name=\"upfile\"; filename=\"image.jpg\"\r\n")
                    writer.append("Content-Type: image/jpeg\r\n\r\n").flush()
                    out.write(bytes)
                    out.flush()
                    writer.append("\r\n--").append(boundary).append("--\r\n").flush()
                    writer.close()
                    out.close()

                    val responseCode = conn.responseCode
                    if (responseCode == 200) {
                        val responseText = conn.inputStream.bufferedReader().use { it.readText() }
                        val json = org.json.JSONObject(responseText)
                        val blocks = json.optJSONArray("blocks")
                        if (blocks != null && blocks.length() > 0) {
                            val block = blocks.getJSONObject(0)
                            val params = block.optJSONObject("params")
                            val queryUrl = params?.optString("url")
                            if (!queryUrl.isNullOrBlank()) {
                                val finalUrl = if (queryUrl.startsWith("http")) queryUrl else "https://yandex.com/images/search?$queryUrl"
                                val intent = android.content.Intent(android.content.Intent.ACTION_VIEW, Uri.parse(finalUrl)).apply {
                                    flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                context.startActivity(intent)
                                return@launch
                            }
                        }
                    }

                    var redirectUrl = conn.getHeaderField("Location")
                    if (redirectUrl.isNullOrBlank()) {
                        redirectUrl = conn.url.toString()
                    }
                    if (redirectUrl.startsWith("/")) {
                        redirectUrl = "https://yandex.com$redirectUrl"
                    }
                    val intent = android.content.Intent(android.content.Intent.ACTION_VIEW, Uri.parse(redirectUrl)).apply {
                        flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(intent)
                } else {
                    val intent = android.content.Intent(android.content.Intent.ACTION_VIEW, Uri.parse("https://yandex.com/images/")).apply {
                        flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(intent)
                }
            }
        } catch (e: Exception) {
            Log.e("GameActivity", "Failed to search image on Yandex", e)
            try {
                val fallbackIntent = android.content.Intent(android.content.Intent.ACTION_VIEW, Uri.parse("https://yandex.com/images/")).apply {
                    flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(fallbackIntent)
            } catch (ignored: Exception) {}
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PosterContextMenuSheet(
    imageUri: String,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
    val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
    val sheetBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = sheetBg,
        dragHandle = { CustomDrawerHandle() },
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 4.dp)
                .padding(bottom = 24.dp)
                .navigationBarsPadding()
        ) {
            ExpressiveMenuGroup(
                items = listOf(
                    { shape ->
                        ExpressiveMenuItem(
                            icon = Icons.Outlined.ContentCopy,
                            title = stringResource(R.string.copyImage),
                            shape = shape,
                            onClick = {
                                onDismiss()
                                copyImageToClipboard(context, imageUri)
                            }
                        )
                    },
                    { shape ->
                        ExpressiveMenuItem(
                            icon = Icons.Outlined.FileDownload,
                            title = stringResource(R.string.downloadImage),
                            shape = shape,
                            onClick = {
                                onDismiss()
                                saveImageToGallery(context, imageUri)
                            }
                        )
                    },
                    { shape ->
                        ExpressiveMenuItem(
                            icon = Icons.Outlined.Search,
                            title = stringResource(R.string.yandexImageSearch),
                            shape = shape,
                            onClick = {
                                onDismiss()
                                performYandexImageSearch(context, imageUri)
                            }
                        )
                    }
                )
            )
        }
    }
}
