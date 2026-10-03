package org.qp.android.ui.game

import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.preference.PreferenceManager
import com.anggrayudi.storage.file.MimeType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.qp.android.R
import org.qp.android.helpers.utils.FileUtil.findOrCreateFile
import org.qp.android.helpers.utils.FileUtil.fromRelPath
import org.qp.android.ui.common.CustomDrawerHandle
import org.qp.android.ui.common.MorphingSurface
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SaveSlotsSheet(
    isSave: Boolean,
    activity: GameActivity,
    viewModel: GameViewModel,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val savesDirOpt = viewModel.savesDir
    val savesDir = if (savesDirOpt.isPresent) savesDirOpt.get() else null

    var selectedPage by remember { mutableIntStateOf(0) }
    var autoSaveSlot by remember { mutableStateOf<SlotInfo?>(null) }
    var slots by remember { mutableStateOf<List<SlotInfo>?>(null) }
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(isSave) {
        withContext(Dispatchers.IO) {
            val sdf = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault())

            // 1. Auto-save slot check
            val autoSaveFile = if (savesDir != null) fromRelPath(context, "autosave.sav", savesDir) else null
            val isAutoPresent = autoSaveFile != null && autoSaveFile.exists()
            val autoTimeStr = if (autoSaveFile != null && isAutoPresent) {
                sdf.format(Date(autoSaveFile.lastModified()))
            } else null
            val autoInfo = SlotInfo(
                index = -1,
                isPresent = isAutoPresent,
                timeStr = autoTimeStr,
                fileUri = autoSaveFile?.uri
            )

            // 2. 60 manual slots (10 pages x 6 slots)
            val list = mutableListOf<SlotInfo>()
            for (slotIndex in 0 until GameActivity.MAX_SAVE_SLOTS) {
                val filename = "${slotIndex + 1}.sav"
                val loadFile = if (savesDir != null) fromRelPath(context, filename, savesDir) else null
                val isSlotPresent = loadFile != null && loadFile.exists()
                val timeStr = if (loadFile != null && isSlotPresent) {
                    sdf.format(Date(loadFile.lastModified()))
                } else null
                list.add(
                    SlotInfo(
                        index = slotIndex,
                        isPresent = isSlotPresent,
                        timeStr = timeStr,
                        fileUri = loadFile?.uri
                    )
                )
            }
            withContext(Dispatchers.Main) {
                autoSaveSlot = autoInfo
                slots = list
                isLoading = false
            }
        }
    }

    val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
    val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
    val sheetBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow
    val slotItemBg = if (isAmoled) Color(0xFF0D0D0D) else MaterialTheme.colorScheme.surfaceContainer

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
            Text(
                text = if (isSave) stringResource(R.string.saveTitle) else stringResource(R.string.loadTitle),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(horizontal = 4.dp, vertical = 8.dp)
            )

            if (isLoading) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(180.dp),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(28.dp),
                        strokeWidth = 2.5.dp
                    )
                }
            } else {
                // 1. Dedicated Auto-Save Section at Top
                autoSaveSlot?.let { autoSlot ->
                    MorphingSurface(
                        shape = RoundedCornerShape(20.dp),
                        color = slotItemBg,
                        pressedRadius = 24.dp,
                        onClick = {
                            if (savesDir != null) {
                                if (isSave) {
                                    onDismiss()
                                    val saveFile = findOrCreateFile(context, savesDir, "autosave.sav", MimeType.TEXT)
                                    if (saveFile != null) {
                                        Log.d("SaveSlotsSheet", "Saving game to autosave.sav: ${saveFile.uri}")
                                        viewModel.requestForNativeLib(GameLibRequest.SAVE_FILE, saveFile.uri)
                                    }
                                } else {
                                    if (autoSlot.isPresent && autoSlot.fileUri != null) {
                                        onDismiss()
                                        Log.d("SaveSlotsSheet", "Loading game from autosave.sav: ${autoSlot.fileUri}")
                                        viewModel.requestForNativeLib(GameLibRequest.LOAD_FILE, autoSlot.fileUri)
                                    }
                                }
                            }
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 14.dp, vertical = 11.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(34.dp)
                                    .clip(CircleShape)
                                    .background(if (autoSlot.isPresent) MaterialTheme.colorScheme.tertiaryContainer else MaterialTheme.colorScheme.surfaceVariant),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Outlined.Autorenew,
                                    contentDescription = null,
                                    tint = if (autoSlot.isPresent) MaterialTheme.colorScheme.onTertiaryContainer else MaterialTheme.colorScheme.onSurfaceVariant,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = stringResource(R.string.autoSaveSlotLabel),
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Text(
                                    text = if (autoSlot.isPresent) stringResource(R.string.slotFilled, autoSlot.timeStr ?: "") else stringResource(R.string.slotEmptySubtitle),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = if (autoSlot.isPresent) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            Icon(
                                imageVector = if (isSave) Icons.Outlined.Save else Icons.Outlined.Download,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // 2. Page Navigation Selector Pills (1..10)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    for (pageIndex in 0 until GameActivity.MAX_PAGES) {
                        val isPageActive = pageIndex == selectedPage
                        val pageBg = if (isPageActive) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainerHigh
                        val pageTextColor = if (isPageActive) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant

                        MorphingSurface(
                            shape = RoundedCornerShape(12.dp),
                            color = pageBg,
                            pressedRadius = 16.dp,
                            onClick = { selectedPage = pageIndex }
                        ) {
                            Box(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = stringResource(R.string.pageIndicator, pageIndex + 1),
                                    style = MaterialTheme.typography.labelMedium,
                                    fontWeight = if (isPageActive) FontWeight.Bold else FontWeight.Medium,
                                    color = pageTextColor
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // 3. Paginated Slots (6 slots per page)
                slots?.let { slotList ->
                    val startIndex = selectedPage * GameActivity.SLOTS_PER_PAGE
                    val endIndex = minOf(startIndex + GameActivity.SLOTS_PER_PAGE, slotList.size)
                    val pageSlots = slotList.subList(startIndex, endIndex)

                    ExpressiveMenuGroup(
                        items = pageSlots.mapIndexed { indexInPage, slot ->
                            { shape ->
                                MorphingSurface(
                                    shape = shape,
                                    color = slotItemBg,
                                    pressedRadius = 24.dp,
                                    onClick = {
                                        if (savesDir != null) {
                                            if (isSave) {
                                                onDismiss()
                                                val saveFile = findOrCreateFile(context, savesDir, "${slot.index + 1}.sav", MimeType.TEXT)
                                                if (saveFile != null) {
                                                    Log.d("SaveSlotsSheet", "Saving game to slot ${slot.index + 1}: ${saveFile.uri}")
                                                    viewModel.requestForNativeLib(GameLibRequest.SAVE_FILE, saveFile.uri)
                                                } else {
                                                    Log.e("SaveSlotsSheet", "Failed to create/find save file for slot ${slot.index + 1}")
                                                }
                                            } else {
                                                if (slot.isPresent && slot.fileUri != null) {
                                                    onDismiss()
                                                    Log.d("SaveSlotsSheet", "Loading game from slot ${slot.index + 1}: ${slot.fileUri}")
                                                    viewModel.requestForNativeLib(GameLibRequest.LOAD_FILE, slot.fileUri)
                                                } else {
                                                    Log.e("SaveSlotsSheet", "Slot ${slot.index + 1} fileUri is null or not present!")
                                                }
                                            }
                                        }
                                    },
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(horizontal = 14.dp, vertical = 9.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Box(
                                            modifier = Modifier
                                                .size(32.dp)
                                                .clip(CircleShape)
                                                .background(if (slot.isPresent) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Text(
                                                text = "${slot.index + 1}",
                                                style = MaterialTheme.typography.bodyMedium,
                                                fontWeight = FontWeight.Bold,
                                                color = if (slot.isPresent) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                        }
                                        Spacer(modifier = Modifier.width(12.dp))
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                text = stringResource(R.string.slotLabel, slot.index + 1),
                                                style = MaterialTheme.typography.bodyMedium,
                                                fontWeight = FontWeight.SemiBold,
                                                color = MaterialTheme.colorScheme.onSurface
                                            )
                                            Text(
                                                text = if (slot.isPresent) stringResource(R.string.slotFilled, slot.timeStr ?: "") else stringResource(R.string.slotEmptySubtitle),
                                                style = MaterialTheme.typography.bodySmall,
                                                color = if (slot.isPresent) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                        }
                                        Icon(
                                            imageVector = if (isSave) Icons.Outlined.Save else Icons.Outlined.Download,
                                            contentDescription = null,
                                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                            modifier = Modifier.size(18.dp)
                                        )
                                    }
                                }
                            }
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // 4. External file action button (Clean, No Emojis)
            Button(
                onClick = {
                    onDismiss()
                    activity.startReadOrWriteSave(if (isSave) GameActivity.SAVE else GameActivity.LOAD)
                },
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer,
                    contentColor = MaterialTheme.colorScheme.onSecondaryContainer
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(44.dp)
            ) {
                Icon(
                    imageVector = if (isSave) Icons.Outlined.Save else Icons.Outlined.FileUpload,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (isSave) stringResource(R.string.saveTo) else stringResource(R.string.loadFrom),
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}
