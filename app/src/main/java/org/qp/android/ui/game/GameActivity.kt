package org.qp.android.ui.game

import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.ViewGroup
import android.util.Log
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.HapticFeedbackConstants
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.widget.LinearLayout
import androidx.activity.SystemBarStyle
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.animation.*
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.ui.graphics.graphicsLayer
import org.qp.android.ui.common.MorphingButton
import org.qp.android.ui.common.MorphingDialogButton
import org.qp.android.ui.common.MorphingOutlinedButton
import org.qp.android.ui.common.MorphingSurface
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.ExitToApp
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.text.HtmlCompat
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.preference.PreferenceManager
import coil.compose.SubcomposeAsyncImage
import coil.request.CachePolicy
import coil.request.ImageRequest
import com.anggrayudi.storage.SimpleStorageHelper
import com.anggrayudi.storage.file.DocumentFileCompat
import com.anggrayudi.storage.file.MimeType
import com.libqsp.jni.QSPLib
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.delay
import org.qp.android.R
import org.qp.android.helpers.ErrorType
import org.qp.android.helpers.utils.FileUtil.findOrCreateFile
import org.qp.android.helpers.utils.FileUtil.fromRelPath
import org.qp.android.helpers.utils.LocaleHelper
import org.qp.android.ui.common.CustomDrawerHandle
import org.qp.android.ui.common.MorphingButton
import org.qp.android.ui.common.MorphingOutlinedButton
import org.qp.android.ui.common.MorphingSurface
import org.qp.android.ui.common.getGroupedItemShape
import org.qp.android.ui.dialogs.GameDialogType
import org.qp.android.ui.settings.SettingsActivity
import org.qp.android.ui.stock.ExpressiveNavItem
import org.qp.android.ui.stock.MaterialYouNavigationItem
import org.qp.android.ui.stock.rememberNavThemeColors
import org.qp.android.ui.stock.ShimmerPlaceholder
import org.qp.android.ui.theme.QuestopiaTheme
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ThreadLocalRandom

