package org.qp.desktop.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuOpen
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.qp.desktop.model.DesktopGameItem
import org.qp.desktop.ui.common.DesktopMorphingSurface

enum class DesktopScreen(val title: String, val icon: ImageVector, val selectedIcon: ImageVector) {
    LIBRARY("Oyunlar", Icons.Outlined.SportsEsports, Icons.Filled.SportsEsports),
    STOCK("Katalog", Icons.Outlined.CloudDownload, Icons.Filled.CloudDownload),
    SETTINGS("Ayarlar", Icons.Outlined.Settings, Icons.Filled.Settings),
    PLAYING("Oyun Ekranı", Icons.Outlined.PlayCircleOutline, Icons.Filled.PlayCircle)
}

@Composable
fun DesktopNavigationRail(
    currentScreen: DesktopScreen,
    onScreenSelected: (DesktopScreen) -> Unit,
    games: List<DesktopGameItem>,
    activeGameId: String?,
    onDirectPlayGame: (DesktopGameItem) -> Unit,
    isExpanded: Boolean,
    onToggleExpand: () -> Unit,
    modifier: Modifier = Modifier
) {
    val railWidth by animateDpAsState(
        targetValue = if (isExpanded) 240.dp else 76.dp,
        animationSpec = spring(stiffness = 400f),
        label = "railWidth"
    )

    Surface(
        modifier = modifier.width(railWidth).fillMaxHeight(),
        color = MaterialTheme.colorScheme.surfaceContainer,
        tonalElevation = 1.dp
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = if (isExpanded) 14.dp else 10.dp, vertical = 18.dp),
            horizontalAlignment = if (isExpanded) Alignment.Start else Alignment.CenterHorizontally
        ) {
            // App Brand Header (Official App Logo + Title without subtitle)
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 6.dp)
            ) {
                org.qp.desktop.ui.common.DesktopAppLogo(size = 44.dp)

                if (isExpanded) {
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "Questopia",
                        style = MaterialTheme.typography.titleMedium.copy(
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 0.5.sp
                        ),
                        color = MaterialTheme.colorScheme.onSurface,
                        maxLines = 1
                    )
                }
            }

            Spacer(modifier = Modifier.height(18.dp))
            HorizontalDivider(
                color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f),
                modifier = Modifier.padding(horizontal = 2.dp)
            )
            Spacer(modifier = Modifier.height(14.dp))

            // Main 3 Navigation Items: Oyunlar, Katalog, Ayarlar
            val mainTabs = listOf(DesktopScreen.LIBRARY, DesktopScreen.STOCK, DesktopScreen.SETTINGS)

            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                mainTabs.forEach { screen ->
                    val isSelected = currentScreen == screen

                    val containerColor by animateColorAsState(
                        if (isSelected) MaterialTheme.colorScheme.primaryContainer
                        else Color.Transparent,
                        label = "mainNavBg"
                    )

                    val contentColor by animateColorAsState(
                        if (isSelected) MaterialTheme.colorScheme.onPrimaryContainer
                        else MaterialTheme.colorScheme.onSurfaceVariant,
                        label = "mainNavText"
                    )

                    DesktopMorphingSurface(
                        onClick = { onScreenSelected(screen) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp),
                        shape = CircleShape,
                        color = containerColor
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(horizontal = if (isExpanded) 14.dp else 12.dp),
                            horizontalArrangement = if (isExpanded) Arrangement.Start else Arrangement.Center
                        ) {
                            Icon(
                                imageVector = if (isSelected) screen.selectedIcon else screen.icon,
                                contentDescription = screen.title,
                                tint = contentColor,
                                modifier = Modifier.size(22.dp)
                            )
                            if (isExpanded) {
                                Spacer(modifier = Modifier.width(12.dp))
                                Text(
                                    text = screen.title,
                                    style = MaterialTheme.typography.labelLarge.copy(
                                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                                    ),
                                    color = contentColor,
                                    maxLines = 1
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            HorizontalDivider(
                color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f),
                modifier = Modifier.padding(horizontal = 2.dp)
            )
            Spacer(modifier = Modifier.height(12.dp))

            // Lower Section: Son Oyunlar / Tüm Eklenen Oyunlar (Direct 1-Click Launcher)
            if (isExpanded) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 4.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Son Oyunlar",
                        style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = "${games.size}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.outline
                    )
                }
            }

            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier.weight(1f).fillMaxWidth()
            ) {
                if (games.isEmpty()) {
                    if (isExpanded) {
                        item {
                            Text(
                                text = "Eklenmiş oyun yok",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.outline,
                                modifier = Modifier.padding(8.dp)
                            )
                        }
                    }
                } else {
                    items(games, key = { it.id }) { game ->
                        val isPlayingThis = currentScreen == DesktopScreen.PLAYING && activeGameId == game.id

                        DesktopMorphingSurface(
                            onClick = { onDirectPlayGame(game) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(44.dp),
                            shape = CircleShape,
                            color = if (isPlayingThis) MaterialTheme.colorScheme.secondaryContainer else Color.Transparent
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier
                                    .fillMaxSize()
                                    .padding(horizontal = if (isExpanded) 10.dp else 12.dp),
                                horizontalArrangement = if (isExpanded) Arrangement.Start else Arrangement.Center
                            ) {
                                Surface(
                                    shape = CircleShape,
                                    color = if (isPlayingThis) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceContainerHigh,
                                    modifier = Modifier.size(28.dp)
                                ) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Icon(
                                            imageVector = if (isPlayingThis) Icons.Filled.PlayArrow else Icons.Filled.SportsEsports,
                                            contentDescription = null,
                                            tint = if (isPlayingThis) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }
                                }

                                if (isExpanded) {
                                    Spacer(modifier = Modifier.width(10.dp))
                                    Text(
                                        text = game.title,
                                        style = MaterialTheme.typography.bodySmall.copy(
                                            fontWeight = if (isPlayingThis) FontWeight.Bold else FontWeight.Normal
                                        ),
                                        color = if (isPlayingThis) MaterialTheme.colorScheme.onSecondaryContainer else MaterialTheme.colorScheme.onSurface,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis,
                                        modifier = Modifier.weight(1f)
                                    )

                                    if (isPlayingThis) {
                                        Box(
                                            modifier = Modifier
                                                .size(8.dp)
                                                .clip(CircleShape)
                                                .background(MaterialTheme.colorScheme.primary)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Collapse / Expand Bar
            HorizontalDivider(
                color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f),
                modifier = Modifier.padding(horizontal = 2.dp)
            )
            Spacer(modifier = Modifier.height(10.dp))

            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(44.dp)
                    .clip(CircleShape)
                    .clickable { onToggleExpand() },
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                shape = CircleShape
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = if (isExpanded) Arrangement.SpaceBetween else Arrangement.Center
                ) {
                    Icon(
                        imageVector = if (isExpanded) Icons.AutoMirrored.Filled.MenuOpen else Icons.Filled.Menu,
                        contentDescription = "Menüyü Daralt/Genişlet",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(22.dp)
                    )

                    if (isExpanded) {
                        Text(
                            text = "Menüyü Daralt",
                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Medium),
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}
