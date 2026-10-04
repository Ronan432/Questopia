package org.qp.android.ui.game

import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.view.HapticFeedbackConstants
import android.view.KeyEvent
import androidx.activity.SystemBarStyle
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed as gridItemsIndexed
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModelProvider
import androidx.preference.PreferenceManager
import com.anggrayudi.storage.SimpleStorageHelper
import org.qp.android.helpers.utils.DirUtil
import com.anggrayudi.storage.file.DocumentFileCompat
import com.anggrayudi.storage.file.MimeType
import org.qp.android.R
import org.qp.android.helpers.ErrorType
import org.qp.android.helpers.utils.FileUtil.findOrCreateFile
import org.qp.android.helpers.utils.LocaleHelper
import org.qp.android.ui.common.MorphingButton
import org.qp.android.ui.common.MorphingOutlinedButton
import org.qp.android.ui.common.MorphingSurface
import org.qp.android.ui.common.getGroupedItemShape
import org.qp.android.ui.dialogs.GameDialogType
import org.qp.android.ui.stock.ExpressiveNavItem
import org.qp.android.ui.stock.MaterialYouNavigationItem
import org.qp.android.ui.stock.rememberNavThemeColors
import org.qp.android.ui.theme.QuestopiaTheme
import java.util.*
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ThreadLocalRandom

class GameActivity : AppCompatActivity() {

    internal fun frozenVariablesKey(): String {
        val file = intent.getStringExtra("gameFileUri") ?: intent.getStringExtra("gameDirUri") ?: "unknown"
        return "frozenVariables_" + file.hashCode()
    }

    companion object {
        const val TAB_MAIN_DESC_AND_ACTIONS = 0
        const val TAB_VARS_DESC = 1
        const val TAB_OBJECTS = 2
        const val LOAD = 0
        const val SAVE = 1
        const val MAX_PAGES = 10
        const val SLOTS_PER_PAGE = 6
        const val MAX_SAVE_SLOTS = 60
    }

    val storageHelper = SimpleStorageHelper(this)
    lateinit var gameViewModel: GameViewModel
    private var slotAction = LOAD
    lateinit var saveResultLaunch: ActivityResultLauncher<android.content.Intent>

    val currentTabState = mutableIntStateOf(TAB_MAIN_DESC_AND_ACTIONS)
    val badgeMainState = mutableStateOf(false)
    val badgeVarsState = mutableStateOf(false)
    val badgeInvState = mutableStateOf(false)
    val gameTitleState = mutableStateOf("")

    // Compose Dialog States
    val inputDialogState = mutableStateOf<InputDialogData?>(null)
    val executorDialogState = mutableStateOf<InputDialogData?>(null)
    val messageDialogState = mutableStateOf<MessageDialogData?>(null)
    val menuDialogState = mutableStateOf<MenuDialogData?>(null)
    val errorDialogState = mutableStateOf<ErrorDialogData?>(null)
    val imageDialogState = mutableStateOf<String?>(null)
    val posterMenuState = mutableStateOf<String?>(null)
    val showCloseDialogState = mutableStateOf(false)
    val showLoadDialogState = mutableStateOf(false)