data class InputDialogData(val title: String, val inputQueue: ArrayBlockingQueue<String>)
data class MessageDialogData(val message: String, val latch: CountDownLatch)
data class MenuDialogData(val items: List<String>, val resultQueue: ArrayBlockingQueue<Int>)
data class ErrorDialogData(val message: String)
data class SlotInfo(val index: Int, val isPresent: Boolean, val timeStr: String?, val fileUri: Uri?)

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
        const val MAX_SAVE_SLOTS = 5
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
    val showCloseDialogState = mutableStateOf(false)
    val showLoadDialogState = mutableStateOf(false)

    override fun attachBaseContext(newBase: Context) {
        super.attachBaseContext(LocaleHelper.wrapContext(newBase))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        LocaleHelper.applyAppLanguage(this)
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.auto(
                android.graphics.Color.TRANSPARENT,
                android.graphics.Color.TRANSPARENT
            ),
            navigationBarStyle = SystemBarStyle.auto(
                android.graphics.Color.TRANSPARENT,
                android.graphics.Color.TRANSPARENT
            )
        )

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
            val prefs = PreferenceManager.getDefaultSharedPreferences(this)
            val themeMode = prefs.getString("themeMode", "system") ?: "system"
            val themeColor = prefs.getString("themeColor", "monochrome") ?: "monochrome"
            QuestopiaTheme(themeMode = themeMode, themeColor = themeColor) {
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
            val files = gameDir?.listFiles()
            if (files != null) {
                for (file in files) {
                    val name = file.name?.lowercase(Locale.ROOT) ?: ""
                    if (name.endsWith(".qsp") || name.endsWith(".gam")) {
                        gameFileUri = file.uri
                        break
                    }
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
        val config = gameViewModel.iConfig
        val processedMsg = if (config.useHtml) gameViewModel.removeHtmlTags(inputString) ?: "" else inputString ?: ""
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

@Composable
fun GameDialogsHost(activity: GameActivity, viewModel: GameViewModel) {
    val inputDialogData by activity.inputDialogState
    val executorDialogData by activity.executorDialogState
    val messageDialogData by activity.messageDialogState
    val menuDialogData by activity.menuDialogState
    val errorDialogData by activity.errorDialogState
    val imageDialogUri by activity.imageDialogState
    val showCloseDialog by activity.showCloseDialogState
    val showLoadDialog by activity.showLoadDialogState

    // 1. User Input Dialog (Compact, Not Screen Filling)
    if (inputDialogData != null) {
        var textInput by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = {
                inputDialogData?.inputQueue?.add("")
                activity.inputDialogState.value = null
            },
            title = { Text(inputDialogData?.title ?: stringResource(R.string.userInputTitle), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold) },
            text = {
                OutlinedTextField(
                    value = textInput,
                    onValueChange = { textInput = it },
                    label = { Text(stringResource(R.string.userInputTitle)) },
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth().padding(top = 4.dp)
                )
            },
            confirmButton = {
                MorphingButton(onClick = {
                    inputDialogData?.inputQueue?.add(textInput)
                    activity.inputDialogState.value = null
                }) {
                    Text(stringResource(android.R.string.ok))
                }
            },
            dismissButton = {
                MorphingOutlinedButton(onClick = {
                    inputDialogData?.inputQueue?.add("")
                    activity.inputDialogState.value = null
                }) {
                    Text(stringResource(android.R.string.cancel))
                }
            }
        )
    }

    // 2. Executor Dialog (Compact)
    if (executorDialogData != null) {
        var textInput by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = {
                executorDialogData?.inputQueue?.add("")
                activity.executorDialogState.value = null
            },
            title = { Text(executorDialogData?.title ?: stringResource(R.string.execStringTitle), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold) },
            text = {
                OutlinedTextField(
                    value = textInput,
                    onValueChange = { textInput = it },
                    label = { Text(stringResource(R.string.command)) },
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth().padding(top = 4.dp)
                )
            },
            confirmButton = {
                org.qp.android.ui.common.MorphingButton(onClick = {
                    executorDialogData?.inputQueue?.add(textInput)
                    activity.executorDialogState.value = null
                }) {
                    Text(stringResource(android.R.string.ok))
                }
            },
            dismissButton = {
                org.qp.android.ui.common.MorphingOutlinedButton(onClick = {
                    executorDialogData?.inputQueue?.add("")
                    activity.executorDialogState.value = null
                }) {
                    Text(stringResource(android.R.string.cancel))
                }
            }
        )
    }

    // 3. Game Message Dialog
    if (messageDialogData != null) {
        AlertDialog(
            onDismissRequest = {
                messageDialogData?.latch?.countDown()
                activity.messageDialogState.value = null
            },
            title = { Text(stringResource(R.string.mainDescTitle), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold) },
            text = {
                Text(
                    text = messageDialogData?.message ?: "",
                    style = MaterialTheme.typography.bodyMedium
                )
            },
            confirmButton = {
                org.qp.android.ui.common.MorphingButton(onClick = {
                    messageDialogData?.latch?.countDown()
                    activity.messageDialogState.value = null
                }) {
                    Text(stringResource(android.R.string.ok))
                }
            }
        )
    }

    // 4. In-Game Select Menu Dialog (No Blank Space, Expressive Buttons)
    if (menuDialogData != null) {
        val prefs = remember { PreferenceManager.getDefaultSharedPreferences(activity) }
        val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
        val dialogBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow
        val itemBg = if (isAmoled) Color(0xFF0D0D0D) else MaterialTheme.colorScheme.surfaceContainer

        Dialog(
            onDismissRequest = {
                menuDialogData?.resultQueue?.add(-1)
                activity.menuDialogState.value = null
            }
        ) {
            Surface(
                shape = RoundedCornerShape(28.dp),
                color = dialogBg,
                tonalElevation = 6.dp,
                shadowElevation = 12.dp,
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.25f)),
                modifier = Modifier
                    .fillMaxWidth()
                    .wrapContentHeight()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp)
                ) {
                    Text(
                        text = stringResource(R.string.selectActionTitle),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.padding(bottom = 16.dp)
                    )

                    val items = menuDialogData!!.items
                    LazyColumn(
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(max = 340.dp),
                        verticalArrangement = Arrangement.spacedBy(2.dp)
                    ) {
                        itemsIndexed(items) { index, item ->
                            val itemShape = getGroupedItemShape(index, items.size)
                            MorphingSurface(
                                shape = itemShape,
                                color = itemBg,
                                pressedRadius = 24.dp,
                                onClick = {
                                    menuDialogData?.resultQueue?.add(index)
                                    activity.menuDialogState.value = null
                                },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(horizontal = 16.dp, vertical = 14.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(32.dp)
                                            .clip(CircleShape)
                                            .background(MaterialTheme.colorScheme.primaryContainer),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            text = "${index + 1}",
                                            style = MaterialTheme.typography.labelLarge,
                                            fontWeight = FontWeight.Bold,
                                            color = MaterialTheme.colorScheme.onPrimaryContainer
                                        )
                                    }
                                    Spacer(modifier = Modifier.width(12.dp))
                                    Text(
                                        text = item,
                                        style = MaterialTheme.typography.bodyLarge,
                                        fontWeight = FontWeight.Medium,
                                        color = MaterialTheme.colorScheme.onSurface,
                                        modifier = Modifier.weight(1f)
                                    )
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    MorphingOutlinedButton(
                        onClick = {
                            menuDialogData?.resultQueue?.add(-1)
                            activity.menuDialogState.value = null
                        },
                        modifier = Modifier.align(Alignment.End)
                    ) {
                        Text(stringResource(android.R.string.cancel))
                    }
                }
            }
        }
    }

    // 5. Error Dialog
    if (errorDialogData != null) {
        AlertDialog(
            onDismissRequest = { activity.errorDialogState.value = null },
            icon = { Icon(Icons.Outlined.ErrorOutline, contentDescription = null, tint = MaterialTheme.colorScheme.error) },
            title = { Text(stringResource(R.string.error)) },
            text = { Text(errorDialogData!!.message, style = MaterialTheme.typography.bodyMedium) },
            confirmButton = {
                MorphingButton(onClick = { activity.errorDialogState.value = null }) {
                    Text(stringResource(android.R.string.ok))
                }
            }
        )
    }

    // 6. Image Preview Dialog
    if (!imageDialogUri.isNullOrBlank()) {
        Dialog(
            onDismissRequest = { activity.imageDialogState.value = null },
            properties = DialogProperties(usePlatformDefaultWidth = false)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.9f))
                    .clickable { activity.imageDialogState.value = null },
                contentAlignment = Alignment.Center
            ) {
                SubcomposeAsyncImage(
                    model = imageDialogUri,
                    contentDescription = null,
                    loading = {
                        CircularProgressIndicator(color = Color.White)
                    },
                    contentScale = ContentScale.Fit,
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp)
                )
            }
        }
    }

    // 7. Prompt Close Dialog
    if (showCloseDialog) {
        AlertDialog(
            onDismissRequest = { activity.showCloseDialogState.value = false },
            icon = { Icon(Icons.AutoMirrored.Outlined.ExitToApp, contentDescription = null, tint = MaterialTheme.colorScheme.primary) },
            title = { Text(stringResource(R.string.close)) },
            text = { Text(stringResource(R.string.promptCloseGame), style = MaterialTheme.typography.bodyMedium) },
            confirmButton = {
                MorphingButton(onClick = {
                    activity.showCloseDialogState.value = false
                    viewModel.stopAudio()
                    viewModel.stopNativeLib()
                    viewModel.removeCallback()
                    activity.finish()
                }) {
                    Text(stringResource(android.R.string.ok))
                }
            },
            dismissButton = {
                MorphingOutlinedButton(onClick = { activity.showCloseDialogState.value = false }) {
                    Text(stringResource(android.R.string.cancel))
                }
            }
        )
    }

    // 8. Load Game External Dialog
    if (showLoadDialog) {
        AlertDialog(
            onDismissRequest = { activity.showLoadDialogState.value = false },
            title = { Text(stringResource(R.string.loadGamePopup)) },
            text = { Text(stringResource(R.string.loadGamePopup), style = MaterialTheme.typography.bodyMedium) },
            confirmButton = {
                MorphingButton(onClick = {
                    activity.showLoadDialogState.value = false
                    activity.startReadOrWriteSave(GameActivity.LOAD)
                }) {
                    Text(stringResource(android.R.string.ok))
                }
            },
            dismissButton = {
                org.qp.android.ui.common.MorphingOutlinedButton(onClick = { activity.showLoadDialogState.value = false }) {
                    Text(stringResource(android.R.string.cancel))
                }
            }
        )
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
    var showRestartDialog by remember { mutableStateOf(false) }
    var showCheatModesSheet by remember { mutableStateOf(false) }

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
                    // Combined Morphing overlay for Back button + Title
                    MorphingSurface(
                        shape = RoundedCornerShape(20.dp),
                        pressedRadius = 8.dp,
                        color = MaterialTheme.colorScheme.surfaceContainerHigh,
                        onClick = if (isTitleTruncated || isTitleExpanded) {
                            { isTitleExpanded = !isTitleExpanded }
                        } else null,
                        modifier = Modifier
                            .weight(1f)
                            .animateContentSize()
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
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
                                    .weight(1f)
                                    .padding(end = 12.dp, top = if (isTitleExpanded) 6.dp else 0.dp, bottom = if (isTitleExpanded) 6.dp else 0.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.width(8.dp))

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
                        viewModel = viewModel
                    )
                }

                if (actionsList.isNotEmpty() && viewModel.showActions) {
                    HorizontalDivider(
                        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f),
                        thickness = 1.dp
                    )
                    LazyColumn(
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(max = 280.dp),
                        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                        verticalArrangement = Arrangement.spacedBy(2.dp)
                    ) {
                        itemsIndexed(actionsList) { index, item ->
                            val itemShape = when {
                                actionsList.size == 1 -> RoundedCornerShape(20.dp)
                                index == 0 -> RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp, bottomStart = 4.dp, bottomEnd = 4.dp)
                                index == actionsList.size - 1 -> RoundedCornerShape(topStart = 4.dp, topEnd = 4.dp, bottomStart = 20.dp, bottomEnd = 20.dp)
                                else -> RoundedCornerShape(4.dp)
                            }
                            GameListItemCard(
                                item = item,
                                shape = itemShape,
                                onClick = { viewModel.onActionClicked(index) }
                            )
                        }
                    }
                }
            }

            // Tab 2: Vars Desc
            if (currentTab == GameActivity.TAB_VARS_DESC) {
                GameHtmlWebView(
                    htmlContent = varsDesc,
                    viewModel = viewModel
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
                            val itemShape = when {
                                objectsList.size == 1 -> RoundedCornerShape(20.dp)
                                index == 0 -> RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp, bottomStart = 4.dp, bottomEnd = 4.dp)
                                index == objectsList.size - 1 -> RoundedCornerShape(topStart = 4.dp, topEnd = 4.dp, bottomStart = 20.dp, bottomEnd = 20.dp)
                                else -> RoundedCornerShape(4.dp)
                            }
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

    // In-Game Options Menu Bottom Sheet (Grouped Expressive Design, No Emojis, No Subtitles)
    if (showInGameMenu) {
        val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
        val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
        val menuSheetBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow

        ModalBottomSheet(
            onDismissRequest = { showInGameMenu = false },
            containerColor = menuSheetBg,
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
                Text(
                    text = stringResource(R.string.gameMenuTitle),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 8.dp)
                )

                // Group 1: Kayıt ve Yükleme (Save & Load)
                ExpressiveMenuGroup(
                    items = listOf(
                        { shape ->
                            ExpressiveMenuItem(
                                icon = Icons.Outlined.Save,
                                title = stringResource(R.string.saveTitle),
                                shape = shape,
                                onClick = {
                                    showInGameMenu = false
                                    showSlotsSheetMode = GameActivity.SAVE
                                }
                            )
                        },
                        { shape ->
                            ExpressiveMenuItem(
                                icon = Icons.Outlined.FolderOpen,
                                title = stringResource(R.string.loadTitle),
                                shape = shape,
                                onClick = {
                                    showInGameMenu = false
                                    showSlotsSheetMode = GameActivity.LOAD
                                }
                            )
                        }
                    )
                )

                Spacer(modifier = Modifier.height(8.dp))

                // Group 2: Hile Modları & Kullanıcı Girdisi (Cheat Modes & User Input)
                val isCheatsEnabled = prefs.getBoolean("enableCheats", false)
                val group2Items = mutableListOf<@Composable (shape: Shape) -> Unit>()

                if (isCheatsEnabled) {
                    group2Items.add { shape ->
                        ExpressiveMenuItem(
                            icon = Icons.Outlined.Code,
                            title = stringResource(R.string.cheatModesTitle),
                            shape = shape,
                            onClick = {
                                showInGameMenu = false
                                showCheatModesSheet = true
                            }
                        )
                    }
                }

                group2Items.add { shape ->
                    ExpressiveMenuItem(
                        icon = Icons.Outlined.Keyboard,
                        title = stringResource(R.string.userInputTitle),
                        shape = shape,
                        onClick = {
                            showInGameMenu = false
                            val settings = viewModel.settingsController
                            if (settings.isUseExecString) {
                                viewModel.requestForNativeLib(GameLibRequest.USE_EXECUTOR)
                            } else {
                                viewModel.requestForNativeLib(GameLibRequest.USE_INPUT)
                            }
                        }
                    )
                }

                ExpressiveMenuGroup(items = group2Items)

                Spacer(modifier = Modifier.height(8.dp))

                // Group 3: Ayarlar, Oyunu Yeniden Başlat & Oyunu Kapat
                ExpressiveMenuGroup(
                    items = listOf(
                        { shape ->
                            ExpressiveMenuItem(
                                icon = Icons.Outlined.Settings,
                                title = stringResource(R.string.settingsTitle),
                                shape = shape,
                                onClick = {
                                    showInGameMenu = false
                                    context.startActivity(android.content.Intent(context, SettingsActivity::class.java))
                                }
                            )
                        },
                        { shape ->
                            ExpressiveMenuItem(
                                icon = Icons.Outlined.Refresh,
                                title = stringResource(R.string.restartGameTitle),
                                shape = shape,
                                onClick = {
                                    showInGameMenu = false
                                    showRestartDialog = true
                                }
                            )
                        },
                        { shape ->
                            ExpressiveMenuItem(
                                icon = Icons.AutoMirrored.Outlined.ExitToApp,
                                title = stringResource(R.string.closeGameTitle),
                                shape = shape,
                                onClick = {
                                    showInGameMenu = false
                                    onExitRequested()
                                }
                            )
                        }
                    )
                )
            }
        }
    }

    // Save/Load Slots Bottom Sheet (Expressive Grouped Style)
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

    // Restart Confirmation Dialog (Clean, No Emojis)
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

