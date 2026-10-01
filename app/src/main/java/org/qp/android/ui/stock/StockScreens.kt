package org.qp.android.ui.stock

import android.view.HapticFeedbackConstants
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandHorizontally
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.shrinkHorizontally
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import androidx.compose.ui.graphics.SolidColor
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.preference.PreferenceManager
import org.qp.android.R
import org.qp.android.dto.stock.GameData
import org.qp.android.ui.settings.ExpressiveSearchBar
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
    var currentNavTab by remember { mutableStateOf(StockNavigationTab.GAMES) }
    var searchQuery by remember { mutableStateOf("") }
    var isSearchActive by remember { mutableStateOf(false) }
    var isSearchFocused by remember { mutableStateOf(false) }
    var showExitDialog by remember { mutableStateOf(false) }

    val focusManager = LocalFocusManager.current
    val view = LocalView.current

    BackHandler(enabled = currentNavTab != StockNavigationTab.GAMES) {
        currentNavTab = StockNavigationTab.GAMES
    }

    BackHandler(enabled = currentNavTab == StockNavigationTab.GAMES) {
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
        containerColor = MaterialTheme.colorScheme.background,
        bottomBar = {
            val navColors = rememberNavThemeColors()
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(navColors.navBarColor)
                    .navigationBarsPadding(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                FlexibleNavigationBar(
                    currentTab = currentNavTab,
                    onTabSelected = { currentNavTab = it }
                )
            }
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
            AnimatedContent(
                targetState = currentNavTab,
                transitionSpec = {
                    (slideInHorizontally(
                        initialOffsetX = { (it * 0.18f).toInt() },
                        animationSpec = tween(durationMillis = 280, easing = FastOutSlowInEasing)
                    ) + fadeIn(animationSpec = tween(durationMillis = 250, easing = FastOutSlowInEasing)))
                        .togetherWith(
                            slideOutHorizontally(
                                targetOffsetX = { -(it * 0.18f).toInt() },
                                animationSpec = tween(durationMillis = 220, easing = FastOutSlowInEasing)
                            ) + fadeOut(animationSpec = tween(durationMillis = 180, easing = FastOutSlowInEasing))
                        )
                },
                label = "navTabTransition"
            ) { targetTab ->
                when (targetTab) {
                    StockNavigationTab.GAMES -> {
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

                            // Top Row: Search Bar + Far Right Small (+) Add Game Button
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                ExpressiveSearchBar(
                                    query = searchQuery,
                                    onQueryChange = { searchQuery = it },
                                    placeholderText = stringResource(R.string.searchGamesPlaceholder),
                                    modifier = Modifier.weight(1f),
                                    isFocused = isSearchFocused,
                                    onFocusChanged = { isSearchFocused = it },
                                    onSearch = { focusManager.clearFocus() }
                                )
                                Spacer(modifier = Modifier.width(10.dp))

                                val addInteractionSource = remember { MutableInteractionSource() }
                                val isAddPressed by addInteractionSource.collectIsPressedAsState()
                                val addCornerRadius by animateDpAsState(
                                    targetValue = if (isAddPressed) 12.dp else 23.dp,
                                    animationSpec = spring(
                                        dampingRatio = Spring.DampingRatioMediumBouncy,
                                        stiffness = Spring.StiffnessMediumLow
                                    ),
                                    label = "addMorphRadius"
                                )

                                Surface(
                                    shape = RoundedCornerShape(addCornerRadius),
                                    color = MaterialTheme.colorScheme.primaryContainer,
                                    tonalElevation = 2.dp,
                                    modifier = Modifier
                                        .size(46.dp)
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
                                            contentDescription = stringResource(R.string.addGameContentDescription),
                                            tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                            modifier = Modifier.size(22.dp)
                                        )
                                    }
                                }
                            }

                            val filteredLocalGames = remember(localGames, searchQuery) {
                                if (searchQuery.isBlank()) localGames
                                else localGames.filter {
                                    (it.title ?: "").contains(searchQuery, ignoreCase = true) ||
                                            (it.author ?: "").contains(searchQuery, ignoreCase = true)
                                }
                            }

                            var isPullRefreshing by remember { mutableStateOf(false) }
                            LaunchedEffect(isLoading) {
                                if (!isLoading) {
                                    isPullRefreshing = false
                                }
                            }

                            PullToRefreshBox(
                                isRefreshing = isPullRefreshing || isLoading,
                                onRefresh = {
                                    isPullRefreshing = true
                                    onRefreshLocal()
                                },
                                modifier = Modifier.fillMaxSize()
                            ) {
                                InstalledGamesList(
                                    games = filteredLocalGames,
                                    onPlayGame = onPlayGame,
                                    onEditGame = onEditGame,
                                    onDeleteGame = onDeleteGame,
                                    contentPadding = PaddingValues(top = 8.dp, bottom = 80.dp, start = 16.dp, end = 16.dp)
                                )
                            }
                        }
                    }

                    StockNavigationTab.REPOSITORY -> {
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

                            // Top Search Bar ONLY (No + button on repository)
                            ExpressiveSearchBar(
                                query = searchQuery,
                                onQueryChange = { searchQuery = it },
                                placeholderText = stringResource(R.string.searchGamesPlaceholder),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 4.dp),
                                isFocused = isSearchFocused,
                                onFocusChanged = { isSearchFocused = it },
                                onSearch = { focusManager.clearFocus() }
                            )

                            val filteredRemoteGames = remember(remoteGames, searchQuery) {
                                if (searchQuery.isBlank()) remoteGames
                                else remoteGames.filter {
                                    (it.title ?: "").contains(searchQuery, ignoreCase = true) ||
                                            (it.author ?: "").contains(searchQuery, ignoreCase = true)
                                }
                            }

                            var isPullRefreshing by remember { mutableStateOf(false) }
                            LaunchedEffect(isLoading) {
                                if (!isLoading) {
                                    isPullRefreshing = false
                                }
                            }

                            LaunchedEffect(Unit) {
                                if (remoteGames.isEmpty()) {
                                    onRefreshRemote()
                                }
                            }

                            PullToRefreshBox(
                                isRefreshing = isPullRefreshing || isLoading,
                                onRefresh = {
                                    isPullRefreshing = true
                                    onRefreshRemote()
                                },
                                modifier = Modifier.fillMaxSize()
                            ) {
                                RemoteGamesList(
                                    games = filteredRemoteGames,
                                    isLoading = isLoading,
                                    onDownloadGame = onDownloadGame,
                                    onRefresh = onRefreshRemote,
                                    contentPadding = PaddingValues(top = 8.dp, bottom = 80.dp, start = 16.dp, end = 16.dp)
                                )
                            }
                        }
                    }

                    StockNavigationTab.SETTINGS -> {
                        SettingsApp(
                            onFinish = { currentNavTab = StockNavigationTab.GAMES },
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
