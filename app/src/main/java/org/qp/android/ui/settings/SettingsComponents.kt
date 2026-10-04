package org.qp.android.ui.settings
import androidx.compose.runtime.setValue

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandHorizontally
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkHorizontally
import android.view.HapticFeedbackConstants
import org.qp.android.ui.common.CustomDrawerHandle
import org.qp.android.ui.common.MorphingDialogButton
import org.qp.android.ui.common.MorphingSurface
import org.qp.android.ui.common.getGroupedItemShape
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.Brightness4
import androidx.compose.material.icons.outlined.LightMode
import androidx.compose.material.icons.outlined.DarkMode
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.ui.platform.LocalContext
import androidx.preference.PreferenceManager
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.qp.android.BuildConfig
import org.qp.android.R

import org.qp.android.ui.common.ExpressiveSearchBar

val Icons.AutoMirrored.Outlined.ChevronLeft: ImageVector
    get() = Icons.AutoMirrored.Outlined.KeyboardArrowLeft

val Icons.AutoMirrored.Outlined.ChevronRight: ImageVector
    get() = Icons.AutoMirrored.Outlined.KeyboardArrowRight


@Composable
fun SwiftSectionHeader(
    title: String,
    modifier: Modifier = Modifier.padding(start = 12.dp, top = 12.dp, bottom = 6.dp)
) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.primary,
        modifier = modifier
    )
}

/**
 * Material 3 Expressive grouped settings container matching the screenshot.
 * Each item receives its specific shape according to its position in the list.
 */
@Composable
fun ExpressiveSettingsGroup(
    modifier: Modifier = Modifier,
    items: List<@Composable (shape: Shape) -> Unit>
) {
    if (items.isEmpty()) return

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(3.dp)
    ) {
        val total = items.size
        items.forEachIndexed { index, item ->
            item(getGroupedItemShape(index, total))
        }
    }
}

@Composable
fun ExpressivePreferenceItem(
    title: String,
    subtitle: String? = null,
    icon: ImageVector? = null,
    iconBgColor: Color = MaterialTheme.colorScheme.primaryContainer,
    iconTint: Color = MaterialTheme.colorScheme.onPrimaryContainer,
    shape: Shape = RoundedCornerShape(16.dp),
    onClick: (() -> Unit)? = null,
    showChevron: Boolean = false,
    trailingContent: (@Composable () -> Unit)? = null
) {
    MorphingSurface(
        shape = shape,
        color = MaterialTheme.colorScheme.surfaceContainer,
        modifier = Modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = 56.dp),
        onClick = onClick
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (icon != null) {
                Surface(
                    shape = CircleShape,
                    color = iconBgColor,
                    modifier = Modifier.size(36.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = icon,
                            contentDescription = null,
                            tint = iconTint,
                            modifier = Modifier.size(19.dp)
                        )
                    }
                }
                Spacer(modifier = Modifier.width(12.dp))
            }

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge.copy(
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold
                    ),
                    color = MaterialTheme.colorScheme.onSurface
                )
                if (!subtitle.isNullOrBlank()) {
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodySmall.copy(
                            fontSize = 12.5.sp
                        ),
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            if (trailingContent != null) {
                trailingContent()
            } else if (showChevron) {
                Spacer(modifier = Modifier.width(6.dp))
                Icon(
                    imageVector = Icons.AutoMirrored.Outlined.ChevronRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                    modifier = Modifier.size(18.dp)
                )
            }
        }
    }
}

