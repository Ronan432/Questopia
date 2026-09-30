package org.qp.android.ui.stock

import android.view.HapticFeedbackConstants
import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CloudDownload
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SportsEsports
import androidx.compose.material.icons.outlined.CloudDownload
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.SportsEsports
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.preference.PreferenceManager
import org.qp.android.R

enum class StockNavigationTab {
    GAMES,
    SETTINGS
}

@Composable
fun FlexibleNavItem(
    selected: Boolean,
    onClick: () -> Unit,
    icon: ImageVector,
    selectedIcon: ImageVector,
    label: String,
    modifier: Modifier = Modifier
) {
    val view = LocalView.current
    val context = LocalContext.current
    val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
    val themeColor = prefs.getString("themeColor", "monochrome") ?: "monochrome"
    val isMonochrome = themeColor == "monochrome"

    val activePillColor = if (isMonochrome) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.primaryContainer
    val activeIconColor = if (isMonochrome) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onPrimaryContainer

    val pillColor by animateColorAsState(
        targetValue = if (selected) activePillColor else Color.Transparent,
        animationSpec = tween(durationMillis = 280),
        label = "navPillColor"
    )
    val pillWidthHorizontal by animateDpAsState(
        targetValue = if (selected) 22.dp else 6.dp,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioLowBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "navPillWidth"
    )
    val iconColor by animateColorAsState(
        targetValue = if (selected) activeIconColor else MaterialTheme.colorScheme.onSurfaceVariant,
        animationSpec = tween(durationMillis = 280),
        label = "navIconColor"
    )
    val textColor by animateColorAsState(
        targetValue = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
        animationSpec = tween(durationMillis = 280),
        label = "navTextColor"
    )

    Column(
        modifier = modifier
            .fillMaxHeight()
            .clip(RoundedCornerShape(20.dp))
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = {
                    view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    onClick()
                }
            ),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Box(
            modifier = Modifier
                .clip(CircleShape)
                .background(pillColor)
                .padding(horizontal = pillWidthHorizontal, vertical = 5.dp),
            contentAlignment = Alignment.Center
        ) {
            Crossfade(
                targetState = selected,
                animationSpec = tween(durationMillis = 320),
                label = "navIconCrossfade"
            ) { isSelected ->
                Icon(
                    imageVector = if (isSelected) selectedIcon else icon,
                    contentDescription = label,
                    tint = iconColor,
                    modifier = Modifier.size(24.dp)
                )
            }
        }
        Spacer(modifier = Modifier.height(3.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
            color = textColor
        )
    }
}

@Composable
fun FlexibleNavigationBar(
    currentTab: StockNavigationTab,
    onTabSelected: (StockNavigationTab) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val view = LocalView.current
    val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
    val themeMode = prefs.getString("themeMode", "system") ?: "system"
    val themeColor = prefs.getString("themeColor", "monochrome") ?: "monochrome"
    val isAmoled = themeMode == "amoled"
    val isMonochrome = themeColor == "monochrome"
    
    val navBarColor = if (isAmoled) Color.Black else MaterialTheme.colorScheme.surfaceContainer
    val indicatorColor = if (isMonochrome) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.primaryContainer
    val selectedIconColor = if (isMonochrome) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onPrimaryContainer

    NavigationBar(
        containerColor = navBarColor,
        tonalElevation = if (isAmoled) 0.dp else 6.dp,
        modifier = modifier.fillMaxWidth()
    ) {
        val gamesSelected = currentTab == StockNavigationTab.GAMES
        val settingsSelected = currentTab == StockNavigationTab.SETTINGS

        NavigationBarItem(
            selected = gamesSelected,
            onClick = {
                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                onTabSelected(StockNavigationTab.GAMES)
            },
            icon = {
                Icon(
                    imageVector = if (gamesSelected) Icons.Filled.Home else Icons.Outlined.Home,
                    contentDescription = stringResource(R.string.nav_home)
                )
            },
            label = { Text(stringResource(R.string.nav_home)) },
            colors = NavigationBarItemDefaults.colors(
                indicatorColor = indicatorColor,
                selectedIconColor = selectedIconColor,
                selectedTextColor = MaterialTheme.colorScheme.primary,
                unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant
            )
        )

        NavigationBarItem(
            selected = settingsSelected,
            onClick = {
                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                onTabSelected(StockNavigationTab.SETTINGS)
            },
            icon = {
                Icon(
                    imageVector = if (settingsSelected) Icons.Filled.Settings else Icons.Outlined.Settings,
                    contentDescription = stringResource(R.string.settingsTitle)
                )
            },
            label = { Text(stringResource(R.string.settingsTitle)) },
            colors = NavigationBarItemDefaults.colors(
                indicatorColor = indicatorColor,
                selectedIconColor = selectedIconColor,
                selectedTextColor = MaterialTheme.colorScheme.primary,
                unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant
            )
        )
    }
}

