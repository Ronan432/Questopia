package org.qp.android.ui.stock

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
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
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
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
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

enum class StockNavigationTab {
    GAMES,
    REPOSITORY,
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

data class ExpressiveNavItem(
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
    val label: String,
    val contentDescription: String? = null,
    val showBadge: Boolean = false
)

@Composable
fun AnimatedExpressiveNavigationBar(
    items: List<ExpressiveNavItem>,
    selectedIndex: Int,
    onTabSelected: (Int) -> Unit,
    modifier: Modifier = Modifier,
    navBarColor: Color = MaterialTheme.colorScheme.surfaceContainer,
    indicatorColor: Color = MaterialTheme.colorScheme.primaryContainer,
    selectedIconColor: Color = MaterialTheme.colorScheme.onPrimaryContainer,
    unselectedIconColor: Color = MaterialTheme.colorScheme.onSurfaceVariant,
    selectedTextColor: Color = MaterialTheme.colorScheme.onPrimaryContainer,
    unselectedTextColor: Color = MaterialTheme.colorScheme.onSurfaceVariant
) {
    if (items.isEmpty()) return
    val view = LocalView.current
    val hasLabels = remember(items) { items.any { it.label.isNotBlank() } }

    BoxWithConstraints(
        modifier = modifier
            .fillMaxWidth()
            .height(56.dp)
            .background(navBarColor)
    ) {
        val count = items.size
        val totalWidth = this.maxWidth
        val itemWidth = totalWidth / count

        // Calculate dynamic pill width for each tab based on its label length
        val itemPillWidths = remember(items, itemWidth) {
            items.map { item ->
                if (item.label.isBlank()) {
                    48.dp
                } else {
                    val estTextWidth = item.label.length * 7.2f
                    (20 + 6 + estTextWidth + 20).dp.coerceIn(72.dp, itemWidth - 6.dp)
                }
            }
        }

        val targetPillWidth = itemPillWidths.getOrElse(selectedIndex) { 80.dp }

        val animatedPillWidth by animateDpAsState(
            targetValue = targetPillWidth,
            animationSpec = spring(
                dampingRatio = 0.82f,
                stiffness = Spring.StiffnessMediumLow
            ),
            label = "navPillWidth"
        )

        val pillHeight = if (hasLabels) 34.dp else 30.dp

        val targetCenterX = itemWidth * selectedIndex + itemWidth / 2
        val targetLeft = targetCenterX - animatedPillWidth / 2

        val animatedLeft by animateDpAsState(
            targetValue = targetLeft,
            animationSpec = spring(
                dampingRatio = 0.82f,
                stiffness = Spring.StiffnessMediumLow
            ),
            label = "navIndicatorX"
        )

        val distanceToTarget = (animatedLeft - targetLeft).value.let { if (it < 0) -it else it }
        val isMoving = distanceToTarget > 1.5f

        val pillScaleX by animateFloatAsState(
            targetValue = if (isMoving) 1.08f else 1.0f,
            animationSpec = tween(180, easing = FastOutSlowInEasing),
            label = "pillScaleX"
        )
        val pillScaleY by animateFloatAsState(
            targetValue = if (isMoving) 0.92f else 1.0f,
            animationSpec = tween(180, easing = FastOutSlowInEasing),
            label = "pillScaleY"
        )

        // Single Shared Active Indicator Pill
        Box(
            modifier = Modifier
                .offset(x = animatedLeft, y = (56.dp - pillHeight) / 2)
                .width(animatedPillWidth)
                .height(pillHeight)
                .graphicsLayer {
                    scaleX = pillScaleX
                    scaleY = pillScaleY
                }
                .clip(CircleShape)
                .background(indicatorColor)
        )

        // Items Row
        Row(
            modifier = Modifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            items.forEachIndexed { index, item ->
                val isSelected = index == selectedIndex

                val iconScale by animateFloatAsState(
                    targetValue = if (isSelected) 1.0f else 0.92f,
                    animationSpec = spring(
                        dampingRatio = 0.8f,
                        stiffness = Spring.StiffnessMediumLow
                    ),
                    label = "iconScale"
                )

                val iconColor by animateColorAsState(
                    targetValue = if (isSelected) selectedIconColor else unselectedIconColor,
                    animationSpec = tween(250),
                    label = "iconColor"
                )

                val textColor by animateColorAsState(
                    targetValue = if (isSelected) selectedTextColor else unselectedTextColor,
                    animationSpec = tween(250),
                    label = "textColor"
                )

                val labelAlpha by animateFloatAsState(
                    targetValue = if (isSelected) 1.0f else 0.72f,
                    animationSpec = tween(250),
                    label = "labelAlpha"
                )

                val labelOffsetY by animateDpAsState(
                    targetValue = if (isSelected) 0.dp else 1.dp,
                    animationSpec = tween(250),
                    label = "labelOffsetY"
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
                            onTabSelected(index)
                        },
                    contentAlignment = Alignment.Center
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center
                    ) {
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
                                tint = iconColor,
                                modifier = Modifier
                                    .size(20.dp)
                                    .graphicsLayer {
                                        scaleX = iconScale
                                        scaleY = iconScale
                                    }
                            )
                        }
                        if (item.label.isNotBlank()) {
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = item.label,
                                style = MaterialTheme.typography.labelMedium.copy(
                                    fontSize = 11.5.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                                ),
                                color = textColor,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier
                                    .graphicsLayer { alpha = labelAlpha }
                                    .offset(y = labelOffsetY)
                            )
                        }
                    }
                }
            }
        }
    }
}