@Composable
fun ExpressiveSwitchPreferenceItem(
    title: String,
    subtitle: String? = null,
    icon: ImageVector? = null,
    iconBgColor: Color = MaterialTheme.colorScheme.primaryContainer,
    iconTint: Color = MaterialTheme.colorScheme.onPrimaryContainer,
    shape: Shape = RoundedCornerShape(16.dp),
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    enabled: Boolean = true
) {
    val view = LocalView.current

    ExpressivePreferenceItem(
        title = title,
        subtitle = subtitle,
        icon = icon,
        iconBgColor = iconBgColor,
        iconTint = iconTint,
        shape = shape,
        onClick = if (enabled) {
            {
                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                onCheckedChange(!checked)
            }
        } else null,
        showChevron = false,
        trailingContent = {
            Switch(
                checked = checked,
                onCheckedChange = {
                    view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    onCheckedChange(it)
                },
                enabled = enabled,
                thumbContent = if (checked) {
                    {
                        Icon(
                            imageVector = Icons.Filled.Check,
                            contentDescription = null,
                            modifier = Modifier.size(SwitchDefaults.IconSize)
                        )
                    }
                } else {
                    {
                        Icon(
                            imageVector = Icons.Filled.Close,
                            contentDescription = null,
                            modifier = Modifier.size(SwitchDefaults.IconSize)
                        )
                    }
                }
            )
        }
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExpressiveListPreferenceItem(
    title: String,
    entries: List<String>,
    entryValues: List<String>,
    currentValue: String,
    onValueSelected: (String) -> Unit,
    icon: ImageVector? = null,
    iconBgColor: Color = MaterialTheme.colorScheme.primaryContainer,
    iconTint: Color = MaterialTheme.colorScheme.onPrimaryContainer,
    shape: Shape = RoundedCornerShape(16.dp)
) {
    var showSheet by remember { mutableStateOf(false) }
    val currentLabel = entries.getOrNull(entryValues.indexOf(currentValue)) ?: currentValue
    val view = LocalView.current
    val context = LocalContext.current

    ExpressivePreferenceItem(
        title = title,
        icon = icon,
        iconBgColor = iconBgColor,
        iconTint = iconTint,
        shape = shape,
        onClick = { showSheet = true },
        trailingContent = {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = currentLabel,
                    style = MaterialTheme.typography.bodyMedium.copy(
                        fontSize = 13.5.sp,
                        fontWeight = FontWeight.Medium
                    ),
                    color = MaterialTheme.colorScheme.primary,
                    maxLines = 1
                )
                Spacer(modifier = Modifier.width(4.dp))
                Icon(
                    imageVector = Icons.AutoMirrored.Outlined.ChevronRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                    modifier = Modifier.size(18.dp)
                )
            }
        }
    )

    if (showSheet) {
        val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
        val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
        val sheetBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow

        ModalBottomSheet(
            onDismissRequest = { showSheet = false },
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
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 8.dp)
                ) {
                    if (icon != null) {
                        Surface(
                            shape = CircleShape,
                            color = iconBgColor,
                            modifier = Modifier.size(36.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = icon,
                                    contentDescription = null,
                                    tint = iconTint,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                    }
                    Text(
                        text = title,
                        style = MaterialTheme.typography.titleMedium.copy(fontSize = 17.sp),
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }

                Spacer(modifier = Modifier.height(6.dp))

                // Options List
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(3.dp)
                ) {
                    entries.forEachIndexed { index, entry ->
                        val value = entryValues.getOrElse(index) { entry }
                        val isSelected = value == currentValue
                        val itemShape = getGroupedItemShape(
                            index = index,
                            total = entries.size,
                            outerRadius = 24.dp,
                            innerRadius = 4.dp
                        )

                        MorphingSurface(
                            shape = itemShape,
                            color = if (isSelected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainer,
                            onClick = {
                                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                onValueSelected(value)
                                showSheet = false
                            },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 16.dp, vertical = 13.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = entry,
                                    style = MaterialTheme.typography.bodyMedium.copy(
                                        fontSize = 15.sp,
                                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                                    ),
                                    color = if (isSelected) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurface,
                                    modifier = Modifier.weight(1f)
                                )

                                if (isSelected) {
                                    Icon(
                                        imageVector = Icons.Filled.Check,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Modern Material You Theme Mode Picker Sheet with visual tone cards (System, Light, Dark, AMOLED).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExpressiveThemeModePreferenceItem(
    title: String,
    currentValue: String,
    onValueSelected: (String) -> Unit,
    icon: ImageVector? = null,
    iconBgColor: Color = MaterialTheme.colorScheme.primaryContainer,
    iconTint: Color = MaterialTheme.colorScheme.onPrimaryContainer,
    shape: Shape = RoundedCornerShape(16.dp)
) {
    var showSheet by remember { mutableStateOf(false) }
    val view = LocalView.current
    val context = LocalContext.current

    val modes = listOf(
        Triple("system", stringResource(R.string.themeModeSystem), "Auto"),
        Triple("light", stringResource(R.string.themeModeLight), "Bright"),
        Triple("dark", stringResource(R.string.themeModeDark), "Muted"),
        Triple("amoled", stringResource(R.string.themeModeAmoled), "Pure 0% Black")
    )

    val currentLabel = when (currentValue.lowercase()) {
        "0", "system" -> stringResource(R.string.themeModeSystem)
        "1", "light" -> stringResource(R.string.themeModeLight)
        "2", "dark" -> stringResource(R.string.themeModeDark)
        "3", "amoled" -> stringResource(R.string.themeModeAmoled)
        else -> currentValue
    }

    ExpressivePreferenceItem(
        title = title,
        icon = icon,
        iconBgColor = iconBgColor,
        iconTint = iconTint,
        shape = shape,
        onClick = { showSheet = true },
        trailingContent = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = currentLabel,
                    style = MaterialTheme.typography.bodyMedium.copy(
                        fontSize = 13.5.sp,
                        fontWeight = FontWeight.Medium
                    ),
                    color = MaterialTheme.colorScheme.primary,
                    maxLines = 1
                )
                Spacer(modifier = Modifier.width(4.dp))
                Icon(
                    imageVector = Icons.AutoMirrored.Outlined.ChevronRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                    modifier = Modifier.size(18.dp)
                )
            }
        }
    )

    if (showSheet) {
        val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
        val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
        val sheetBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow

        ModalBottomSheet(
            onDismissRequest = { showSheet = false },
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
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 8.dp)
                ) {
                    if (icon != null) {
                        Surface(
                            shape = CircleShape,
                            color = iconBgColor,
                            modifier = Modifier.size(36.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = icon,
                                    contentDescription = null,
                                    tint = iconTint,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                    }
                    Text(
                        text = title,
                        style = MaterialTheme.typography.titleMedium.copy(fontSize = 17.sp),
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    modes.forEachIndexed { index, (modeKey, modeTitle, subtitle) ->
                        val isSelected = currentValue.equals(modeKey, ignoreCase = true) ||
                                (modeKey == "system" && (currentValue == "0" || currentValue.isBlank())) ||
                                (modeKey == "light" && currentValue == "1") ||
                                (modeKey == "dark" && currentValue == "2") ||
                                (modeKey == "amoled" && currentValue == "3")

                        val itemShape = getGroupedItemShape(
                            index = index,
                            total = modes.size,
                            outerRadius = 24.dp,
                            innerRadius = 4.dp
                        )

                        MorphingSurface(
                            shape = itemShape,
                            color = if (isSelected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainer,
                            onClick = {
                                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                onValueSelected(modeKey)
                                showSheet = false
                            },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 16.dp, vertical = 12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                // Visual Mode Preview Badge
                                val previewBg = when (modeKey) {
                                    "light" -> Color(0xFFF8F9FA)
                                    "dark" -> Color(0xFF1E1E1E)
                                    "amoled" -> Color(0xFF000000)
                                    else -> MaterialTheme.colorScheme.surfaceVariant
                                }
                                val previewBorder = when (modeKey) {
                                    "amoled" -> BorderStroke(1.dp, Color(0xFF333333))
                                    "light" -> BorderStroke(1.dp, Color(0xFFE0E0E0))
                                    else -> null
                                }

                                Surface(
                                    shape = CircleShape,
                                    color = previewBg,
                                    border = previewBorder,
                                    modifier = Modifier.size(34.dp)
                                ) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Icon(
                                            imageVector = when (modeKey) {
                                                "light" -> Icons.Outlined.Brightness4
                                                "dark" -> Icons.Outlined.Brightness4
                                                "amoled" -> Icons.Outlined.Brightness4
                                                else -> Icons.Outlined.Brightness4
                                            },
                                            contentDescription = null,
                                            tint = when (modeKey) {
                                                "light" -> Color(0xFF202124)
                                                "dark" -> Color(0xFFE8EAED)
                                                "amoled" -> Color(0xFFFFFFFF)
                                                else -> MaterialTheme.colorScheme.onSurfaceVariant
                                            },
                                            modifier = Modifier.size(17.dp)
                                        )
                                    }
                                }

                                Spacer(modifier = Modifier.width(14.dp))

                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = modeTitle,
                                        style = MaterialTheme.typography.bodyMedium.copy(
                                            fontSize = 15.sp,
                                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                                        ),
                                        color = if (isSelected) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurface
                                    )
                                    Text(
                                        text = subtitle,
                                        style = MaterialTheme.typography.bodySmall.copy(fontSize = 12.sp),
                                        color = if (isSelected) MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f) else MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }

                                if (isSelected) {
                                    Icon(
                                        imageVector = Icons.Filled.Check,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Modern Material You Dynamic Color Accent Palette Picker with interactive tonal swatches.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExpressiveThemeColorPreferenceItem(
    title: String,
    currentValue: String,
    onValueSelected: (String) -> Unit,
    icon: ImageVector? = null,
    iconBgColor: Color = MaterialTheme.colorScheme.primaryContainer,
    iconTint: Color = MaterialTheme.colorScheme.onPrimaryContainer,
    shape: Shape = RoundedCornerShape(16.dp)
) {
    var showSheet by remember { mutableStateOf(false) }
    val view = LocalView.current
    val context = LocalContext.current

    data class AccentOption(
        val key: String,
        val label: String,
        val primaryColor: Color,
        val containerColor: Color,
        val isDynamic: Boolean = false
    )

    val colorOptions = listOf(
        AccentOption("dynamic", stringResource(R.string.themeColorDynamic), MaterialTheme.colorScheme.primary, MaterialTheme.colorScheme.primaryContainer, isDynamic = true),
        AccentOption("blue", stringResource(R.string.themeColorBlue), Color(0xFF0061A4), Color(0xFFD1E4FF)),
        AccentOption("green", stringResource(R.string.themeColorGreen), Color(0xFF2E6A3E), Color(0xFFB0F2BA)),
        AccentOption("purple", stringResource(R.string.themeColorPurple), Color(0xFF7043A6), Color(0xFFEBDCFF)),
        AccentOption("orange", stringResource(R.string.themeColorOrange), Color(0xFF904A1D), Color(0xFFFFDCC5)),
        AccentOption("red", stringResource(R.string.themeColorRed), Color(0xFFBA1A1A), Color(0xFFFFDAD6)),
        AccentOption("pink", stringResource(R.string.themeColorPink), Color(0xFF8B4168), Color(0xFFFFD8E7)),
        AccentOption("teal", stringResource(R.string.themeColorTeal), Color(0xFF006A68), Color(0xFF70F7F3)),
        AccentOption("amber", stringResource(R.string.themeColorAmber), Color(0xFF745B00), Color(0xFFFFE08B)),
        AccentOption("monochrome", stringResource(R.string.themeColorMonochrome), Color(0xFF000000), Color(0xFFE2E2E2))
    )

    val currentAccent = colorOptions.firstOrNull { it.key.equals(currentValue, ignoreCase = true) } ?: colorOptions[0]

    ExpressivePreferenceItem(
        title = title,
        icon = icon,
        iconBgColor = iconBgColor,
        iconTint = iconTint,
        shape = shape,
        onClick = { showSheet = true },
        trailingContent = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Current color accent dot
                Surface(
                    shape = CircleShape,
                    color = currentAccent.primaryColor,
                    border = BorderStroke(1.5.dp, MaterialTheme.colorScheme.surface),
                    modifier = Modifier.size(20.dp)
                ) {}
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = currentAccent.label,
                    style = MaterialTheme.typography.bodyMedium.copy(
                        fontSize = 13.5.sp,
                        fontWeight = FontWeight.Medium
                    ),
                    color = MaterialTheme.colorScheme.primary,
                    maxLines = 1
                )
                Spacer(modifier = Modifier.width(4.dp))
                Icon(
                    imageVector = Icons.AutoMirrored.Outlined.ChevronRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                    modifier = Modifier.size(18.dp)
                )
            }
        }
    )

    if (showSheet) {
        val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
        val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
        val sheetBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow

        ModalBottomSheet(
            onDismissRequest = { showSheet = false },
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
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 8.dp)
                ) {
                    if (icon != null) {
                        Surface(
                            shape = CircleShape,
                            color = iconBgColor,
                            modifier = Modifier.size(36.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = icon,
                                    contentDescription = null,
                                    tint = iconTint,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                    }
                    Column {
                        Text(
                            text = title,
                            style = MaterialTheme.typography.titleMedium.copy(fontSize = 17.sp),
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = stringResource(R.string.themeColorTitle),
                            style = MaterialTheme.typography.bodySmall.copy(fontSize = 12.sp),
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    colorOptions.forEachIndexed { index, option ->
                        val isSelected = option.key.equals(currentValue, ignoreCase = true)
                        val itemShape = getGroupedItemShape(
                            index = index,
                            total = colorOptions.size,
                            outerRadius = 24.dp,
                            innerRadius = 4.dp
                        )

                        MorphingSurface(
                            shape = itemShape,
                            color = if (isSelected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainer,
                            onClick = {
                                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                onValueSelected(option.key)
                                showSheet = false
                            },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 16.dp, vertical = 12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                // Dual-tone Material You Color Palette Swatch
                                Box(
                                    modifier = Modifier
                                        .size(34.dp)
                                        .clip(CircleShape)
                                        .background(option.containerColor),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(20.dp)
                                            .clip(CircleShape)
                                            .background(option.primaryColor)
                                    )
                                }

                                Spacer(modifier = Modifier.width(14.dp))

                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = option.label,
                                        style = MaterialTheme.typography.bodyMedium.copy(
                                            fontSize = 15.sp,
                                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                                        ),
                                        color = if (isSelected) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurface
                                    )
                                    if (option.isDynamic) {
                                        Text(
                                            text = "Material You Wallpaper Tones",
                                            style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.5.sp),
                                            color = if (isSelected) MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f) else MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }

                                if (isSelected) {
                                    Icon(
                                        imageVector = Icons.Filled.Check,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


@Composable
fun ExpressiveColorPreferenceItem(
    title: String,
    subtitle: String? = null,
    color: Int,
    onColorSelected: (Int) -> Unit,
    icon: ImageVector? = null,
    iconBgColor: Color = MaterialTheme.colorScheme.primaryContainer,
    iconTint: Color = MaterialTheme.colorScheme.onPrimaryContainer,
    shape: Shape = RoundedCornerShape(16.dp)
) {
    var showDialog by remember { mutableStateOf(false) }
    val view = LocalView.current

    ExpressivePreferenceItem(
        title = title,
        subtitle = subtitle,
        icon = icon,
        iconBgColor = iconBgColor,
        iconTint = iconTint,
        shape = shape,
        onClick = { showDialog = true },
        showChevron = false,
        trailingContent = {
            Surface(
                shape = CircleShape,
                color = Color(color),
                border = BorderStroke(1.5.dp, MaterialTheme.colorScheme.outlineVariant),
                modifier = Modifier.size(22.dp)
            ) {}
        }
    )

    if (showDialog) {
        val presetColors = listOf(
            0xFF000000.toInt(),
            0xFFFFFFFF.toInt(),
            0xFF1976D2.toInt(),
            0xFF388E3C.toInt(),
            0xFFD32F2F.toInt(),
            0xFFF57C00.toInt(),
            0xFF7B1FA2.toInt(),
            0xFF00796B.toInt(),
            0xFF5D4037.toInt(),
            0xFF455A64.toInt(),
            0xFFE91E63.toInt(),
            0xFFFFD700.toInt()
        )

        val context = LocalContext.current
        val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
        val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
        val dialogBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow

        AlertDialog(
            onDismissRequest = { showDialog = false },
            containerColor = dialogBg,
            title = { Text(title, fontWeight = FontWeight.Bold) },
            text = {
                Column {
                    Text(
                        text = stringResource(R.string.themeColorTitle),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        presetColors.take(6).forEach { c ->
                            Surface(
                                shape = CircleShape,
                                color = Color(c),
                                border = BorderStroke(
                                    if (c == color) 3.dp else 1.dp,
                                    if (c == color) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant
                                ),
                                modifier = Modifier
                                    .size(36.dp)
                                    .clip(CircleShape)
                                    .clickable {
                                        view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                        onColorSelected(c)
                                        showDialog = false
                                    }
                            ) {}
                        }
                    }
                    Spacer(modifier = Modifier.height(12.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        presetColors.drop(6).take(6).forEach { c ->
                            Surface(
                                shape = CircleShape,
                                color = Color(c),
                                border = BorderStroke(
                                    if (c == color) 3.dp else 1.dp,
                                    if (c == color) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant
                                ),
                                modifier = Modifier
                                    .size(36.dp)
                                    .clip(CircleShape)
                                    .clickable {
                                        view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                        onColorSelected(c)
                                        showDialog = false
                                    }
                            ) {}
                        }
                    }
                }
            },
            confirmButton = {
                MorphingDialogButton(
                    isOutlined = true,
                    onClick = { showDialog = false }
                ) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }
}

@Composable
fun ExpressiveInfoDialog(
    title: String,
    onDismiss: () -> Unit,
    content: @Composable ColumnScope.() -> Unit
) {
    val context = LocalContext.current
    val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
    val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
    val dialogBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = dialogBg,
        title = { Text(title, fontWeight = FontWeight.Bold) },
        text = {
            Column(modifier = Modifier.fillMaxWidth()) {
                content()
            }
        },
        confirmButton = {
            MorphingDialogButton(onClick = onDismiss) {
                Text(stringResource(R.string.ok))
            }
        }
    )
}

@Composable
fun AboutDialog(onDismiss: () -> Unit) {
    ExpressiveInfoDialog(
        title = stringResource(R.string.aboutTitle),
        onDismiss = onDismiss
    ) {
        Text(
            text = stringResource(R.string.appName),
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.primary,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = stringResource(R.string.versionInfoTitle) + ": ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = stringResource(R.string.aboutDescription),
            style = MaterialTheme.typography.bodyMedium
        )
    }
}

@Composable
fun VersionDialog(onDismiss: () -> Unit) {
    ExpressiveInfoDialog(
        title = stringResource(R.string.versionInfoTitle),
        onDismiss = onDismiss
    ) {
        Text(
            text = stringResource(R.string.buildInformation),
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.primary,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = stringResource(R.string.buildDetails, BuildConfig.VERSION_NAME, BuildConfig.VERSION_CODE, BuildConfig.APPLICATION_ID),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
