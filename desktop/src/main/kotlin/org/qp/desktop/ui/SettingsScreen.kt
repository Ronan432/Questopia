package org.qp.desktop.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.VolumeOff
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.qp.desktop.model.DesktopAppSettings
import org.qp.desktop.ui.common.DesktopMorphingSurface
import org.qp.desktop.ui.common.getGroupedItemShape

@Composable
fun SettingsScreen(
    settings: DesktopAppSettings,
    onSettingsChanged: (DesktopAppSettings) -> Unit,
    modifier: Modifier = Modifier
) {
    var showAboutDialog by remember { mutableStateOf(false) }

    if (showAboutDialog) {
        AlertDialog(
            onDismissRequest = { showAboutDialog = false },
            title = { Text("Questopia Hakkında", fontWeight = FontWeight.Bold) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Questopia Desktop v1.0.0", fontWeight = FontWeight.Bold)
                    Text("Modern Compose Multiplatform ve QSP Engine ile güçlendirilmiş interaktif metin macera oyunu oynatıcısı.")
                    Text("© 2026 Questopia Team")
                }
            },
            confirmButton = {
                Button(
                    onClick = { showAboutDialog = false },
                    shape = CircleShape
                ) {
                    Text("Kapat")
                }
            },
            shape = RoundedCornerShape(24.dp)
        )
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 28.dp, vertical = 24.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        Text(
            text = "Ayarlar",
            style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold),
            color = MaterialTheme.colorScheme.onSurface
        )

        // --- 1. APPEARANCE & THEME CARD (Light / Dark / AMOLED - No System) ---
        SectionHeader(title = "Görünüm ve Tema")

        DesktopThemeAppearanceCard(
            currentMode = settings.themeMode,
            currentColor = settings.themeColor,
            onModeSelected = { onSettingsChanged(settings.copy(themeMode = it)) },
            onColorSelected = { onSettingsChanged(settings.copy(themeColor = it)) }
        )

        // --- 2. GENERAL SETTINGS ---
        SectionHeader(title = "Genel")
        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
            DesktopSettingSwitchTile(
                title = "Otomatik Kaydırma",
                subtitle = "Yeni metinler geldikçe ekranı aşağı kaydır",
                checked = settings.autoscroll,
                onCheckedChange = { onSettingsChanged(settings.copy(autoscroll = it)) },
                icon = Icons.Outlined.VerticalAlignBottom,
                iconBg = Color(0xFFFF5722),
                shape = getGroupedItemShape(0, 2, outerRadius = 22.dp, innerRadius = 6.dp)
            )
            DesktopSettingSwitchTile(
                title = "Ayırıcı Çizgi",
                subtitle = "Metin blokları arasına görsel ayrım ekle",
                checked = settings.separator,
                onCheckedChange = { onSettingsChanged(settings.copy(separator = it)) },
                icon = Icons.Outlined.TableRows,
                iconBg = Color(0xFF3F51B5),
                shape = getGroupedItemShape(1, 2, outerRadius = 22.dp, innerRadius = 6.dp)
            )
        }

        // --- 3. TYPOGRAPHY & TEXT ---
        SectionHeader(title = "Yazı ve Tipografi")
        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
            DesktopSettingDropdownTile(
                title = "Yazı Boyutu",
                subtitle = "Oyun içi metin büyüklüğü",
                currentValue = "${settings.fontSize} sp",
                options = listOf("12", "14", "16", "18", "20", "24"),
                onSelect = { onSettingsChanged(settings.copy(fontSize = it)) },
                icon = Icons.Outlined.FormatSize,
                iconBg = Color(0xFF00ACC1),
                shape = getGroupedItemShape(0, 2, outerRadius = 22.dp, innerRadius = 6.dp)
            )
            DesktopSettingSwitchTile(
                title = "Oyun Yazı Tipini Kullan",
                subtitle = "Oyunun kendi belirlediği yazı fontunu önceliklendir",
                checked = settings.isUseGameFont,
                onCheckedChange = { onSettingsChanged(settings.copy(isUseGameFont = it)) },
                icon = Icons.Outlined.TextFields,
                iconBg = Color(0xFFFFA000),
                shape = getGroupedItemShape(1, 2, outerRadius = 22.dp, innerRadius = 6.dp)
            )
        }

        // --- 4. SOUND & MEDIA ---
        SectionHeader(title = "Ses ve Medya")
        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
            DesktopSettingSwitchTile(
                title = "Ses Efektlerini Çal",
                subtitle = "Oyun müzik ve ses efektlerini oynat",
                checked = settings.isAudioPlay,
                onCheckedChange = { onSettingsChanged(settings.copy(isAudioPlay = it)) },
                icon = Icons.AutoMirrored.Outlined.VolumeUp,
                iconBg = Color(0xFFE53935),
                shape = getGroupedItemShape(0, 2, outerRadius = 22.dp, innerRadius = 6.dp)
            )
            DesktopSettingSwitchTile(
                title = "Videoları Sessize Al",
                subtitle = "Oyun içi video içeriklerini sessiz başlat",
                checked = settings.isMuteVideo,
                onCheckedChange = { onSettingsChanged(settings.copy(isMuteVideo = it)) },
                icon = Icons.AutoMirrored.Outlined.VolumeOff,
                iconBg = Color(0xFF6D4C41),
                shape = getGroupedItemShape(1, 2, outerRadius = 22.dp, innerRadius = 6.dp)
            )
        }

        // --- 5. ABOUT ---
        SectionHeader(title = "Hakkında")
        DesktopMorphingSurface(
            onClick = { showAboutDialog = true },
            shape = RoundedCornerShape(22.dp),
            color = MaterialTheme.colorScheme.surfaceContainer
        ) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = CircleShape,
                    color = Color(0xFF1976D2),
                    modifier = Modifier.size(44.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Outlined.Info, contentDescription = null, tint = Color.White, modifier = Modifier.size(22.dp))
                    }
                }
                Spacer(Modifier.width(14.dp))
                Column(Modifier.weight(1f)) {
                    Text("Questopia Desktop v1.0.0", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Text("Sürüm bilgisi ve geliştiriciler", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline)
                }
                Icon(Icons.Outlined.ChevronRight, contentDescription = null, tint = MaterialTheme.colorScheme.outline)
            }
        }
    }
}

