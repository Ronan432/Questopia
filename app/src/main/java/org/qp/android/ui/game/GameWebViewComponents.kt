package org.qp.android.ui.game

import android.net.Uri
import android.util.Log
import android.view.HapticFeedbackConstants
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.widget.LinearLayout
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.text.HtmlCompat
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.SubcomposeAsyncImage
import coil.request.CachePolicy
import coil.request.ImageRequest
import com.libqsp.jni.QSPLib
import org.qp.android.helpers.utils.FileUtil.fromRelPath
import org.qp.android.ui.common.MorphingSurface
import org.qp.android.ui.stock.ShimmerPlaceholder

@Composable
fun GameListItemCard(
    item: QSPLib.ListItem,
    shape: Shape = RoundedCornerShape(20.dp),
    onClick: () -> Unit,
    onLongClick: (() -> Unit)? = null
) {
    val context = LocalContext.current
    val gameViewModel: GameViewModel = viewModel()

    LaunchedEffect(item.name, item.image) {
        Log.d("QUEST_INVENTORY", "Rendering item: name=${item.name}, image=${item.image}")
    }

    val resolvedImagePath = remember(item.image, item.name) {
        if (!item.image.isNullOrBlank()) {
            item.image
        } else if (!item.name.isNullOrBlank() && item.name.contains("<img", ignoreCase = true)) {
            val match = Regex("""src=["']?([^"'>\s]+)["']?""", RegexOption.IGNORE_CASE).find(item.name)
            val relPath = match?.groupValues?.getOrNull(1)?.replace("\\", "/")
            if (!relPath.isNullOrBlank()) {
                val curDir = gameViewModel.getCurGameDir().get()
                if (curDir != null) {
                    val docFile = fromRelPath(context, relPath, curDir)
                    if (docFile != null && docFile.exists()) {
                        docFile.uri.toString()
                    } else {
                        relPath
                    }
                } else {
                    relPath
                }
            } else ""
        } else ""
    }

    val textParsed = remember(item.name) {
        if (item.name.isNullOrBlank()) ""
        else HtmlCompat.fromHtml(item.name, HtmlCompat.FROM_HTML_MODE_LEGACY).toString().trim()
    }

    val activity = context as? GameActivity
    val finalLongClick = onLongClick ?: if (!resolvedImagePath.isNullOrBlank()) {
        {
            activity?.posterMenuState?.value = resolvedImagePath
        }
    } else null

    MorphingSurface(
        shape = shape,
        color = MaterialTheme.colorScheme.surfaceContainer,
        modifier = Modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = 52.dp),
        onClick = onClick,
        onLongClick = finalLongClick
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (!resolvedImagePath.isNullOrBlank()) {
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = MaterialTheme.colorScheme.surfaceContainerHighest,
                    modifier = Modifier.size(32.dp)
                ) {
                    SubcomposeAsyncImage(
                        model = ImageRequest.Builder(context)
                            .data(resolvedImagePath)
                            .crossfade(true)
                            .diskCachePolicy(CachePolicy.ENABLED)
                            .memoryCachePolicy(CachePolicy.ENABLED)
                            .build(),
                        contentDescription = null,
                        loading = {
                            ShimmerPlaceholder()
                        },
                        error = {
                            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = Icons.Outlined.Image,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        },
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )
                }
                if (textParsed.isNotBlank()) {
                    Spacer(modifier = Modifier.width(10.dp))
                }
            }
            if (textParsed.isNotBlank()) {
                Text(
                    text = textParsed,
                    style = MaterialTheme.typography.bodyMedium.copy(
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold
                    ),
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
fun GameHtmlWebView(
    htmlContent: String,
    viewModel: GameViewModel,
    activity: GameActivity? = null
) {
    val isPinchZoom = viewModel.settingsController?.isPinchZoomEnabled ?: true
    AndroidView(
        factory = { ctx ->
            WebView(ctx).apply {
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                webChromeClient = object : WebChromeClient() {
                    override fun onConsoleMessage(message: android.webkit.ConsoleMessage?): Boolean {
                        Log.d("GameWebView", "Console [${message?.messageLevel()}]: ${message?.message()} (${message?.sourceId()}:${message?.lineNumber()})")
                        return true
                    }
                }
                viewModel.getDefaultWebClient(this)
                settings.apply {
                    setSupportZoom(isPinchZoom)
                    builtInZoomControls = isPinchZoom
                    displayZoomControls = false
                    useWideViewPort = true
                    loadWithOverviewMode = true
                    mediaPlaybackRequiresUserGesture = false
                    allowFileAccess = true
                    allowContentAccess = true
                    allowFileAccessFromFileURLs = true
                    allowUniversalAccessFromFileURLs = true
                    domStorageEnabled = true
                    databaseEnabled = true
                    javaScriptEnabled = true
                    mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                }
                setOnLongClickListener {
                    val hit = hitTestResult
                    if (hit.type == WebView.HitTestResult.IMAGE_TYPE || hit.type == WebView.HitTestResult.SRC_IMAGE_ANCHOR_TYPE) {
                        val src = hit.extra
                        if (!src.isNullOrBlank()) {
                            val uri = viewModel.getImageUriFromPath(src)
                            val finalUri = if (uri != Uri.EMPTY) uri.toString() else src
                            performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
                            val act = activity ?: (context as? GameActivity) ?: (viewModel.getGameActivity())
                            act?.posterMenuState?.value = finalUri
                            return@setOnLongClickListener true
                        }
                    }
                    false
                }
                addJavascriptInterface(object : Any() {
                    @JavascriptInterface
                    fun onClickImage(src: String?) {
                        if (src == null) return
                        val uri = viewModel.getImageUriFromPath(src)
                        if (uri != Uri.EMPTY) {
                            viewModel.showPicture(uri.toString())
                        }
                    }
                    @JavascriptInterface
                    fun onLongClickImage(src: String?) {
                        if (src == null) return
                        val uri = viewModel.getImageUriFromPath(src)
                        val finalUri = if (uri != Uri.EMPTY) uri.toString() else src
                        val act = activity ?: (context as? GameActivity) ?: (viewModel.getGameActivity())
                        act?.runOnUiThread {
                            act.window.decorView.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
                            act.posterMenuState.value = finalUri
                        }
                    }
                }, "img")
                setBackgroundColor(android.graphics.Color.TRANSPARENT)
                tag = htmlContent
                loadDataWithBaseURL("https://questopia.local/", htmlContent, "text/html", "UTF-8", null)
            }
        },
        update = { webView ->
            webView.settings.apply {
                setSupportZoom(isPinchZoom)
                builtInZoomControls = isPinchZoom
                displayZoomControls = false
                useWideViewPort = true
                loadWithOverviewMode = true
            }
            if (webView.tag != htmlContent) {
                webView.tag = htmlContent
                webView.loadDataWithBaseURL("https://questopia.local/", htmlContent, "text/html", "UTF-8", null)
            }
        },
        modifier = Modifier.fillMaxSize()
    )
}