data class NavThemeColors(
    val navBarColor: Color,
    val indicatorColor: Color,
    val selectedIconColor: Color,
    val unselectedIconColor: Color,
    val selectedTextColor: Color,
    val unselectedTextColor: Color
)

@Composable
fun rememberNavThemeColors(): NavThemeColors {
    val context = LocalContext.current
    val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
    val themeMode = prefs.getString("themeMode", "system") ?: "system"
    val themeColor = prefs.getString("themeColor", "monochrome") ?: "monochrome"
    val isAmoled = themeMode == "amoled" || themeMode == "3"
    val isMonochrome = themeColor == "monochrome"

    val navBarColor = if (isAmoled) Color.Black else MaterialTheme.colorScheme.surfaceContainer
    val indicatorColor = if (isAmoled || isMonochrome) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.primaryContainer
    val selectedIconColor = if (isAmoled || isMonochrome) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onPrimaryContainer
    val unselectedColor = MaterialTheme.colorScheme.onSurfaceVariant

    return NavThemeColors(
        navBarColor = navBarColor,
        indicatorColor = indicatorColor,
        selectedIconColor = selectedIconColor,
        unselectedIconColor = unselectedColor,
        selectedTextColor = selectedIconColor,
        unselectedTextColor = unselectedColor
    )
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
            selectedIcon = Icons.Filled.SportsEsports,
            unselectedIcon = Icons.Outlined.SportsEsports,
            label = stringResource(R.string.tabZeroName)
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

    AnimatedExpressiveNavigationBar(
        items = navItems,
        selectedIndex = selectedIndex,
        onTabSelected = { idx ->
            val newTab = when (idx) {
                0 -> StockNavigationTab.GAMES
                1 -> StockNavigationTab.REPOSITORY
                else -> StockNavigationTab.SETTINGS
            }
            onTabSelected(newTab)
        },
        navBarColor = navColors.navBarColor,
        indicatorColor = navColors.indicatorColor,
        selectedIconColor = navColors.selectedIconColor,
        unselectedIconColor = navColors.unselectedIconColor,
        selectedTextColor = navColors.selectedTextColor,
        unselectedTextColor = navColors.unselectedTextColor,
        modifier = modifier
    )
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