@Composable
fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold),
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(start = 6.dp, top = 6.dp)
    )
}

@Composable
fun DesktopThemeAppearanceCard(
    currentMode: String,
    currentColor: String,
    onModeSelected: (String) -> Unit,
    onColorSelected: (String) -> Unit
) {
    // Only 3 Modes: Light, Dark, AMOLED (System removed)
    val modes = listOf(
        Triple("light", "Aydınlık", Icons.Default.LightMode),
        Triple("dark", "Karanlık", Icons.Default.DarkMode),
        Triple("amoled", "AMOLED", Icons.Default.DarkMode)
    )

    val colorOptions = listOf(
        Pair("monochrome", Color(0xFFFFFFFF)),
        Pair("blue", Color(0xFF0061A4)),
        Pair("green", Color(0xFF2E6C38)),
        Pair("purple", Color(0xFF77539D)),
        Pair("orange", Color(0xFF924C00)),
        Pair("red", Color(0xFFB3261E)),
        Pair("pink", Color(0xFF9B4061)),
        Pair("teal", Color(0xFF006A6A)),
        Pair("amber", Color(0xFFFBBD00))
    )

    Surface(
        shape = RoundedCornerShape(24.dp),
        color = MaterialTheme.colorScheme.surfaceContainer,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            // Theme Mode Selector Cards (3 Segmented Cards)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                modes.forEach { (modeKey, modeTitle, icon) ->
                    val isSelected = currentMode == modeKey
                    val bgColor by animateColorAsState(
                        if (isSelected) MaterialTheme.colorScheme.primaryContainer
                        else MaterialTheme.colorScheme.surfaceContainerHigh,
                        label = "themeModeBg"
                    )
                    val contentColor by animateColorAsState(
                        if (isSelected) MaterialTheme.colorScheme.onPrimaryContainer
                        else MaterialTheme.colorScheme.onSurfaceVariant,
                        label = "themeModeText"
                    )

                    DesktopMorphingSurface(
                        onClick = { onModeSelected(modeKey) },
                        modifier = Modifier
                            .weight(1f)
                            .height(72.dp),
                        shape = RoundedCornerShape(18.dp),
                        color = bgColor
                    ) {
                        Column(
                            modifier = Modifier.fillMaxSize().padding(8.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            Surface(
                                shape = CircleShape,
                                color = if (isSelected) MaterialTheme.colorScheme.primary else Color.Transparent,
                                modifier = Modifier.size(32.dp)
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Icon(
                                        icon,
                                        contentDescription = modeTitle,
                                        tint = if (isSelected) MaterialTheme.colorScheme.onPrimary else contentColor,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            }
                            Spacer(Modifier.height(4.dp))
                            Text(
                                modeTitle,
                                style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                color = contentColor
                            )
                        }
                    }
                }
            }

            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f))

            // Color Accent Chips
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    "Vurgu Rengi",
                    style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.onSurface
                )

                Row(
                    modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    colorOptions.forEach { (colorKey, colorVal) ->
                        val isSelected = currentColor == colorKey
                        Surface(
                            modifier = Modifier
                                .size(44.dp)
                                .clip(CircleShape)
                                .clickable { onColorSelected(colorKey) },
                            color = colorVal,
                            shape = CircleShape,
                            border = if (isSelected) androidx.compose.foundation.BorderStroke(3.5.dp, MaterialTheme.colorScheme.primary) else null
                        ) {
                            if (isSelected) {
                                Box(contentAlignment = Alignment.Center) {
                                    Icon(
                                        Icons.Filled.Check,
                                        contentDescription = null,
                                        tint = if (colorKey == "monochrome") Color.Black else Color.White,
                                        modifier = Modifier.size(22.dp)
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
fun DesktopSettingSwitchTile(
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    icon: ImageVector,
    iconBg: Color,
    shape: androidx.compose.ui.graphics.Shape
) {
    DesktopMorphingSurface(
        onClick = { onCheckedChange(!checked) },
        shape = shape,
        color = MaterialTheme.colorScheme.surfaceContainer
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                shape = CircleShape,
                color = iconBg,
                modifier = Modifier.size(42.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(22.dp))
                }
            }
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.SemiBold))
                Text(subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline)
            }

            // Modern Expressive Switch with Check / Cross Ticks
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange,
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
    }
}

@Composable
fun DesktopSettingDropdownTile(
    title: String,
    subtitle: String,
    currentValue: String,
    options: List<String>,
    onSelect: (String) -> Unit,
    icon: ImageVector,
    iconBg: Color,
    shape: androidx.compose.ui.graphics.Shape
) {
    var expanded by remember { mutableStateOf(false) }

    DesktopMorphingSurface(
        onClick = { expanded = true },
        shape = shape,
        color = MaterialTheme.colorScheme.surfaceContainer
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                shape = CircleShape,
                color = iconBg,
                modifier = Modifier.size(42.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(22.dp))
                }
            }
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.SemiBold))
                Text(subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline)
            }

            Box {
                FilledTonalButton(
                    onClick = { expanded = true },
                    shape = CircleShape,
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
                ) {
                    Text(currentValue, style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold))
                }

                DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                    options.forEach { option ->
                        DropdownMenuItem(
                            text = { Text(option, fontWeight = if (option == currentValue.replace(" sp", "")) FontWeight.Bold else FontWeight.Normal) },
                            onClick = {
                                onSelect(option)
                                expanded = false
                            }
                        )
                    }
                }
            }
        }
    }
}
