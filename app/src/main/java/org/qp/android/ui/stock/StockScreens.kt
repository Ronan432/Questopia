package org.qp.android.ui.stock
import androidx.compose.runtime.setValue

import android.view.HapticFeedbackConstants
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandHorizontally
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkHorizontally
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Sort
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.Storage
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import org.qp.android.R
import org.qp.android.dto.stock.GameData
import org.qp.android.ui.common.ExpressiveSearchBar
import org.qp.android.ui.settings.SettingsApp

enum class HomeFilter {
    ALL,
    FAVORITES
}

enum class HomeSortOrder {
    NAME_ASC,
    SIZE_DESC,
    DATE_DESC
}

@Composable
private fun StatMetric(
    value: String,
    label: String,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
        modifier = modifier
    ) {
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium.copy(
                fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                fontSize = 15.sp
            ),
            color = MaterialTheme.colorScheme.primary,
            maxLines = 1
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall.copy(
                fontSize = 11.sp,
                fontWeight = androidx.compose.ui.text.font.FontWeight.Medium
            ),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StockMainScreen(
    localGames: List<GameData>,
    remoteGames: List<GameData>,
    isLoading: Boolean,
    onPlayGame: (GameData) -> Unit,
    onEditGame: (GameData) -> Unit,
    onDeleteGame: (GameData) -> Unit,
    onDownloadGame: (GameData) -> Unit,
    onAddGameClicked: () -> Unit,
    onExitApp: () -> Unit,
    onToggleFavorite: (GameData) -> Unit = {},
    onRefreshLocal: () -> Unit = {},
    onRefreshRemote: () -> Unit = {}
) {
    val pagerState = rememberPagerState(initialPage = 0) { 3 }
    val coroutineScope = rememberCoroutineScope()

    var searchQuery by remember { mutableStateOf("") }
    var isSearchActive by remember { mutableStateOf(false) }
    var isSearchFocused by remember { mutableStateOf(false) }
    var showExitDialog by remember { mutableStateOf(false) }
    var selectedHomeFilter by remember { mutableStateOf(HomeFilter.ALL) }

    val focusManager = LocalFocusManager.current
    val keyboardController = LocalSoftwareKeyboardController.current
    val view = LocalView.current

    val hideKeyboard = {
        focusManager.clearFocus()
        keyboardController?.hide()
    }

    val currentNavTab = when (pagerState.currentPage) {
        0 -> StockNavigationTab.GAMES
        1 -> StockNavigationTab.REPOSITORY
        else -> StockNavigationTab.SETTINGS
    }

    BackHandler(enabled = pagerState.currentPage != 0) {
        coroutineScope.launch {
            pagerState.scrollToPage(0)
        }
    }

    BackHandler(enabled = pagerState.currentPage == 0) {
        if (isSearchActive || searchQuery.isNotEmpty()) {
            isSearchActive = false
            searchQuery = ""
            focusManager.clearFocus()
        } else {
            showExitDialog = true
        }
    }

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        containerColor = MaterialTheme.colorScheme.surface,
        bottomBar = {
            FlexibleNavigationBar(
                currentTab = currentNavTab,
                onTabSelected = { targetTab ->
                    coroutineScope.launch {
                        pagerState.scrollToPage(targetTab.ordinal)
                    }
                }
            )
        }
    ) { _ ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .pointerInput(Unit) {
                    detectTapGestures(onTap = {
                        focusManager.clearFocus()
                    })
                }
        ) {
            HorizontalPager(
                state = pagerState,
                modifier = Modifier.fillMaxSize()
            ) { page ->
                when (page) {
                    0 -> {
                        // GAMES TAB
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .statusBarsPadding()
                        ) {
                            AnimatedVisibility(
                                visible = isLoading,
                                enter = fadeIn(),
                                exit = fadeOut()
                            ) {
                                LinearProgressIndicator(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(4.dp)
                                )
                            }

                            val totalSizeBytes = remember(localGames) {
                                localGames.filter { it.fileSize > 0 }.sumOf { it.fileSize }
                            }
                            val totalFormattedSize = remember(totalSizeBytes) {
                                if (totalSizeBytes > 0) org.qp.android.helpers.utils.FileUtil.formatFileSize(totalSizeBytes, 1000) else "0 B"
                            }
                            val favCount = remember(localGames) {
                                localGames.count { it.isFavorite }
                            }

                            var selectedSortOrder by remember { mutableStateOf(HomeSortOrder.NAME_ASC) }
                            var showSortMenu by remember { mutableStateOf(false) }

                            val filteredLocalGames = remember(localGames, searchQuery, selectedHomeFilter, selectedSortOrder) {
                                val base = if (selectedHomeFilter == HomeFilter.FAVORITES) {
                                    localGames.filter { it.isFavorite }
                                } else {
                                    localGames
                                }
                                val searched = if (searchQuery.isBlank()) base
                                else base.filter {
                                    (it.title ?: "").contains(searchQuery, ignoreCase = true) ||
                                            (it.author ?: "").contains(searchQuery, ignoreCase = true)
                                }
                                when (selectedSortOrder) {
                                    HomeSortOrder.NAME_ASC -> searched.sortedBy { (it.title ?: "").lowercase(java.util.Locale.ROOT) }
                                    HomeSortOrder.SIZE_DESC -> searched.sortedByDescending { it.fileSize }
                                    HomeSortOrder.DATE_DESC -> searched.sortedByDescending { it.id }
                                }
                            }

                            var isLocalPullRefreshing by remember { mutableStateOf(false) }

                            PullToRefreshBox(
                                isRefreshing = isLocalPullRefreshing,
                                onRefresh = {
                                    coroutineScope.launch {
                                        isLocalPullRefreshing = true
                                        onRefreshLocal()
                                        kotlinx.coroutines.delay(600)
                                        isLocalPullRefreshing = false
                                    }
                                },
                                modifier = Modifier.fillMaxSize()
                            ) {
                                InstalledGamesList(
                                    games = filteredLocalGames,
                                    onPlayGame = onPlayGame,
                                    onEditGame = onEditGame,
                                    onDeleteGame = onDeleteGame,
                                    onToggleFavorite = onToggleFavorite,
                                    headerContent = {
                                        Column(
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .padding(top = 4.dp, bottom = 4.dp),
                                            verticalArrangement = Arrangement.spacedBy(8.dp)
                                        ) {
                                            // Top Search + Add Button Row
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                ExpressiveSearchBar(
                                                    query = searchQuery,
                                                    onQueryChange = { searchQuery = it },
                                                    placeholderText = stringResource(R.string.searchGamesPlaceholder),
                                                    modifier = Modifier.weight(1f),
                                                    isFocused = isSearchFocused,
                                                    onFocusChanged = { isSearchFocused = it },
                                                    onSearch = { hideKeyboard() },
                                                    onCancel = {
                                                        isSearchFocused = false
                                                        searchQuery = ""
                                                        hideKeyboard()
                                                    },
                                                    showCancelButton = true
                                                )

                                                AnimatedVisibility(
                                                    visible = !isSearchFocused && searchQuery.isEmpty(),
                                                    enter = fadeIn(animationSpec = tween(durationMillis = 180)) +
                                                            expandHorizontally(
                                                                animationSpec = spring(
                                                                    dampingRatio = Spring.DampingRatioNoBouncy,
                                                                    stiffness = Spring.StiffnessMediumLow
                                                                )
                                                            ),
                                                    exit = fadeOut(animationSpec = tween(durationMillis = 120)) +
                                                            shrinkHorizontally(
                                                                animationSpec = spring(
                                                                    dampingRatio = Spring.DampingRatioNoBouncy,
                                                                    stiffness = Spring.StiffnessMediumLow
                                                                )
                                                            )
                                                ) {
                                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                                        Spacer(modifier = Modifier.width(10.dp))
                                                        val addInteractionSource = remember { MutableInteractionSource() }
                                                        val isAddPressed by addInteractionSource.collectIsPressedAsState()
                                                        val addCornerRadius by animateDpAsState(
                                                            targetValue = if (isAddPressed) 12.dp else 24.dp,
                                                            animationSpec = spring(
                                                                dampingRatio = Spring.DampingRatioNoBouncy,
                                                                stiffness = Spring.StiffnessMediumLow
                                                            ),
                                                            label = "addMorphRadius"
                                                        )

                                                        Surface(
                                                            shape = RoundedCornerShape(addCornerRadius),
                                                            color = MaterialTheme.colorScheme.surfaceContainerHigh,
                                                            tonalElevation = 2.dp,
                                                            modifier = Modifier
                                                                .size(48.dp)
                                                                .clip(RoundedCornerShape(addCornerRadius))
                                                                .clickable(
                                                                    interactionSource = addInteractionSource,
                                                                    indication = null,
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
                                                                    tint = MaterialTheme.colorScheme.primary,
                                                                    modifier = Modifier.size(24.dp)
                                                                )
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // Mini Stats Bar (Clean, typographic and sleek)
                                            if (localGames.isNotEmpty() && !isSearchFocused && searchQuery.isEmpty()) {
                                                Surface(
                                                    shape = RoundedCornerShape(16.dp),
                                                    color = MaterialTheme.colorScheme.surfaceContainerHigh,
                                                    modifier = Modifier.fillMaxWidth()
                                                ) {
                                                    Row(
                                                        modifier = Modifier
                                                            .fillMaxWidth()
                                                            .padding(vertical = 12.dp, horizontal = 8.dp),
                                                        horizontalArrangement = Arrangement.SpaceEvenly,
                                                        verticalAlignment = Alignment.CenterVertically
                                                    ) {
                                                        StatMetric(
                                                            value = "${localGames.size}",
                                                            label = stringResource(R.string.statLibrary),
                                                            modifier = Modifier.weight(1f)
                                                        )
                                                        Box(
                                                            modifier = Modifier
                                                                .width(1.dp)
                                                                .height(26.dp)
                                                                .background(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.25f))
                                                        )
                                                        StatMetric(
                                                            value = totalFormattedSize,
                                                            label = stringResource(R.string.statSize),
                                                            modifier = Modifier.weight(1f)
                                                        )
                                                        Box(
                                                            modifier = Modifier
                                                                .width(1.dp)
                                                                .height(26.dp)
                                                                .background(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.25f))
                                                        )
                                                        StatMetric(
                                                            value = "$favCount",
                                                            label = stringResource(R.string.statFavorites),
                                                            modifier = Modifier.weight(1f)
                                                        )
                                                    }
                                                }
                                            }

                                            // Filter Chips (All / Favorites) & Sort Control
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                // 1. "All" button
                                                val isAllSelected = selectedHomeFilter == HomeFilter.ALL
                                                val allInteractionSource = remember { MutableInteractionSource() }
                                                val isAllPressed by allInteractionSource.collectIsPressedAsState()
                                                val allRadius by animateDpAsState(
                                                    targetValue = if (isAllPressed) 10.dp else 16.dp,
                                                    animationSpec = spring(
                                                        dampingRatio = Spring.DampingRatioNoBouncy,
                                                        stiffness = Spring.StiffnessMediumLow
                                                    ),
                                                    label = "allRadius"
                                                )
                                                Surface(
                                                    shape = RoundedCornerShape(allRadius),
                                                    color = if (isAllSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceContainerHigh,
                                                    modifier = Modifier
                                                        .weight(1f)
                                                        .height(38.dp)
                                                        .clip(RoundedCornerShape(allRadius))
                                                        .clickable(
                                                            interactionSource = allInteractionSource,
                                                            indication = null
                                                        ) {
                                                            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                                            selectedHomeFilter = HomeFilter.ALL
                                                        }
                                                ) {
                                                    Box(
                                                        modifier = Modifier.fillMaxSize(),
                                                        contentAlignment = Alignment.Center
                                                    ) {
                                                        Text(
                                                            text = "${stringResource(R.string.filterHomeAll)} (${localGames.size})",
                                                            style = MaterialTheme.typography.labelMedium.copy(
                                                                fontWeight = if (isAllSelected) androidx.compose.ui.text.font.FontWeight.Bold else androidx.compose.ui.text.font.FontWeight.SemiBold,
                                                                fontSize = 12.sp
                                                            ),
                                                            color = if (isAllSelected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface,
                                                            maxLines = 1
                                                        )
                                                    }
                                                }

                                                // 2. "Favorites" button
                                                val isFavSelected = selectedHomeFilter == HomeFilter.FAVORITES
                                                val favInteractionSource = remember { MutableInteractionSource() }
                                                val isFavPressed by favInteractionSource.collectIsPressedAsState()
                                                val favRadius by animateDpAsState(
                                                    targetValue = if (isFavPressed) 10.dp else 16.dp,
                                                    animationSpec = spring(
                                                        dampingRatio = Spring.DampingRatioNoBouncy,
                                                        stiffness = Spring.StiffnessMediumLow
                                                    ),
                                                    label = "favRadius"
                                                )
                                                Surface(
                                                    shape = RoundedCornerShape(favRadius),
                                                    color = if (isFavSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceContainerHigh,
                                                    modifier = Modifier
                                                        .weight(1f)
                                                        .height(38.dp)
                                                        .clip(RoundedCornerShape(favRadius))
                                                        .clickable(
                                                            interactionSource = favInteractionSource,
                                                            indication = null
                                                        ) {
                                                            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                                            selectedHomeFilter = HomeFilter.FAVORITES
                                                        }
                                                ) {
                                                    Row(
                                                        modifier = Modifier
                                                            .fillMaxSize()
                                                            .padding(horizontal = 4.dp),
                                                        verticalAlignment = Alignment.CenterVertically,
                                                        horizontalArrangement = Arrangement.Center
                                                    ) {
                                                        Icon(
                                                            imageVector = if (isFavSelected) androidx.compose.material.icons.Icons.Filled.Favorite else androidx.compose.material.icons.Icons.Outlined.FavoriteBorder,
                                                            contentDescription = null,
                                                            tint = if (isFavSelected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.error,
                                                            modifier = Modifier.size(13.dp)
                                                        )
                                                        Spacer(modifier = Modifier.width(4.dp))
                                                        Text(
                                                            text = "${stringResource(R.string.filterFavorites)} ($favCount)",
                                                            style = MaterialTheme.typography.labelMedium.copy(
                                                                fontWeight = if (isFavSelected) androidx.compose.ui.text.font.FontWeight.Bold else androidx.compose.ui.text.font.FontWeight.SemiBold,
                                                                fontSize = 12.sp
                                                            ),
                                                            color = if (isFavSelected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface,
                                                            maxLines = 1
                                                        )
                                                    }
                                                }

                                                // 3. "Sort" button
                                                Box(
                                                    modifier = Modifier
                                                        .weight(1f)
                                                        .height(38.dp)
                                                ) {
                                                    val sortInteractionSource = remember { MutableInteractionSource() }
                                                    val isSortPressed by sortInteractionSource.collectIsPressedAsState()
                                                    val sortRadius by animateDpAsState(
                                                        targetValue = if (isSortPressed) 10.dp else 16.dp,
                                                        animationSpec = spring(
                                                            dampingRatio = Spring.DampingRatioNoBouncy,
                                                            stiffness = Spring.StiffnessMediumLow
                                                        ),
                                                        label = "sortRadius"
                                                    )
                                                    Surface(
                                                        shape = RoundedCornerShape(sortRadius),
                                                        color = MaterialTheme.colorScheme.surfaceContainerHigh,
                                                        modifier = Modifier
                                                            .fillMaxSize()
                                                            .clip(RoundedCornerShape(sortRadius))
                                                            .clickable(
                                                                interactionSource = sortInteractionSource,
                                                                indication = null
                                                            ) {
                                                                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                                                showSortMenu = true
                                                            }
                                                    ) {
                                                        Row(
                                                            modifier = Modifier
                                                                .fillMaxSize()
                                                                .padding(horizontal = 4.dp),
                                                            verticalAlignment = Alignment.CenterVertically,
                                                            horizontalArrangement = Arrangement.Center
                                                        ) {
                                                            Icon(
                                                                imageVector = androidx.compose.material.icons.Icons.AutoMirrored.Outlined.Sort,
                                                                contentDescription = stringResource(R.string.sortTitle),
                                                                tint = MaterialTheme.colorScheme.primary,
                                                                modifier = Modifier.size(15.dp)
                                                            )
                                                            Spacer(modifier = Modifier.width(4.dp))
                                                            Text(
                                                                text = when (selectedSortOrder) {
                                                                    HomeSortOrder.NAME_ASC -> stringResource(R.string.sortName)
                                                                    HomeSortOrder.SIZE_DESC -> stringResource(R.string.sortSize)
                                                                    HomeSortOrder.DATE_DESC -> stringResource(R.string.sortDate)
                                                                },
                                                                style = MaterialTheme.typography.labelMedium.copy(
                                                                    fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold,
                                                                    fontSize = 12.sp
                                                                ),
                                                                color = MaterialTheme.colorScheme.onSurface,
                                                                maxLines = 1
                                                            )
                                                        }
                                                    }

                                                    DropdownMenu(
                                                        expanded = showSortMenu,
                                                        onDismissRequest = { showSortMenu = false },
                                                        modifier = Modifier.background(MaterialTheme.colorScheme.surfaceContainerHigh)
                                                    ) {
                                                        DropdownMenuItem(
                                                            text = {
                                                                Text(
                                                                    stringResource(R.string.sortName),
                                                                    fontWeight = if (selectedSortOrder == HomeSortOrder.NAME_ASC) androidx.compose.ui.text.font.FontWeight.Bold else androidx.compose.ui.text.font.FontWeight.Normal
                                                                )
                                                            },
                                                            leadingIcon = {
                                                                if (selectedSortOrder == HomeSortOrder.NAME_ASC) {
                                                                    Icon(Icons.Default.Check, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(18.dp))
                                                                }
                                                            },
                                                            onClick = {
                                                                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                                                selectedSortOrder = HomeSortOrder.NAME_ASC
                                                                showSortMenu = false
                                                            }
                                                        )
                                                        DropdownMenuItem(
                                                            text = {
                                                                Text(
                                                                    stringResource(R.string.sortSize),
                                                                    fontWeight = if (selectedSortOrder == HomeSortOrder.SIZE_DESC) androidx.compose.ui.text.font.FontWeight.Bold else androidx.compose.ui.text.font.FontWeight.Normal
                                                                )
                                                            },
                                                            leadingIcon = {
                                                                if (selectedSortOrder == HomeSortOrder.SIZE_DESC) {
                                                                    Icon(Icons.Default.Check, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(18.dp))
                                                                }
                                                            },
                                                            onClick = {
                                                                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                                                selectedSortOrder = HomeSortOrder.SIZE_DESC
                                                                showSortMenu = false
                                                            }
                                                        )
                                                        DropdownMenuItem(
                                                            text = {
                                                                Text(
                                                                    stringResource(R.string.sortDate),
                                                                    fontWeight = if (selectedSortOrder == HomeSortOrder.DATE_DESC) androidx.compose.ui.text.font.FontWeight.Bold else androidx.compose.ui.text.font.FontWeight.Normal
                                                                )
                                                            },
                                                            leadingIcon = {
                                                                if (selectedSortOrder == HomeSortOrder.DATE_DESC) {
                                                                    Icon(Icons.Default.Check, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(18.dp))
                                                                }
                                                            },
                                                            onClick = {
                                                                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                                                selectedSortOrder = HomeSortOrder.DATE_DESC
                                                                showSortMenu = false
                                                            }
                                                        )
                                                    }
                                                }
                                            }
                                        }
                                    },
                                    contentPadding = PaddingValues(top = 4.dp, bottom = 96.dp, start = 16.dp, end = 16.dp)
                                )
                            }
                        }
                    }

                    1 -> {
                        // REPOSITORY TAB
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .statusBarsPadding()
                        ) {
                            AnimatedVisibility(
                                visible = isLoading,
                                enter = fadeIn(),
                                exit = fadeOut()
                            ) {
                                LinearProgressIndicator(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(4.dp)
                                )
                            }

                            val filteredRemoteGames = remember(remoteGames, searchQuery) {
                                if (searchQuery.isBlank()) remoteGames
                                else remoteGames.filter {
                                    (it.title ?: "").contains(searchQuery, ignoreCase = true) ||
                                            (it.author ?: "").contains(searchQuery, ignoreCase = true)
                                }
                            }

                            var isRemotePullRefreshing by remember { mutableStateOf(false) }

                            LaunchedEffect(Unit) {
                                if (remoteGames.isEmpty()) {
                                    onRefreshRemote()
                                }
                            }

                            PullToRefreshBox(
                                isRefreshing = isRemotePullRefreshing,
                                onRefresh = {
                                    coroutineScope.launch {
                                        isRemotePullRefreshing = true
                                        onRefreshRemote()
                                        kotlinx.coroutines.delay(800)
                                        isRemotePullRefreshing = false
                                    }
                                },
                                modifier = Modifier.fillMaxSize()
                            ) {
                                RemoteGamesList(
                                    games = filteredRemoteGames,
                                    isLoading = isLoading && remoteGames.isEmpty(),
                                    onDownloadGame = onDownloadGame,
                                    onRefresh = onRefreshRemote,
                                    headerContent = {
                                        ExpressiveSearchBar(
                                            query = searchQuery,
                                            onQueryChange = { searchQuery = it },
                                            placeholderText = stringResource(R.string.searchGamesPlaceholder),
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .padding(top = 4.dp, bottom = 4.dp),
                                            isFocused = isSearchFocused,
                                            onFocusChanged = { isSearchFocused = it },
                                            onSearch = { hideKeyboard() },
                                            onCancel = {
                                                isSearchFocused = false
                                                searchQuery = ""
                                                hideKeyboard()
                                            },
                                            showCancelButton = true
                                        )
                                    },
                                    contentPadding = PaddingValues(top = 4.dp, bottom = 96.dp, start = 16.dp, end = 16.dp)
                                )
                            }
                        }
                    }

                    2 -> {
                        // SETTINGS TAB
                        SettingsApp(
                            onFinish = {
                                coroutineScope.launch {
                                    pagerState.animateScrollToPage(0)
                                }
                            },
                            searchQuery = searchQuery,
                            isSearchActive = isSearchActive,
                            showBackButton = false,
                            onSearchQueryChange = { searchQuery = it }
                        )
                    }
                }
            }
        }
    }

    if (showExitDialog) {
        AlertDialog(
            onDismissRequest = { showExitDialog = false },
            title = { Text(stringResource(R.string.appName)) },
            text = { Text(stringResource(R.string.promptExitApp)) },
            confirmButton = {
                Button(
                    onClick = {
                        showExitDialog = false
                        onExitApp()
                    }
                ) {
                    Text(stringResource(R.string.yes))
                }
            },
            dismissButton = {
                TextButton(onClick = { showExitDialog = false }) {
                    Text(stringResource(R.string.no))
                }
            }
        )
    }
}
