package org.qp.android.ui.game

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.util.Log
import android.widget.Toast
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.preference.PreferenceManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import org.qp.android.R
import org.qp.android.ui.common.CustomDrawerHandle
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.URL
import java.net.URLEncoder
import java.time.Duration
import java.util.Locale

fun copyImageToClipboard(context: Context, imageUriStr: String) {
    try {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
        val uri = Uri.parse(imageUriStr)
        val clip = android.content.ClipData.newUri(context.contentResolver, "Image", uri)
        clipboard.setPrimaryClip(clip)
        Toast.makeText(context, R.string.imageCopied, Toast.LENGTH_SHORT).show()
    } catch (e: Exception) {
        Log.e("GameActivity", "Failed to copy image", e)
    }
}

fun saveImageToGallery(context: Context, imageUriStr: String) {
    CoroutineScope(Dispatchers.IO).launch {
        try {
            val uri = Uri.parse(imageUriStr)
            val inputStream = if (imageUriStr.startsWith("http://") || imageUriStr.startsWith("https://")) {
                URL(imageUriStr).openStream()
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
                        Toast.makeText(context, R.string.imageSaved, Toast.LENGTH_SHORT).show()
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("GameActivity", "Failed to save image", e)
        }
    }
}

private val okHttpClient: OkHttpClient by lazy {
    OkHttpClient.Builder()
        .connectTimeout(Duration.ofSeconds(6))
        .readTimeout(Duration.ofSeconds(6))
        .followRedirects(true)
        .followSslRedirects(true)
        .build()
}

private fun launchBrowser(context: Context, url: String) {
    try {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
            if (context !is Activity) {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        context.startActivity(intent)
    } catch (e: ActivityNotFoundException) {
        Log.d("GameActivity", "Activity not found: ${e.message}")
    } catch (e: Exception) {
        Log.d("GameActivity", "Error: ${e.message}")
    }
}

private fun prepareImageBytes(rawBytes: ByteArray): ByteArray {
    return try {
        if (rawBytes.size <= 80 * 1024) return rawBytes
        val options = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        BitmapFactory.decodeByteArray(rawBytes, 0, rawBytes.size, options)
        val maxDim = maxOf(options.outWidth, options.outHeight)
        var sampleSize = 1
        while (maxDim / sampleSize > 600) {
            sampleSize *= 2
        }
        val decodeOptions = BitmapFactory.Options().apply {
            inSampleSize = sampleSize
        }
        val bitmap = BitmapFactory.decodeByteArray(rawBytes, 0, rawBytes.size, decodeOptions)
            ?: return rawBytes
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 75, out)
        bitmap.recycle()
        out.toByteArray()
    } catch (e: Exception) {
        rawBytes
    }
}

fun openYandexImageSearch(context: Context, imageUrl: String?) {
    if (imageUrl.isNullOrBlank()) return
    if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
        val encodedUrl = URLEncoder.encode(imageUrl, "UTF-8")
        launchBrowser(context, "https://yandex.com/images/search?rpt=imageview&url=$encodedUrl")
        return
    }

    try {
        Toast.makeText(context, R.string.yandexImageSearch, Toast.LENGTH_SHORT).show()
    } catch (ignored: Exception) {}

    CoroutineScope(Dispatchers.IO).launch {
        try {
            val uri = Uri.parse(imageUrl)
            val rawBytes = if (imageUrl.startsWith("file://")) {
                File(uri.path ?: "").readBytes()
            } else {
                context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
            }

            if (rawBytes == null || rawBytes.isEmpty()) {
                withContext(Dispatchers.Main) {
                    launchBrowser(context, "https://yandex.com/images/")
                }
                return@launch
            }

            val bytes = prepareImageBytes(rawBytes)
            val mediaType = "image/jpeg".toMediaTypeOrNull()
            val requestBody = MultipartBody.Builder()
                .setType(MultipartBody.FORM)
                .addFormDataPart("upfile", "image.jpg", bytes.toRequestBody(mediaType))
                .build()

            val lang = Locale.getDefault().language.lowercase()
            val base = when (lang) {
                "tr" -> "https://yandex.com.tr/gorsel/search"
                "ru", "be", "kk" -> "https://yandex.ru/images/search"
                else -> "https://yandex.com/images/search"
            }
            val uploadUrl = "$base?rpt=imageview&format=json&request=%7B%22blocks%22%3A%5B%7B%22block%22%3A%22b-page_type_search-by-image__link%22%7D%5D%7D"

            val request = Request.Builder()
                .url(uploadUrl)
                .post(requestBody)
                .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
                .header("Accept", "application/json, text/javascript, */*; q=0.01")
                .header("X-Requested-With", "XMLHttpRequest")
                .build()

            val response = okHttpClient.newCall(request).execute()
            var finalSearchUrl: String? = null

            if (response.isSuccessful) {
                val responseText = response.body?.string()
                if (!responseText.isNullOrBlank()) {
                    val json = JSONObject(responseText)
                    val blocks = json.optJSONArray("blocks")
                    if (blocks != null && blocks.length() > 0) {
                        val params = blocks.getJSONObject(0).optJSONObject("params")
                        val cbirId = params?.optString("cbirId")
                        val origImgUrl = params?.optString("originalImageUrl")
                        val queryUrl = params?.optString("url")

                        finalSearchUrl = when {
                            !cbirId.isNullOrBlank() -> "https://yandex.com/images/search?rpt=imageview&cbir_id=" + URLEncoder.encode(cbirId, "UTF-8")
                            !origImgUrl.isNullOrBlank() -> "https://yandex.com/images/search?rpt=imageview&url=" + URLEncoder.encode(origImgUrl, "UTF-8")
                            !queryUrl.isNullOrBlank() -> if (queryUrl.startsWith("http")) queryUrl else "https://yandex.com/images/search?$queryUrl"
                            else -> null
                        }
                    }
                }
            }

            val targetUrl = finalSearchUrl ?: "https://yandex.com/images/"
            withContext(Dispatchers.Main) {
                launchBrowser(context, targetUrl)
            }
        } catch (e: Exception) {
            Log.d("GameActivity", "Error: ${e.message}")
        }
    }
}

fun performYandexImageSearch(context: Context, imageUriStr: String) {
    openYandexImageSearch(context, imageUriStr)
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