@Composable
fun ExpressiveMenuGroup(
    modifier: Modifier = Modifier,
    items: List<@Composable (shape: Shape) -> Unit>
) {
    if (items.isEmpty()) return
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        val total = items.size
        for (index in 0 until total) {
            val shape = getGroupedItemShape(index, total, outerRadius = 24.dp, innerRadius = 4.dp)
            items[index](shape)
        }
    }
}

@Composable
fun ExpressiveMenuItem(
    icon: ImageVector,
    title: String,
    shape: Shape,
    subtitle: String? = null,
    onClick: () -> Unit
) {
    val itemBg = MaterialTheme.colorScheme.surfaceContainer
    val iconBg = MaterialTheme.colorScheme.surfaceContainerHigh

    MorphingSurface(
        shape = shape,
        color = itemBg,
        pressedRadius = 28.dp,
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 9.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(iconBg),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(17.dp)
                )
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyMedium.copy(fontSize = 14.sp),
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                if (!subtitle.isNullOrBlank()) {
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
fun GameListItemCard(
    item: QSPLib.ListItem,
    shape: Shape = RoundedCornerShape(20.dp),
    onClick: () -> Unit
) {
    val context = LocalContext.current
    val gameViewModel: GameViewModel = viewModel()

    LaunchedEffect(item.name, item.image) {
        Log.d("QUEST_INVENTORY", "Rendering item: name=${item.name}, image=${item.image}")
    }

    val resolvedImagePath = remember(item.image, item.name) {
        if (!item.image.isNullOrBlank()) {
            item.image
        } else if (!item.name.isNullOrBlank() && item.name.contains("<img", ignoreCase = true)) {
            val match = Regex("""src=["']?([^"'>\s]+)["']?""", RegexOption.IGNORE_CASE).find(item.name)
            val relPath = match?.groupValues?.getOrNull(1)?.replace("\\", "/")
            if (!relPath.isNullOrBlank()) {
                val curDir = gameViewModel.getCurGameDir().get()
                if (curDir != null) {
                    val docFile = fromRelPath(context, relPath, curDir)
                    if (docFile != null && docFile.exists()) {
                        docFile.uri.toString()
                    } else {
                        relPath
                    }
                } else {
                    relPath
                }
            } else ""
        } else ""
    }

    val textParsed = remember(item.name) {
        if (item.name.isNullOrBlank()) ""
        else HtmlCompat.fromHtml(item.name, HtmlCompat.FROM_HTML_MODE_LEGACY).toString().trim()
    }

    MorphingSurface(
        shape = shape,
        color = MaterialTheme.colorScheme.secondaryContainer,
        tonalElevation = 3.dp,
        pressedRadius = 12.dp,
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 18.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (!resolvedImagePath.isNullOrBlank()) {
                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = MaterialTheme.colorScheme.surfaceContainerHighest,
                    modifier = Modifier.size(38.dp)
                ) {
                    SubcomposeAsyncImage(
                        model = ImageRequest.Builder(context)
                            .data(resolvedImagePath)
                            .crossfade(true)
                            .diskCachePolicy(CachePolicy.ENABLED)
                            .memoryCachePolicy(CachePolicy.ENABLED)
                            .build(),
                        contentDescription = null,
                        loading = {
                            ShimmerPlaceholder()
                        },
                        error = {
                            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = Icons.Outlined.Image,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        },
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )
                }
                if (textParsed.isNotBlank()) {
                    Spacer(modifier = Modifier.width(14.dp))
                }
            }
            if (textParsed.isNotBlank()) {
                Text(
                    text = textParsed,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSecondaryContainer,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
fun GameHtmlWebView(
    htmlContent: String,
    viewModel: GameViewModel
) {
    AndroidView(
        factory = { ctx ->
            WebView(ctx).apply {
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                viewModel.getDefaultWebClient(this)
                addJavascriptInterface(object : Any() {
                    @JavascriptInterface
                    fun onClickImage(src: String?) {
                        if (src == null) return
                        val uri = viewModel.getImageUriFromPath(src)
                        if (uri != Uri.EMPTY) {
                            viewModel.showPicture(uri.toString())
                        }
                    }
                }, "img")
                setBackgroundColor(android.graphics.Color.TRANSPARENT)
            }
        },
        update = { webView ->
            webView.loadDataWithBaseURL("file:///", htmlContent, "text/html", "UTF-8", null)
        },
        modifier = Modifier.fillMaxSize()
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SaveSlotsSheet(
    isSave: Boolean,
    activity: GameActivity,
    viewModel: GameViewModel,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val savesDirOpt = viewModel.savesDir
    val savesDir = if (savesDirOpt.isPresent) savesDirOpt.get() else null

    var slots by remember { mutableStateOf<List<SlotInfo>?>(null) }
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(isSave) {
        withContext(Dispatchers.IO) {
            val list = mutableListOf<SlotInfo>()
            for (slotIndex in 0 until GameActivity.MAX_SAVE_SLOTS) {
                val filename = "${slotIndex + 1}.sav"
                val loadFile = if (savesDir != null) fromRelPath(context, filename, savesDir) else null
                val isSlotPresent = loadFile != null && loadFile.exists()
                val timeStr = if (loadFile != null && isSlotPresent) {
                    val sdf = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault())
                    sdf.format(Date(loadFile.lastModified()))
                } else null
                list.add(
                    SlotInfo(
                        index = slotIndex,
                        isPresent = isSlotPresent,
                        timeStr = timeStr,
                        fileUri = loadFile?.uri
                    )
                )
            }
            withContext(Dispatchers.Main) {
                slots = list
                isLoading = false
            }
        }
    }

    val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
    val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
    val sheetBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow
    val slotItemBg = if (isAmoled) Color(0xFF0D0D0D) else MaterialTheme.colorScheme.surfaceContainer

    ModalBottomSheet(
        onDismissRequest = onDismiss,
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
            Text(
                text = if (isSave) stringResource(R.string.saveTitle) else stringResource(R.string.loadTitle),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(horizontal = 4.dp, vertical = 8.dp)
            )

            if (isLoading) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(140.dp),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(28.dp),
                        strokeWidth = 2.5.dp
                    )
                }
            } else {
                slots?.let { slotList ->
                    ExpressiveMenuGroup(
                        items = slotList.map { slot ->
                            { shape ->
                                MorphingSurface(
                                    shape = shape,
                                    color = slotItemBg,
                                    pressedRadius = 24.dp,
                                    onClick = {
                                        onDismiss()
                                        if (savesDir != null) {
                                            if (isSave) {
                                                val saveFile = findOrCreateFile(context, savesDir, "${slot.index + 1}.sav", MimeType.TEXT)
                                                if (saveFile != null) {
                                                    Log.d("SaveSlotsSheet", "Saving game to slot ${slot.index + 1}: ${saveFile.uri}")
                                                    viewModel.requestForNativeLib(GameLibRequest.SAVE_FILE, saveFile.uri)
                                                } else {
                                                    Log.e("SaveSlotsSheet", "Failed to create/find save file for slot ${slot.index + 1}")
                                                }
                                            } else {
                                                if (slot.fileUri != null) {
                                                    Log.d("SaveSlotsSheet", "Loading game from slot ${slot.index + 1}: ${slot.fileUri}")
                                                    viewModel.requestForNativeLib(GameLibRequest.LOAD_FILE, slot.fileUri)
                                                } else {
                                                    Log.e("SaveSlotsSheet", "Slot ${slot.index + 1} fileUri is null!")
                                                }
                                            }
                                        }
                                    },
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(horizontal = 14.dp, vertical = 10.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Box(
                                            modifier = Modifier
                                                .size(32.dp)
                                                .clip(CircleShape)
                                                .background(if (slot.isPresent) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Text(
                                                text = "${slot.index + 1}",
                                                style = MaterialTheme.typography.bodyMedium,
                                                fontWeight = FontWeight.Bold,
                                                color = if (slot.isPresent) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                        }
                                        Spacer(modifier = Modifier.width(12.dp))
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                text = stringResource(R.string.slotLabel, slot.index + 1),
                                                style = MaterialTheme.typography.bodyMedium,
                                                fontWeight = FontWeight.SemiBold,
                                                color = MaterialTheme.colorScheme.onSurface
                                            )
                                            Text(
                                                text = if (slot.isPresent) "Dolu • ${slot.timeStr}" else "Boş Slot",
                                                style = MaterialTheme.typography.bodySmall,
                                                color = if (slot.isPresent) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                        }
                                        Icon(
                                            imageVector = if (isSave) Icons.Outlined.Save else Icons.Outlined.Download,
                                            contentDescription = null,
                                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                            modifier = Modifier.size(18.dp)
                                        )
                                    }
                                }
                            }
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // External file action button (Clean, No Emojis)
            Button(
                onClick = {
                    onDismiss()
                    activity.startReadOrWriteSave(if (isSave) GameActivity.SAVE else GameActivity.LOAD)
                },
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer,
                    contentColor = MaterialTheme.colorScheme.onSecondaryContainer
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(44.dp)
            ) {
                Icon(
                    imageVector = if (isSave) Icons.Outlined.Save else Icons.Outlined.FileUpload,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (isSave) stringResource(R.string.saveTo) else stringResource(R.string.loadFrom),
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}
