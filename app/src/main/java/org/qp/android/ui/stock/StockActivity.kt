package org.qp.android.ui.stock
import androidx.compose.runtime.setValue
import androidx.compose.runtime.getValue

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Log
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.Composable
import androidx.core.content.IntentCompat
import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.documentfile.provider.DocumentFile
import androidx.preference.PreferenceManager
import com.anggrayudi.storage.file.DocumentFileCompat
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import com.xayah.libpickyou.PickYouLauncher
import com.xayah.libpickyou.ui.model.PermissionType
import com.xayah.libpickyou.ui.model.PickerType
import org.qp.android.R
import org.qp.android.dto.stock.GameData
import org.qp.android.helpers.utils.DirUtil
import org.qp.android.helpers.utils.FileUtil
import org.qp.android.helpers.utils.LocaleHelper
import org.qp.android.model.repository.LocalGame
import org.qp.android.ui.theme.QuestopiaTheme
import java.io.File
import java.io.FileOutputStream
import java.util.Locale

class StockActivity : ComponentActivity() {

    private val TAG = "QUESTLOGTEST"
    private lateinit var stockViewModel: StockViewModel
    private var pendingAddFolder: DocumentFile? = null
    private var showAddDialogState by mutableStateOf(false)
    private var isLoadingState by mutableStateOf(false)
    private var crashReport by mutableStateOf<String?>(null)
    private val downloadReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == android.app.DownloadManager.ACTION_DOWNLOAD_COMPLETE) {
                Log.i(TAG, "Received ACTION_DOWNLOAD_COMPLETE broadcast")
                stockViewModel.postProcessingDownload()
            }
        }
    }

    private fun openFolderPicker() {
        val prefs = PreferenceManager.getDefaultSharedPreferences(this)
        val themeMode = prefs.getString("themeMode", "system") ?: "system"
        val themeType = when (themeMode) {
            "dark" -> "DARK_THEME"
            "light" -> "LIGHT_THEME"
            else -> "AUTO"
        }

        getSharedPreferences("PickYouPreferences", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("dynamic_color", false)
            .putString("theme_type", themeType)
            .apply()

        val launcher = PickYouLauncher(
            title = getString(R.string.selectFolder),
            pickerType = PickerType.DIRECTORY,
            permissionType = PermissionType.NORMAL
        )
        launcher.launch(this) { path ->
            if (!path.isNullOrBlank()) {
                val file = File(path)
                if (file.exists()) {
                    val docFile = DocumentFile.fromFile(file)
                    Log.d(TAG, "Selected folder via LibPickYou: ${docFile.name} ($path)")
                    pendingAddFolder = docFile
                    showAddDialogState = true
                }
            }
        }
    }

    override fun attachBaseContext(newBase: Context) {
        super.attachBaseContext(LocaleHelper.wrapContext(newBase))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val crashFile = File(filesDir, "last_crash.txt")
        if (crashFile.exists()) {
            crashReport = runCatching { crashFile.readText() }.getOrNull()
            crashFile.delete()
        }
        enableEdgeToEdge()

        androidx.core.content.ContextCompat.registerReceiver(
            this,
            downloadReceiver,
            android.content.IntentFilter(android.app.DownloadManager.ACTION_DOWNLOAD_COMPLETE),
            androidx.core.content.ContextCompat.RECEIVER_EXPORTED
        )

        stockViewModel = ViewModelProvider(this)[StockViewModel::class.java]

        Log.i(TAG, "StockActivity onCreate. Triggering initial refresh...")
        isLoadingState = true
        stockViewModel.refreshGamesDirs(null)
        isLoadingState = false

        handleIncomingIntent(intent)

        setContent {
            QuestopiaTheme {
                StockContent(
                    viewModel = stockViewModel,
                    isLoading = isLoadingState,
                    onAddGameClicked = { openFolderPicker() },
                    onPlayGame = { gameData ->
                        stockViewModel.currGameData = gameData
                        val playIntentOpt = stockViewModel.createPlayGameIntent()
                        if (playIntentOpt.isPresent) {
                            val intent = playIntentOpt.get()
                            if (!intent.hasExtra("gameFileUri")) {
                                var chosenUri: Uri? = null
                                if (!gameData.gameFilesUri.isNullOrEmpty()) {
                                    chosenUri = gameData.gameFilesUri[0]
                                } else if (gameData.gameDirUri != Uri.EMPTY) {
                                    val docDir = DocumentFileCompat.fromUri(this, gameData.gameDirUri)
                                    val loc = DirUtil.findGameFileDeep(docDir, 4)
                                    chosenUri = loc?.gameFile?.uri
                                }
                                if (chosenUri != null) {
                                    intent.putExtra("gameFileUri", chosenUri.toString())
                                }
                            }
                            startActivity(intent)
                        } else {
                            Toast.makeText(this, "Game file not found or cannot be opened", Toast.LENGTH_SHORT).show()
                        }
                    },
                    onDeleteGame = { gameData ->
                        stockViewModel.deleteGame(gameData)
                    },
                    onDownloadGame = { gameData ->
                        stockViewModel.startFileDownload(gameData)
                    },
                    showAddDialog = showAddDialogState,
                    pendingFolder = pendingAddFolder,
                    onDismissAddDialog = {
                        showAddDialogState = false
                        pendingAddFolder = null
                    },
                    onConfirmAddGame = { title, author, version ->
                        val folder = pendingAddFolder
                        if (folder != null) {
                            addGameInPlace(folder, title, author, version)
                        }
                        showAddDialogState = false
                        pendingAddFolder = null
                    },
                    onExitApp = { finish() }
                )
                crashReport?.let { report ->
                    AlertDialog(
                        onDismissRequest = { crashReport = null },
                        title = { Text(getString(R.string.crashReportTitle)) },
                        text = { Text(report, maxLines = 18, overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis) },
                        confirmButton = {
                            TextButton(onClick = { crashReport = null }) { Text(getString(R.string.close)) }
                        }
                    )
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingIntent(intent)
    }

    private fun handleIncomingIntent(incomingIntent: Intent?) {
        if (incomingIntent == null) return
        val action = incomingIntent.action
        val uri: Uri? = if (action == Intent.ACTION_SEND) {
            IntentCompat.getParcelableExtra(incomingIntent, Intent.EXTRA_STREAM, Uri::class.java)
        } else if (action == Intent.ACTION_VIEW) {
            incomingIntent.data
        } else {
            null
        }

        if (uri != null) {
            Log.i(TAG, "==> Received incoming intent URI: $uri (Action: $action)")
            importGameFromUri(uri)
        }
    }

    private fun importGameFromUri(uri: Uri) {
        lifecycleScope.launch(Dispatchers.IO) {
            withContext(Dispatchers.Main) { isLoadingState = true }
            try {
                var fileName = "imported_game.qsp"
                contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1 && cursor.moveToFirst()) {
                        fileName = cursor.getString(nameIndex) ?: fileName
                    }
                }
                val rawTitle = fileName.substringBeforeLast(".")
                Log.d(TAG, "Importing game file: '$fileName', parsed title: '$rawTitle'")

                val gamesDir = File(getExternalFilesDir(null), "games-dir")
                if (!gamesDir.exists()) gamesDir.mkdirs()

                val gameTargetDir = File(gamesDir, rawTitle)
                if (!gameTargetDir.exists()) gameTargetDir.mkdirs()

                val targetFile = File(gameTargetDir, fileName)
                contentResolver.openInputStream(uri)?.use { input ->
                    FileOutputStream(targetFile).use { output ->
                        input.copyTo(output)
                    }
                }
                Log.d(TAG, "Copied $fileName to: ${targetFile.absolutePath} (Size: ${targetFile.length()} bytes)")

                val newGame = GameData().apply {
                    this.id = targetFile.absolutePath.hashCode().toLong()
                    this.title = rawTitle
                    this.gameDirUri = Uri.fromFile(gameTargetDir)
                    this.gameFilesUri = listOf(Uri.fromFile(targetFile))
                    this.fileSize = targetFile.length()
                }

                val localGame = LocalGame(this@StockActivity)
                localGame.createDataIntoFolder(newGame, gameTargetDir)
                Log.d(TAG, "Wrote .gameInfo into ${gameTargetDir.absolutePath}")

                withContext(Dispatchers.Main) {
                    stockViewModel.addGameDataDirectly(newGame)
                    stockViewModel.refreshGamesDirs(null)
                    isLoadingState = false
                    Log.i(TAG, "==> Successfully imported standalone game: $rawTitle")
                    Toast.makeText(this@StockActivity, "Game added: $rawTitle", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to import incoming game file: ${e.message}", e)
                withContext(Dispatchers.Main) {
                    isLoadingState = false
                    Toast.makeText(this@StockActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    private fun addGameInPlace(
        folder: DocumentFile,
        title: String,
        author: String,
        version: String
    ) {
        lifecycleScope.launch(Dispatchers.IO) {
            withContext(Dispatchers.Main) { isLoadingState = true }
            Log.i(TAG, "==> Starting in-place game registration for: '$title' at URI: ${folder.uri}")

            try {
                val gameFiles = mutableListOf<Uri>()
                var effectiveGameDir: DocumentFile = folder

                val files = folder.listFiles()
                if (files != null) {
                    files.forEach { file ->
                        val ext = FileUtil.documentWrap(file).extension.lowercase(Locale.ROOT)
                        if (ext.endsWith("qsp") || ext.endsWith("gam") || ext.endsWith("qsps") || ext.endsWith("aqsp")) {
                            gameFiles.add(file.uri)
                            Log.d(TAG, "Found executable game file: ${file.name} -> ${file.uri}")
                        }
                    }
                }

                // If not found in root, deep search up to 4 directory levels
                if (gameFiles.isEmpty()) {
                    val deepLoc = DirUtil.findGameFileDeep(folder, 4)
                    if (deepLoc != null) {
                        gameFiles.add(deepLoc.gameFile.uri)
                        effectiveGameDir = deepLoc.gameDir
                        Log.i(TAG, "Deep search found executable QSP: ${deepLoc.gameFile.name} in directory: ${deepLoc.gameDir.uri}")
                    }
                }

                // STRICT VALIDATION: If no playable QSP file found, abort and do not add to home screen!
                if (gameFiles.isEmpty()) {
                    Log.w(TAG, "No executable QSP file found in folder: ${folder.uri}")
                    withContext(Dispatchers.Main) {
                        isLoadingState = false
                        Toast.makeText(this@StockActivity, getString(R.string.errorNoQspFound), Toast.LENGTH_LONG).show()
                    }
                    return@launch
                }

                // Accurate full recursive size calculation (calculated once and saved)
                val accurateSize = DirUtil.calculateDirSize(folder)

                val finalTitle = title.ifBlank { folder.name ?: "Untitled" }
                val newGame = GameData().apply {
                    this.id = folder.uri.hashCode().toLong()
                    this.title = finalTitle
                    this.author = author
                    this.version = version
                    this.gameDirUri = effectiveGameDir.uri
                    this.gameFilesUri = gameFiles
                    this.fileSize = if (accurateSize > 0) accurateSize else -1L
                }

                val localGame = LocalGame(this@StockActivity)
                val wroteInfo = localGame.tryCreateDataIntoFolder(folder, newGame)
                if (effectiveGameDir.uri != folder.uri) {
                    localGame.tryCreateDataIntoFolder(effectiveGameDir, newGame)
                }
                Log.d(TAG, "Wrote .gameInfo into folder result: $wroteInfo")

                stockViewModel.saveDirToFile(folder).join()
                Log.d(TAG, "Saved folder URI to external listDirsFile cache")

                withContext(Dispatchers.Main) {
                    stockViewModel.addGameDataDirectly(newGame)
                    stockViewModel.refreshGamesDirs(folder)
                    isLoadingState = false
                    Log.i(TAG, "==> Successfully registered in-place game '$finalTitle' with ${gameFiles.size} executable files!")
                    Toast.makeText(this@StockActivity, "Game added: $finalTitle", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error adding game in place: ${e.message}", e)
                withContext(Dispatchers.Main) {
                    isLoadingState = false
                    Toast.makeText(this@StockActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(downloadReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }
}

@Composable
private fun StockContent(
    viewModel: StockViewModel,
    isLoading: Boolean,
    onAddGameClicked: () -> Unit,
    onPlayGame: (GameData) -> Unit,
    onDeleteGame: (GameData) -> Unit,
    onDownloadGame: (GameData) -> Unit,
    showAddDialog: Boolean,
    pendingFolder: DocumentFile?,
    onDismissAddDialog: () -> Unit,
    onConfirmAddGame: (title: String, author: String, version: String) -> Unit,
    onExitApp: () -> Unit
) {
    val localGames by viewModel.localDataList.observeAsState(emptyList())
    val remoteGames by viewModel.remoteDataList.observeAsState(emptyList())
    var editingGame by remember { mutableStateOf<GameData?>(null) }

    StockMainScreen(
        localGames = localGames ?: emptyList(),
        remoteGames = remoteGames ?: emptyList(),
        isLoading = isLoading,
        onPlayGame = onPlayGame,
        onEditGame = { gameData -> editingGame = gameData },
        onDeleteGame = onDeleteGame,
        onDownloadGame = onDownloadGame,
        onAddGameClicked = onAddGameClicked,
        onExitApp = onExitApp,
        onToggleFavorite = { gameData -> viewModel.toggleFavorite(gameData) },
        onRefreshLocal = { viewModel.refreshGamesDirs(null) },
        onRefreshRemote = { viewModel.fetchRemoteRepository() }
    )

    if (showAddDialog && pendingFolder != null) {
        AddGameDialog(
            initialTitle = pendingFolder.name ?: "New Game",
            onDismiss = onDismissAddDialog,
            onSave = onConfirmAddGame
        )
    }

    editingGame?.let { targetGame ->
        EditGameDialog(
            game = targetGame,
            onDismiss = { editingGame = null },
            onSave = { title, author, version, iconUri ->
                targetGame.title = title
                targetGame.author = author
                targetGame.version = version
                targetGame.iconUrl = iconUri
                viewModel.saveGameData(targetGame)
                editingGame = null
            }
        )
    }
}
