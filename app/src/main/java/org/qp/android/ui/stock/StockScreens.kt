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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
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
    onRefreshLocal: () -> Unit = {},
    onRefreshRemote: () -> Unit = {}
) {
    val pagerState = rememberPagerState(initialPage = 0) { 3 }
    val coroutineScope = rememberCoroutineScope()

    var searchQuery by remember { mutableStateOf("") }
    var isSearchActive by remember { mutableStateOf(false) }
    var isSearchFocused by remember { mutableStateOf(false) }
    var showExitDialog by remember { mutableStateOf(false) }

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

                            val filteredLocalGames = remember(localGames, searchQuery) {
                                if (searchQuery.isBlank()) localGames
                                else localGames.filter {
                                    (it.title ?: "").contains(searchQuery, ignoreCase = true) ||
                                            (it.author ?: "").contains(searchQuery, ignoreCase = true)
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
                                    headerContent = {
                                        Row(
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .padding(top = 4.dp, bottom = 4.dp),
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
