package org.qp.android.ui.game

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ExitToApp
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.preference.PreferenceManager
import org.qp.android.R
import org.qp.android.ui.common.CustomDrawerHandle
import org.qp.android.ui.common.MorphingSurface
import org.qp.android.ui.common.getGroupedItemShape
import org.qp.android.ui.settings.SettingsActivity

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InGameOptionsMenuSheet(
    activity: GameActivity,
    viewModel: GameViewModel,
    onSaveClick: () -> Unit,
    onLoadClick: () -> Unit,
    onCheatsClick: () -> Unit,
    onRestartClick: () -> Unit,
    onExitRequested: () -> Unit,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
    val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
    val menuSheetBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = menuSheetBg,
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
                text = stringResource(R.string.gameMenuTitle),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(horizontal = 4.dp, vertical = 8.dp)
            )

            // Group 1: Kayıt ve Yükleme (Save & Load)
            ExpressiveMenuGroup(
                items = listOf(
                    { shape ->
                        ExpressiveMenuItem(
                            icon = Icons.Outlined.Save,
                            title = stringResource(R.string.saveTitle),
                            shape = shape,
                            onClick = onSaveClick
                        )
                    },
                    { shape ->
                        ExpressiveMenuItem(
                            icon = Icons.Outlined.FolderOpen,
                            title = stringResource(R.string.loadTitle),
                            shape = shape,
                            onClick = onLoadClick
                        )
                    }
                )
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Group 2: Hile Modları & Kullanıcı Girdisi (Cheat Modes & User Input)
            val isCheatsEnabled = prefs.getBoolean("enableCheats", false)
            val group2Items = mutableListOf<@Composable (shape: Shape) -> Unit>()

            if (isCheatsEnabled) {
                group2Items.add { shape ->
                    ExpressiveMenuItem(
                        icon = Icons.Outlined.Code,
                        title = stringResource(R.string.cheatModesTitle),
                        shape = shape,
                        onClick = onCheatsClick
                    )
                }
            }

            group2Items.add { shape ->
                ExpressiveMenuItem(
                    icon = Icons.Outlined.Keyboard,
                    title = stringResource(R.string.userInputTitle),
                    shape = shape,
                    onClick = {
                        onDismiss()
                        val settings = viewModel.settingsController
                        if (settings.isUseExecString) {
                            viewModel.requestForNativeLib(GameLibRequest.USE_EXECUTOR)
                        } else {
                            viewModel.requestForNativeLib(GameLibRequest.USE_INPUT)
                        }
                    }
                )
            }

            ExpressiveMenuGroup(items = group2Items)

            Spacer(modifier = Modifier.height(8.dp))

            // Group 3: Ayarlar, Oyunu Yeniden Başlat & Oyunu Kapat
            ExpressiveMenuGroup(
                items = listOf(
                    { shape ->
                        ExpressiveMenuItem(
                            icon = Icons.Outlined.Settings,
                            title = stringResource(R.string.settingsTitle),
                            shape = shape,
                            onClick = {
                                onDismiss()
                                context.startActivity(Intent(context, SettingsActivity::class.java))
                            }
                        )
                    },
                    { shape ->
                        ExpressiveMenuItem(
                            icon = Icons.Outlined.Refresh,
                            title = stringResource(R.string.restartGameTitle),
                            shape = shape,
                            onClick = onRestartClick
                        )
                    },
                    { shape ->
                        ExpressiveMenuItem(
                            icon = Icons.AutoMirrored.Outlined.ExitToApp,
                            title = stringResource(R.string.closeGameTitle),
                            shape = shape,
                            onClick = onExitRequested
                        )
                    }
                )
            )
        }
    }
}

@Composable
fun ExpressiveMenuGroup(
    modifier: Modifier = Modifier,
    items: List<@Composable (shape: Shape) -> Unit>
) {
    if (items.isEmpty()) return
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        val total = items.size
        for (index in 0 until total) {
            val shape = getGroupedItemShape(index, total, outerRadius = 24.dp, innerRadius = 4.dp)
            items[index](shape)
        }
    }
}

@Composable
fun ExpressiveMenuItem(
    icon: ImageVector,
    title: String,
    shape: Shape,
    subtitle: String? = null,
    onClick: () -> Unit
) {
    val itemBg = MaterialTheme.colorScheme.surfaceContainer
    val iconBg = MaterialTheme.colorScheme.surfaceContainerHigh

    MorphingSurface(
        shape = shape,
        color = itemBg,
        pressedRadius = 28.dp,
        onClick = onClick,
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
                    .background(iconBg),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(17.dp)
                )
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyMedium.copy(fontSize = 14.sp),
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                if (!subtitle.isNullOrBlank()) {
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}
