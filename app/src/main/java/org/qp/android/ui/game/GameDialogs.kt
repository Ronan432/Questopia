package org.qp.android.ui.game

import android.content.Context
import android.net.Uri
import android.view.HapticFeedbackConstants
import android.view.ViewGroup
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ExitToApp
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.preference.PreferenceManager
import coil.compose.SubcomposeAsyncImage
import org.qp.android.R
import org.qp.android.ui.common.MorphingButton
import org.qp.android.ui.common.MorphingOutlinedButton
import org.qp.android.ui.common.MorphingSurface
import org.qp.android.ui.common.getGroupedItemShape

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun GameDialogsHost(activity: GameActivity, viewModel: GameViewModel) {
    val inputDialogData by activity.inputDialogState
    val executorDialogData by activity.executorDialogState
    val messageDialogData by activity.messageDialogState
    val menuDialogData by activity.menuDialogState
    val errorDialogData by activity.errorDialogState
    val imageDialogUri by activity.imageDialogState
    val posterMenuUri by activity.posterMenuState
    val showCloseDialog by activity.showCloseDialogState
    val showLoadDialog by activity.showLoadDialogState

    // 1. User Input Dialog (Compact, Not Screen Filling)
    if (inputDialogData != null) {
        var textInput by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = {
                inputDialogData?.inputQueue?.add("")
                activity.inputDialogState.value = null
            },
            title = { Text(inputDialogData?.title ?: stringResource(R.string.userInputTitle), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold) },
            text = {
                OutlinedTextField(
                    value = textInput,
                    onValueChange = { textInput = it },
                    label = { Text(stringResource(R.string.userInputTitle)) },
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth().padding(top = 4.dp)
                )
            },
            confirmButton = {
                MorphingButton(onClick = {
                    inputDialogData?.inputQueue?.add(textInput)
                    activity.inputDialogState.value = null
                }) {
                    Text(stringResource(android.R.string.ok))
                }
            },
            dismissButton = {
                MorphingOutlinedButton(onClick = {
                    inputDialogData?.inputQueue?.add("")
                    activity.inputDialogState.value = null
                }) {
                    Text(stringResource(android.R.string.cancel))
                }
            }
        )
    }

    // 2. Executor Dialog (Compact)
    if (executorDialogData != null) {
        var textInput by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = {
                executorDialogData?.inputQueue?.add("")
                activity.executorDialogState.value = null
            },
            title = { Text(executorDialogData?.title ?: stringResource(R.string.execStringTitle), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold) },
            text = {
                OutlinedTextField(
                    value = textInput,
                    onValueChange = { textInput = it },
                    label = { Text(stringResource(R.string.command)) },
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth().padding(top = 4.dp)
                )
            },
            confirmButton = {
                MorphingButton(onClick = {
                    executorDialogData?.inputQueue?.add(textInput)
                    activity.executorDialogState.value = null
                }) {
                    Text(stringResource(android.R.string.ok))
                }
            },
            dismissButton = {
                MorphingOutlinedButton(onClick = {
                    executorDialogData?.inputQueue?.add("")
                    activity.executorDialogState.value = null
                }) {
                    Text(stringResource(android.R.string.cancel))
                }
            }
        )
    }

    // 3. Game Message Dialog (Rendered with HTML / Image / Text support, No Blank Text)
    if (messageDialogData != null) {
        val rawMessage = messageDialogData?.message ?: ""
        val prefs = remember { PreferenceManager.getDefaultSharedPreferences(activity) }
        val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
        val dialogBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow

        AlertDialog(
            onDismissRequest = {
                messageDialogData?.latch?.countDown()
                activity.messageDialogState.value = null
            },
            containerColor = dialogBg,
            title = {
                Text(
                    text = activity.gameTitleState.value.ifBlank { stringResource(R.string.mainDescTitle) },
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
            },
            text = {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 40.dp, max = 360.dp)
                ) {
                    if (rawMessage.contains("<") && rawMessage.contains(">")) {
                        GameHtmlWebView(
                            htmlContent = rawMessage,
                            viewModel = viewModel,
                            activity = activity
                        )
                    } else {
                        Text(
                            text = rawMessage,
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
            },
            confirmButton = {
                MorphingButton(onClick = {
                    messageDialogData?.latch?.countDown()
                    activity.messageDialogState.value = null
                }) {
                    Text(stringResource(android.R.string.ok))
                }
            }
        )
    }

    // 4. In-Game Select Menu Dialog (No Blank Space, Expressive Buttons)
    if (menuDialogData != null) {
        val prefs = remember { PreferenceManager.getDefaultSharedPreferences(activity) }
        val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
        val dialogBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow
        val itemBg = if (isAmoled) Color(0xFF0D0D0D) else MaterialTheme.colorScheme.surfaceContainer

        Dialog(
            onDismissRequest = {
                menuDialogData?.resultQueue?.add(-1)
                activity.menuDialogState.value = null
            }
        ) {
            Surface(
                shape = RoundedCornerShape(28.dp),
                color = dialogBg,
                tonalElevation = 6.dp,
                shadowElevation = 12.dp,
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.25f)),
                modifier = Modifier
                    .fillMaxWidth()
                    .wrapContentHeight()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp)
                ) {
                    Text(
                        text = stringResource(R.string.selectActionTitle),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.padding(bottom = 16.dp)
                    )

                    val items = menuDialogData!!.items
                    LazyColumn(
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(max = 340.dp),
                        verticalArrangement = Arrangement.spacedBy(2.dp)
                    ) {
                        itemsIndexed(items) { index, item ->
                            val itemShape = getGroupedItemShape(index, items.size)
                            MorphingSurface(
                                shape = itemShape,
                                color = itemBg,
                                pressedRadius = 24.dp,
                                onClick = {
                                    menuDialogData?.resultQueue?.add(index)
                                    activity.menuDialogState.value = null
                                },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(horizontal = 16.dp, vertical = 14.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(32.dp)
                                            .clip(CircleShape)
                                            .background(MaterialTheme.colorScheme.primaryContainer),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            text = "${index + 1}",
                                            style = MaterialTheme.typography.labelLarge,
                                            fontWeight = FontWeight.Bold,
                                            color = MaterialTheme.colorScheme.onPrimaryContainer
                                        )
                                    }
                                    Spacer(modifier = Modifier.width(12.dp))
                                    Text(
                                        text = item,
                                        style = MaterialTheme.typography.bodyLarge,
                                        fontWeight = FontWeight.Medium,
                                        color = MaterialTheme.colorScheme.onSurface,
                                        modifier = Modifier.weight(1f)
                                    )
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    MorphingOutlinedButton(
                        onClick = {
                            menuDialogData?.resultQueue?.add(-1)
                            activity.menuDialogState.value = null
                        },
                        modifier = Modifier.align(Alignment.End)
                    ) {
                        Text(stringResource(android.R.string.cancel))
                    }
                }
            }
        }
    }

    // 5. Error Dialog (Enhanced diagnostics and report copy)
    if (errorDialogData != null) {
        val clipboard = LocalContext.current.getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
        val context = LocalContext.current

        AlertDialog(
            onDismissRequest = { activity.errorDialogState.value = null },
            icon = { Icon(Icons.Outlined.ErrorOutline, contentDescription = null, tint = MaterialTheme.colorScheme.error) },
            title = { Text(stringResource(R.string.errorReportTitle), fontWeight = FontWeight.Bold) },
            text = {
                Column(modifier = Modifier.fillMaxWidth()) {
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = MaterialTheme.colorScheme.surfaceContainerHighest,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp)
                    ) {
                        Text(
                            text = errorDialogData!!.message,
                            style = MaterialTheme.typography.bodySmall.copy(
                                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace,
                                lineHeight = 18.sp
                            ),
                            color = MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.padding(12.dp)
                        )
                    }
                }
            },
            confirmButton = {
                MorphingButton(onClick = { activity.errorDialogState.value = null }) {
                    Text(stringResource(android.R.string.ok))
                }
            },
            dismissButton = {
                MorphingOutlinedButton(onClick = {
                    val clip = android.content.ClipData.newPlainText("QSP Error", errorDialogData!!.message)
                    clipboard.setPrimaryClip(clip)
                    android.widget.Toast.makeText(context, R.string.errorCopied, android.widget.Toast.LENGTH_SHORT).show()
                }) {
                    Icon(
                        imageVector = Icons.Outlined.ContentCopy,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(stringResource(R.string.copyErrorReport))
                }
            }
        )
    }

    // 6. Image / Video Preview Dialog
    if (!imageDialogUri.isNullOrBlank()) {
        val uri = imageDialogUri!!
        val isVideo = uri.endsWith(".webm", ignoreCase = true) ||
                uri.endsWith(".mp4", ignoreCase = true) ||
                uri.endsWith(".m4v", ignoreCase = true) ||
                uri.endsWith(".ogv", ignoreCase = true) ||
                uri.endsWith(".mkv", ignoreCase = true) ||
                uri.endsWith(".avi", ignoreCase = true)
        val view = LocalView.current
        Dialog(
            onDismissRequest = { activity.imageDialogState.value = null },
            properties = DialogProperties(usePlatformDefaultWidth = false)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.95f))
                    .clickable { activity.imageDialogState.value = null },
                contentAlignment = Alignment.Center
            ) {
                if (isVideo) {
                    AndroidView(
                        factory = { ctx ->
                            android.widget.VideoView(ctx).apply {
                                layoutParams = ViewGroup.LayoutParams(
                                    ViewGroup.LayoutParams.MATCH_PARENT,
                                    ViewGroup.LayoutParams.WRAP_CONTENT
                                )
                                setVideoURI(Uri.parse(uri))
                                setOnPreparedListener { mp ->
                                    mp.isLooping = true
                                    start()
                                }
                                setOnErrorListener { _, _, _ ->
                                    false
                                }
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .combinedClickable(
                                onClick = { activity.imageDialogState.value = null },
                                onLongClick = {
                                    view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
                                    val u = imageDialogUri
                                    activity.imageDialogState.value = null
                                    if (u != null) openYandexImageSearch(activity, u)
                                }
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        SubcomposeAsyncImage(
                            model = imageDialogUri,
                            contentDescription = null,
                            loading = {
                                CircularProgressIndicator(color = Color.White)
                            },
                            contentScale = ContentScale.Fit,
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(16.dp)
                        )
                    }
                }
            }
        }
    }

    if (!posterMenuUri.isNullOrBlank()) {
        PosterContextMenuSheet(
            imageUri = posterMenuUri!!,
            onDismiss = { activity.posterMenuState.value = null }
        )
    }

    // 7. Prompt Close Dialog
    if (showCloseDialog) {
        AlertDialog(
            onDismissRequest = { activity.showCloseDialogState.value = false },
            icon = { Icon(Icons.AutoMirrored.Outlined.ExitToApp, contentDescription = null, tint = MaterialTheme.colorScheme.primary) },
            title = { Text(stringResource(R.string.close)) },
            text = { Text(stringResource(R.string.promptCloseGame), style = MaterialTheme.typography.bodyMedium) },
            confirmButton = {
                MorphingButton(onClick = {
                    activity.showCloseDialogState.value = false
                    viewModel.stopAudio()
                    viewModel.stopNativeLib()
                    viewModel.removeCallback()
                    activity.finish()
                }) {
                    Text(stringResource(android.R.string.ok))
                }
            },
            dismissButton = {
                MorphingOutlinedButton(onClick = { activity.showCloseDialogState.value = false }) {
                    Text(stringResource(android.R.string.cancel))
                }
            }
        )
    }

    // 8. Load Game External Dialog
    if (showLoadDialog) {
        AlertDialog(
            onDismissRequest = { activity.showLoadDialogState.value = false },
            title = { Text(stringResource(R.string.loadGamePopup)) },
            text = { Text(stringResource(R.string.loadGamePopup), style = MaterialTheme.typography.bodyMedium) },
            confirmButton = {
                MorphingButton(onClick = {
                    activity.showLoadDialogState.value = false
                    activity.startReadOrWriteSave(GameActivity.LOAD)
                }) {
                    Text(stringResource(android.R.string.ok))
                }
            },
            dismissButton = {
                MorphingOutlinedButton(onClick = { activity.showLoadDialogState.value = false }) {
                    Text(stringResource(android.R.string.cancel))
                }
            }
        )
    }
}