@Composable
fun StockSegmentedControl(
    selectedTab: Int,
    onTabSelected: (Int) -> Unit,
    localCount: Int,
    remoteCount: Int,
    onAddGameClicked: () -> Unit,
    modifier: Modifier = Modifier
) {
    val view = LocalView.current

    Surface(
        shape = RoundedCornerShape(28.dp),
        color = MaterialTheme.colorScheme.surfaceContainerHigh,
        tonalElevation = 6.dp,
        shadowElevation = 4.dp,
        border = BorderStroke(1.2.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)),
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp)
            .height(54.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(4.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            val isTab0 = selectedTab == 0
            val tab0Bg by animateColorAsState(
                targetValue = if (isTab0) MaterialTheme.colorScheme.primaryContainer else Color.Transparent,
                animationSpec = tween(durationMillis = 240),
                label = "tab0Bg"
            )
            val tab0Text by animateColorAsState(
                targetValue = if (isTab0) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant,
                animationSpec = tween(durationMillis = 240),
                label = "tab0Text"
            )

            // Left Tab: Oyunlar
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(22.dp))
                    .background(tab0Bg)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                        onClick = {
                            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                            onTabSelected(0)
                        }
                    ),
                contentAlignment = Alignment.Center
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center,
                    modifier = Modifier.padding(horizontal = 8.dp)
                ) {
                    Icon(
                        imageVector = if (isTab0) Icons.Filled.SportsEsports else Icons.Outlined.SportsEsports,
                        contentDescription = null,
                        tint = tab0Text,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "${stringResource(R.string.tabZeroName)} ($localCount)",
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = if (isTab0) FontWeight.Bold else FontWeight.Medium,
                        color = tab0Text,
                        maxLines = 1
                    )
                }
            }

            Spacer(modifier = Modifier.width(4.dp))

            // Center Unified Add (+) Action Pill
            Surface(
                shape = CircleShape,
                color = MaterialTheme.colorScheme.primary,
                shadowElevation = 2.dp,
                modifier = Modifier
                    .size(42.dp)
                    .clip(CircleShape)
                    .clickable(
                        onClick = {
                            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                            onAddGameClicked()
                        }
                    )
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = stringResource(R.string.btnAddGame),
                        tint = MaterialTheme.colorScheme.onPrimary,
                        modifier = Modifier.size(22.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.width(4.dp))

            val isTab1 = selectedTab == 1
            val tab1Bg by animateColorAsState(
                targetValue = if (isTab1) MaterialTheme.colorScheme.primaryContainer else Color.Transparent,
                animationSpec = tween(durationMillis = 240),
                label = "tab1Bg"
            )
            val tab1Text by animateColorAsState(
                targetValue = if (isTab1) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant,
                animationSpec = tween(durationMillis = 240),
                label = "tab1Text"
            )

            // Right Tab: Oyun Deposu
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(22.dp))
                    .background(tab1Bg)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                        onClick = {
                            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                            onTabSelected(1)
                        }
                    ),
                contentAlignment = Alignment.Center
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center,
                    modifier = Modifier.padding(horizontal = 8.dp)
                ) {
                    Icon(
                        imageVector = if (isTab1) Icons.Filled.CloudDownload else Icons.Outlined.CloudDownload,
                        contentDescription = null,
                        tint = tab1Text,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "${stringResource(R.string.tabOneName)} ($remoteCount)",
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = if (isTab1) FontWeight.Bold else FontWeight.Medium,
                        color = tab1Text,
                        maxLines = 1
                    )
                }
            }
        }
    }
}

