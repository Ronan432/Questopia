package org.qp.android.ui.stock

import android.os.Build
import android.view.HapticFeedbackConstants
import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.BlurredEdgeTreatment
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.getValue
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CloudDownload
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SportsEsports
import androidx.compose.material.icons.outlined.CloudDownload
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.SportsEsports
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarDefaults
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.preference.PreferenceManager
import org.qp.android.R

import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.ui.platform.LocalDensity

import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.outlined.Home
import androidx.compose.foundation.layout.RowScope

enum class StockNavigationTab {
    GAMES,
    REPOSITORY,
    SETTINGS
}

data class ExpressiveNavItem(
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
    val label: String,
    val contentDescription: String? = null,
    val showBadge: Boolean = false
)

data class NavThemeColors(
    val navBarColor: Color,
    val indicatorColor: Color,
    val selectedIconColor: Color,
    val unselectedIconColor: Color,
    val selectedTextColor: Color,
    val unselectedTextColor: Color,
    val isAmoled: Boolean
)

@Composable
fun rememberNavThemeColors(): NavThemeColors {
    val context = LocalContext.current
    val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
    var themeMode by remember { mutableStateOf(prefs.getString("themeMode", "system") ?: "system") }
    var themeColor by remember { mutableStateOf(prefs.getString("themeColor", "monochrome") ?: "monochrome") }

    DisposableEffect(prefs) {
        val listener = android.content.SharedPreferences.OnSharedPreferenceChangeListener { sp, key ->
            when (key) {
                "themeMode" -> themeMode = sp.getString("themeMode", "system") ?: "system"
                "themeColor" -> themeColor = sp.getString("themeColor", "monochrome") ?: "monochrome"
            }
        }
        prefs.registerOnSharedPreferenceChangeListener(listener)
        onDispose {
            prefs.unregisterOnSharedPreferenceChangeListener(listener)
        }
    }

    val isAmoled = themeMode == "amoled" || themeMode == "3"
    val isMonochrome = themeColor == "monochrome"

    val navBarColor = when {
        isAmoled -> Color.Black
        else -> MaterialTheme.colorScheme.surfaceContainer
    }

    val indicatorColor = when {
        isAmoled -> Color(0xFF2C2C2C)
        isMonochrome -> MaterialTheme.colorScheme.primary.copy(alpha = 0.22f)
        else -> MaterialTheme.colorScheme.secondaryContainer
    }

    val selectedIconColor = when {
        isAmoled -> Color.White
        isMonochrome -> MaterialTheme.colorScheme.primary
        else -> MaterialTheme.colorScheme.onSecondaryContainer
    }

    val selectedTextColor = when {
        isAmoled -> Color.White
        isMonochrome -> MaterialTheme.colorScheme.primary
        else -> MaterialTheme.colorScheme.onSurface
    }

    val unselectedColor = MaterialTheme.colorScheme.onSurfaceVariant

    return NavThemeColors(
        navBarColor = navBarColor,
        indicatorColor = indicatorColor,
        selectedIconColor = selectedIconColor,
        unselectedIconColor = unselectedColor,
        selectedTextColor = selectedTextColor,
        unselectedTextColor = unselectedColor,
        isAmoled = isAmoled
    )
}

@Composable
fun RowScope.MaterialYouNavigationItem(
    selected: Boolean,
    onClick: () -> Unit,
    icon: @Composable () -> Unit,
    label: (@Composable () -> Unit)? = null,
    indicatorColor: Color
) {
    val view = LocalView.current
    val indicatorWidth by animateDpAsState(
        targetValue = if (selected) 56.dp else 0.dp,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "indicatorWidth"
    )

    Box(
        modifier = Modifier
            .weight(1f)
            .fillMaxHeight()
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null
            ) {
                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                onClick()
            },
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Box(
                modifier = Modifier
                    .height(32.dp)
                    .width(56.dp),
                contentAlignment = Alignment.Center
            ) {
                if (selected) {
                    Box(
                        modifier = Modifier
                            .width(indicatorWidth)
                            .height(32.dp)
                            .clip(CircleShape)
                            .background(indicatorColor)
                    )
                }
                Box(contentAlignment = Alignment.Center) {
                    icon()
                }
            }
            if (label != null) {
                Spacer(modifier = Modifier.height(4.dp))
                label()
            }
        }
    }
}

@Composable
fun FlexibleNavigationBar(
    currentTab: StockNavigationTab,
    onTabSelected: (StockNavigationTab) -> Unit,
    modifier: Modifier = Modifier
) {
    val navColors = rememberNavThemeColors()

    val navItems = listOf(
        ExpressiveNavItem(
            selectedIcon = Icons.Filled.Home,
            unselectedIcon = Icons.Outlined.Home,
            label = stringResource(R.string.nav_home)
        ),
        ExpressiveNavItem(
            selectedIcon = Icons.Filled.CloudDownload,
            unselectedIcon = Icons.Outlined.CloudDownload,
            label = stringResource(R.string.tabOneName)
        ),
        ExpressiveNavItem(
            selectedIcon = Icons.Filled.Settings,
            unselectedIcon = Icons.Outlined.Settings,
            label = stringResource(R.string.settingsTitle)
        )
    )

    val selectedIndex = when (currentTab) {
        StockNavigationTab.GAMES -> 0
        StockNavigationTab.REPOSITORY -> 1
        StockNavigationTab.SETTINGS -> 2
    }

    Surface(
        modifier = modifier.fillMaxWidth(),
        color = navColors.navBarColor,
        tonalElevation = if (navColors.isAmoled) 0.dp else 2.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .windowInsetsPadding(NavigationBarDefaults.windowInsets)
                .height(54.dp)
                .padding(horizontal = 8.dp),
            horizontalArrangement = Arrangement.SpaceAround,
            verticalAlignment = Alignment.CenterVertically
        ) {
            navItems.forEachIndexed { index, item ->
                val isSelected = index == selectedIndex
                MaterialYouNavigationItem(
                    selected = isSelected,
                    onClick = {
                        val newTab = when (index) {
                            0 -> StockNavigationTab.GAMES
                            1 -> StockNavigationTab.REPOSITORY
                            else -> StockNavigationTab.SETTINGS
                        }
                        onTabSelected(newTab)
                    },
                    icon = {
                        BadgedBox(
                            badge = {
                                if (item.showBadge) {
                                    Badge()
                                }
                            }
                        ) {
                            Icon(
                                imageVector = if (isSelected) item.selectedIcon else item.unselectedIcon,
                                contentDescription = item.contentDescription ?: item.label,
                                tint = if (isSelected) navColors.selectedIconColor else navColors.unselectedIconColor,
                                modifier = Modifier.size(24.dp)
                            )
                        }
                    },
                    label = null,
                    indicatorColor = navColors.indicatorColor
                )
            }
        }
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