    override fun attachBaseContext(newBase: Context) {
        super.attachBaseContext(LocaleHelper.wrapContext(newBase))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        LocaleHelper.applyAppLanguage(this)
        enableEdgeToEdge()

        gameViewModel = ViewModelProvider(this)[GameViewModel::class.java]
        gameViewModel.activityObserver.value = this

        saveResultLaunch = registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { result ->
            if (result.resultCode == RESULT_OK) {
                val data = result.data ?: return@registerForActivityResult
                val uri = data.data ?: return@registerForActivityResult
                when (slotAction) {
                    LOAD -> gameViewModel.requestForNativeLib(GameLibRequest.LOAD_FILE, uri)
                    SAVE -> gameViewModel.requestForNativeLib(GameLibRequest.SAVE_FILE, uri)
                }
            }
        }

        if (savedInstanceState != null) {
            currentTabState.intValue = savedInstanceState.getInt("savedActiveTab", 0)
        } else {
            initServices()
            initGame()
        }

        gameViewModel.audioErrorObserver.observe(this) { path ->
            val settings = gameViewModel.settingsController
            if (settings.isUseMusicDebug) {
                showSimpleDialog(path, GameDialogType.ERROR_DIALOG, ErrorType.SOUND_ERROR)
            }
        }

        setContent {
            QuestopiaTheme {
                GameMainCompose(
                    activity = this,
                    viewModel = gameViewModel,
                    currentTab = currentTabState.intValue,
                    onTabSelected = { tab ->
                        currentTabState.intValue = tab
                        when (tab) {
                            TAB_MAIN_DESC_AND_ACTIONS -> badgeMainState.value = false
                            TAB_VARS_DESC -> badgeVarsState.value = false
                            TAB_OBJECTS -> badgeInvState.value = false
                        }
                    },
                    badgeMain = badgeMainState.value,
                    badgeVars = badgeVarsState.value,
                    badgeInv = badgeInvState.value,
                    gameTitle = gameTitleState.value,
                    onExitRequested = { promptCloseGame() }
                )

                // Dialogs rendered directly via Jetpack Compose
                GameDialogsHost(activity = this, viewModel = gameViewModel)
            }
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        outState.putInt("savedActiveTab", currentTabState.intValue)
        super.onSaveInstanceState(outState)
    }

    private fun initServices() {
        gameViewModel.startAudio()
        gameViewModel.startNativeLib()
    }

    private fun initGame() {
        val gameId = intent.getLongExtra("gameId", 0L)
        val gameTitle = intent.getStringExtra("gameTitle") ?: ""
        gameTitleState.value = gameTitle
        val gameDirUriStr = intent.getStringExtra("gameDirUri")
        val gameFileUriStr = intent.getStringExtra("gameFileUri")

        var gameDirUri = if (!gameDirUriStr.isNullOrEmpty()) Uri.parse(gameDirUriStr) else Uri.EMPTY
        var gameFileUri = if (!gameFileUriStr.isNullOrEmpty()) Uri.parse(gameFileUriStr) else Uri.EMPTY

        if (gameFileUri == Uri.EMPTY && gameDirUri != Uri.EMPTY) {
            val gameDir = DocumentFileCompat.fromUri(this, gameDirUri)
            val loc = DirUtil.findGameFileDeep(gameDir, 4)
            if (loc != null) {
                gameFileUri = loc.gameFile.uri
                if (loc.gameDir.uri != gameDirUri) {
                    gameDirUri = loc.gameDir.uri
                }
            }
        }

        gameViewModel.setGameDirUri(gameDirUri)
        gameViewModel.runGameIntoNativeLib(gameId, gameTitle, gameDirUri, gameFileUri)
    }

    fun warnUser(id: Int) {
        runOnUiThread {
            when (id) {
                TAB_MAIN_DESC_AND_ACTIONS -> {
                    if (currentTabState.intValue != TAB_MAIN_DESC_AND_ACTIONS) badgeMainState.value = true
                }
                TAB_VARS_DESC -> {
                    if (currentTabState.intValue != TAB_VARS_DESC) badgeVarsState.value = true
                }
                TAB_OBJECTS -> {
                    if (currentTabState.intValue != TAB_OBJECTS) badgeInvState.value = true
                }
            }
        }
    }

    override fun onDestroy() {
        gameViewModel.removeCallback()
        super.onDestroy()
    }

    override fun onPause() {
        gameViewModel.pauseAudio()
        gameViewModel.removeCallback()
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        if (gameViewModel.isGameRunning) {
            gameViewModel.resumeAudio()
            gameViewModel.setCallback()
        }
    }

    fun applySettings() {
        // Reactive compose updates handle view styling
    }

    fun promptCloseGame() {
        runOnUiThread {
            showCloseDialogState.value = true
        }
    }

    fun showSavePopup() {
        // Handled via Compose UI
    }

    fun showSimpleDialog(inputString: String, dialogType: GameDialogType, errorType: ErrorType?) {
        if (isFinishing || isDestroyed) return
        runOnUiThread {
            when (dialogType) {
                GameDialogType.ERROR_DIALOG -> {
                    val msg = if (errorType != null) {
                        when (errorType) {
                            ErrorType.IMAGE_ERROR -> getString(R.string.notFoundImage) + "\n" + inputString
                            ErrorType.SOUND_ERROR -> getString(R.string.notFoundSound) + "\n" + inputString
                            ErrorType.WAITING_ERROR -> getString(R.string.waitingError) + "\n" + inputString
                            ErrorType.WAITING_INPUT_ERROR -> getString(R.string.waitingInputError) + "\n" + inputString
                            ErrorType.EXCEPTION -> getString(R.string.error) + "\n" + inputString
                            else -> inputString
                        }
                    } else inputString
                    errorDialogState.value = ErrorDialogData(msg)
                }
                GameDialogType.IMAGE_DIALOG -> {
                    imageDialogState.value = inputString
                }
                GameDialogType.LOAD_DIALOG -> {
                    showLoadDialogState.value = true
                }
                GameDialogType.CLOSE_DIALOG -> {
                    showCloseDialogState.value = true
                }
                else -> {}
            }
        }
    }

    fun showMessageDialog(inputString: String?, latch: CountDownLatch) {
        if (isFinishing || isDestroyed) {
            latch.countDown()
            return
        }
        val processedMsg = inputString ?: ""
        runOnUiThread {
            messageDialogState.value = MessageDialogData(processedMsg, latch)
        }
    }

    fun showInputDialog(inputString: String?, inputQueue: ArrayBlockingQueue<String>) {
        if (isFinishing || isDestroyed) {
            inputQueue.add("")
            return
        }
        val config = gameViewModel.iConfig
        val msg = if (config.useHtml) gameViewModel.removeHtmlTags(inputString) ?: "" else inputString ?: ""
        val title = if (msg == "userInputTitle" || msg.isBlank()) getString(R.string.userInputTitle) else msg
        runOnUiThread {
            inputDialogState.value = InputDialogData(title, inputQueue)
        }
    }

    fun showExecutorDialog(inputString: String?, inputQueue: ArrayBlockingQueue<String>) {
        if (isFinishing || isDestroyed) {
            inputQueue.add("")
            return
        }
        val config = gameViewModel.iConfig
        val msg = if (config.useHtml) gameViewModel.removeHtmlTags(inputString) ?: "" else inputString ?: ""
        val title = if (msg == "execStringTitle" || msg.isBlank()) getString(R.string.execStringTitle) else msg
        runOnUiThread {
            executorDialogState.value = InputDialogData(title, inputQueue)
        }
    }

    fun showMenuDialog(items: List<String>, resultQueue: ArrayBlockingQueue<Int>) {
        if (isFinishing || isDestroyed) {
            resultQueue.add(-1)
            return
        }
        runOnUiThread {
            menuDialogState.value = MenuDialogData(items, resultQueue)
        }
    }

    fun startReadOrWriteSave(action: Int) {
        slotAction = action
        when (action) {
            LOAD -> {
                val intent = android.content.Intent(android.content.Intent.ACTION_GET_CONTENT).apply {
                    type = "application/octet-stream"
                    putExtra(android.content.Intent.EXTRA_ALLOW_MULTIPLE, false)
                }
                saveResultLaunch.launch(intent)
            }
            SAVE -> {
                val intent = android.content.Intent(android.content.Intent.ACTION_CREATE_DOCUMENT).apply {
                    type = "application/octet-stream"
                    val gameDirOpt = gameViewModel.curGameDir
                    val extraValue = if (gameDirOpt.isPresent && gameDirOpt.get().name != null) {
                        "${gameDirOpt.get().name}.sav"
                    } else {
                        "${ThreadLocalRandom.current().nextInt()}.sav"
                    }
                    putExtra(android.content.Intent.EXTRA_TITLE, extraValue)
                }
                saveResultLaunch.launch(intent)
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK && event?.repeatCount == 0) {
            promptCloseGame()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GameMainCompose(
    activity: GameActivity,
    viewModel: GameViewModel,
    currentTab: Int,
    onTabSelected: (Int) -> Unit,
    badgeMain: Boolean,
    badgeVars: Boolean,
    badgeInv: Boolean,
    gameTitle: String,
    onExitRequested: () -> Unit
) {
    val context = LocalContext.current
    var showInGameMenu by remember { mutableStateOf(false) }
    var showSlotsSheetMode by remember { mutableStateOf<Int?>(null) } // LOAD=0, SAVE=1
    var showCheatModesSheet by remember { mutableStateOf(false) }
    var showRestartDialog by remember { mutableStateOf(false) }
    var actionClickCount by remember { mutableIntStateOf(0) }

    val mainDesc by viewModel.mainDescObserver.observeAsState("")
    val varsDesc by viewModel.varsDescObserver.observeAsState("")
    val actionsList by viewModel.actsListLiveData.observeAsState(emptyList())
    val objectsList by viewModel.objsListLiveData.observeAsState(emptyList())

    LaunchedEffect(objectsList) {
        Log.d(
            "QUEST_INVENTORY",
            "Inventory updated: count=${objectsList.size}, items=${objectsList.joinToString { item -> "name=${item.name()}, image=${item.image}" }}"
        )
    }

    BackHandler {
        onExitRequested()
    }

    Scaffold(
        topBar = {
            val view = LocalView.current
            var isTitleExpanded by remember { mutableStateOf(false) }
            var isTitleTruncated by remember { mutableStateOf(false) }

            Surface(
                color = MaterialTheme.colorScheme.surface,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .statusBarsPadding()
                        .padding(horizontal = 12.dp, vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Combined Morphing overlay for Back button + Title (Snug fit)
                    MorphingSurface(
                        shape = RoundedCornerShape(20.dp),
                        pressedRadius = 8.dp,
                        color = MaterialTheme.colorScheme.surfaceContainerHigh,
                        onClick = if (isTitleTruncated || isTitleExpanded) {
                            { isTitleExpanded = !isTitleExpanded }
                        } else null,
                        modifier = Modifier
                            .weight(1f, fill = false)
                            .wrapContentWidth(Alignment.Start)
                            .animateContentSize()
                    ) {
                        Row(
                            modifier = Modifier
                                .wrapContentWidth()
                                .padding(horizontal = 4.dp, vertical = 2.dp),
                            verticalAlignment = if (isTitleExpanded) Alignment.Top else Alignment.CenterVertically
                        ) {
                            IconButton(
                                onClick = {
                                    view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                    onExitRequested()
                                },
                                modifier = Modifier.size(36.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                    contentDescription = stringResource(R.string.close),
                                    tint = MaterialTheme.colorScheme.onSurface,
                                    modifier = Modifier.size(20.dp)
                                )
                            }

                            Spacer(modifier = Modifier.width(4.dp))

                            Text(
                                text = gameTitle.ifBlank { stringResource(R.string.closeGameTitle) },
                                style = MaterialTheme.typography.titleSmall.copy(
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.sp
                                ),
                                color = MaterialTheme.colorScheme.onSurface,
                                maxLines = if (isTitleExpanded) 5 else 1,
                                overflow = TextOverflow.Ellipsis,
                                onTextLayout = { textLayoutResult ->
                                    if (!isTitleExpanded) {
                                        isTitleTruncated = textLayoutResult.hasVisualOverflow || textLayoutResult.lineCount > 1
                                    }
                                },
                                modifier = Modifier
                                    .padding(end = 12.dp, top = if (isTitleExpanded) 6.dp else 0.dp, bottom = if (isTitleExpanded) 6.dp else 0.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.weight(1f))

                    // Separate Morphing overlay for 3-dots Menu button
                    MorphingSurface(
                        shape = CircleShape,
                        pressedRadius = 10.dp,
                        color = MaterialTheme.colorScheme.surfaceContainerHigh,
                        onClick = {
                            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                            showInGameMenu = true
                        },
                        modifier = Modifier.size(40.dp)
                    ) {
                        Box(
                            contentAlignment = Alignment.Center,
                            modifier = Modifier.fillMaxSize()
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.MoreVert,
                                contentDescription = stringResource(R.string.menu),
                                tint = MaterialTheme.colorScheme.onSurface,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }
                }
            }
        },
        bottomBar = {
            if (showInGameMenu || showSlotsSheetMode != null || showCheatModesSheet) return@Scaffold
            val navColors = rememberNavThemeColors()

            val gameNavItems = listOf(
                ExpressiveNavItem(
                    selectedIcon = Icons.Filled.Description,
                    unselectedIcon = Icons.Outlined.Description,
                    label = "",
                    contentDescription = stringResource(R.string.mainDescTitle),
                    showBadge = badgeMain
                ),
                ExpressiveNavItem(
                    selectedIcon = Icons.Filled.Assessment,
                    unselectedIcon = Icons.Outlined.Assessment,
                    label = "",
                    contentDescription = stringResource(R.string.varsDescTitle),
                    showBadge = badgeVars
                ),
                ExpressiveNavItem(
                    selectedIcon = Icons.Filled.Inventory2,
                    unselectedIcon = Icons.Outlined.Inventory2,
                    label = "",
                    contentDescription = stringResource(R.string.inventoryTitle),
                    showBadge = badgeInv
                )
            )

            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = navColors.navBarColor,
                tonalElevation = if (navColors.isAmoled) 0.dp else 2.dp
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .windowInsetsPadding(NavigationBarDefaults.windowInsets)
                        .height(54.dp)
                        .padding(horizontal = 4.dp),
                    horizontalArrangement = Arrangement.SpaceAround,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    gameNavItems.forEachIndexed { index, item ->
                        val isSelected = index == currentTab
                        MaterialYouNavigationItem(
                            selected = isSelected,
                            onClick = { onTabSelected(index) },
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
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(MaterialTheme.colorScheme.surface)
        ) {
            // Tab 1: Main Desc & Actions (Always preserved in composition)
            val isMainTab = currentTab == GameActivity.TAB_MAIN_DESC_AND_ACTIONS
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .then(if (isMainTab) Modifier else Modifier.height(0.dp).alpha(0f))
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f)
                ) {
                    GameHtmlWebView(
                        htmlContent = mainDesc,
                        viewModel = viewModel,
                        activity = activity
                    )
                }

                if (actionsList.isNotEmpty() && viewModel.showActions) {
                    HorizontalDivider(
                        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f),
                        thickness = 1.dp
                    )
                    val columnCount = if (actionsList.size == 1) 1 else 2
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(columnCount),
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(max = 280.dp),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        gridItemsIndexed(actionsList) { index, item ->
                            GameListItemCard(
                                item = item,
                                shape = RoundedCornerShape(16.dp),
                                onClick = {
                                    actionClickCount++
                                    val settings = viewModel.settingsController
                                    if (settings != null && settings.isAutosaveEnabled && settings.autosaveClickInterval >= 10) {
                                        if (actionClickCount >= settings.autosaveClickInterval) {
                                            actionClickCount = 0
                                            val savesDirOpt = viewModel.savesDir
                                            val savesDir = if (savesDirOpt.isPresent) savesDirOpt.get() else null
                                            if (savesDir != null) {
                                                val autoSaveFile = findOrCreateFile(context, savesDir, "autosave.sav", MimeType.TEXT)
                                                if (autoSaveFile != null) {
                                                    Log.d("GameActivity", "Auto-saving game to ${autoSaveFile.uri}")
                                                    viewModel.requestForNativeLib(GameLibRequest.SAVE_FILE, autoSaveFile.uri)
                                                }
                                            }
                                        }
                                    }
                                    viewModel.onActionClicked(index)
                                }
                            )
                        }
                    }
                }
            }

            // Tab 2: Vars Desc
            if (currentTab == GameActivity.TAB_VARS_DESC) {
                GameHtmlWebView(
                    htmlContent = varsDesc,
                    viewModel = viewModel,
                    activity = activity
                )
            }

            // Tab 3: Inventory / Objects
            if (currentTab == GameActivity.TAB_OBJECTS) {
                if (objectsList.isEmpty()) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = stringResource(R.string.emptyInventory),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                        verticalArrangement = Arrangement.spacedBy(2.dp)
                    ) {
                        itemsIndexed(objectsList) { index, item ->
                            val itemShape = getGroupedItemShape(index, objectsList.size)
                            GameListItemCard(
                                item = item,
                                shape = itemShape,
                                onClick = { viewModel.onObjectClicked(index) }
                            )
                        }
                    }
                }
            }
        }
    }

    // In-Game Options Menu Bottom Sheet
    if (showInGameMenu) {
        InGameOptionsMenuSheet(
            activity = activity,
            viewModel = viewModel,
            onSaveClick = {
                showInGameMenu = false
                showSlotsSheetMode = GameActivity.SAVE
            },
            onLoadClick = {
                showInGameMenu = false
                showSlotsSheetMode = GameActivity.LOAD
            },
            onCheatsClick = {
                showInGameMenu = false
                showCheatModesSheet = true
            },
            onRestartClick = {
                showInGameMenu = false
                showRestartDialog = true
            },
            onExitRequested = {
                showInGameMenu = false
                onExitRequested()
            },
            onDismiss = { showInGameMenu = false }
        )
    }

    // Save/Load Slots Bottom Sheet
    if (showSlotsSheetMode != null) {
        val isSaveMode = showSlotsSheetMode == GameActivity.SAVE
        SaveSlotsSheet(
            isSave = isSaveMode,
            activity = activity,
            viewModel = viewModel,
            onDismiss = { showSlotsSheetMode = null }
        )
    }

    // Cheat Modes & Save Editor Bottom Sheet
    if (showCheatModesSheet) {
        CheatModesSheet(
            viewModel = viewModel,
            activity = activity,
            onDismiss = { showCheatModesSheet = false }
        )
    }

    // Restart Confirmation Dialog
    if (showRestartDialog) {
        AlertDialog(
            onDismissRequest = { showRestartDialog = false },
            icon = { Icon(Icons.Outlined.Refresh, contentDescription = null, tint = MaterialTheme.colorScheme.primary) },
            title = { Text(stringResource(R.string.restartGameTitle), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold) },
            text = { Text(stringResource(R.string.promptRestartGame), style = MaterialTheme.typography.bodyMedium) },
            confirmButton = {
                MorphingButton(onClick = {
                    showRestartDialog = false
                    viewModel.requestForNativeLib(GameLibRequest.RESTART_GAME)
                    onTabSelected(GameActivity.TAB_MAIN_DESC_AND_ACTIONS)
                }) {
                    Text(stringResource(android.R.string.ok))
                }
            },
            dismissButton = {
                MorphingOutlinedButton(onClick = { showRestartDialog = false }) {
                    Text(stringResource(android.R.string.cancel))
                }
            }
        )
    }
}
