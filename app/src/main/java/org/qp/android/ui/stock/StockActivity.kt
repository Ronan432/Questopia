package org.qp.android.ui.stock

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
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.core.content.IntentCompat
import androidx.compose.runtime.getValue
import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
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
        LocaleHelper.applyAppLanguage(this)
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.auto(
                Color.TRANSPARENT,
                Color.TRANSPARENT
            ),
            navigationBarStyle = SystemBarStyle.auto(
                Color.TRANSPARENT,
                Color.TRANSPARENT
            )
        )

        stockViewModel = ViewModelProvider(this)[StockViewModel::class.java]

        Log.i(TAG, "StockActivity onCreate. Triggering initial refresh...")
        isLoadingState = true
        stockViewModel.refreshGamesDirs(null)
        isLoadingState = false

        handleIncomingIntent(intent)

        setContent {
            val prefs = PreferenceManager.getDefaultSharedPreferences(this)
            val themeMode = prefs.getString("themeMode", "system") ?: "system"
            QuestopiaTheme(themeMode = themeMode) {
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
                                    val files = docDir?.listFiles()
                                    val qspFile = files?.firstOrNull { f ->
                                        val name = f.name?.lowercase(Locale.ROOT) ?: ""
                                        name.endsWith(".qsp") || name.endsWith(".gam")
                                    }
                                    chosenUri = qspFile?.uri
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
                        stockViewModel.delEntryDirFromList(stockViewModel.tempList, gameData, stockViewModel.listDirsFile)
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
                    Toast.makeText(this@StockActivity, "Oyun eklendi: $rawTitle", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to import incoming game file: ${e.message}", e)
                withContext(Dispatchers.Main) {
                    isLoadingState = false
                    Toast.makeText(this@StockActivity, "Hata: ${e.message}", Toast.LENGTH_LONG).show()
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
                val files = folder.listFiles()
                val gameFiles = mutableListOf<Uri>()
                var computedSize = 0L

                files.forEach { file ->
                    val ext = FileUtil.documentWrap(file).extension.lowercase(Locale.ROOT)
                    if (ext.endsWith("qsp") || ext.endsWith("gam") || ext.endsWith("qsps") || ext.endsWith("aqsp")) {
                        gameFiles.add(file.uri)
                        Log.d(TAG, "Found executable game file: ${file.name} -> ${file.uri}")
                    }
                    computedSize += file.length()
                }

                val finalTitle = title.ifBlank { folder.name ?: "Untitled" }
                val newGame = GameData().apply {
                    this.id = folder.uri.hashCode().toLong()
                    this.title = finalTitle
                    this.author = author
                    this.version = version
                    this.gameDirUri = folder.uri
                    this.gameFilesUri = gameFiles
                    this.fileSize = if (computedSize > 0) computedSize else -1L
                }

                val localGame = LocalGame(this@StockActivity)
                val wroteInfo = localGame.tryCreateDataIntoFolder(folder, newGame)
                Log.d(TAG, "Wrote .gameInfo into folder result: $wroteInfo")

                stockViewModel.saveDirToFile(folder).join()
                Log.d(TAG, "Saved folder URI to external listDirsFile cache")

                withContext(Dispatchers.Main) {
                    stockViewModel.addGameDataDirectly(newGame)
                    stockViewModel.refreshGamesDirs(folder)
                    isLoadingState = false
                    Log.i(TAG, "==> Successfully registered in-place game '$finalTitle' with ${gameFiles.size} executable files!")
                    Toast.makeText(this@StockActivity, "Oyun eklendi: $finalTitle", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error adding game in place: ${e.message}", e)
                withContext(Dispatchers.Main) {
                    isLoadingState = false
                    Toast.makeText(this@StockActivity, "Hata: ${e.message}", Toast.LENGTH_LONG).show()
                }
            }
        }
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
            onSave = { title, author, version ->
                targetGame.title = title
                targetGame.author = author
                targetGame.version = version
                viewModel.saveGameData(targetGame)
                editingGame = null
            }
        )
    }
}
