package org.qp.desktop

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import org.qp.desktop.engine.DesktopQspEngine
import org.qp.desktop.model.DesktopAppSettings
import org.qp.desktop.model.DesktopGameItem
import org.qp.desktop.theme.QuestopiaDesktopTheme
import org.qp.desktop.ui.*
import java.io.File

@Composable
fun DesktopApp() {
    val engine = remember { DesktopQspEngine() }
    var currentScreen by remember { mutableStateOf(DesktopScreen.LIBRARY) }
    var settings by remember { mutableStateOf(DesktopAppSettings()) }
    var isRailExpanded by remember { mutableStateOf(true) }
    var activeGameId by remember { mutableStateOf<String?>("sample_quest") }
    var downloadedGameIds by remember { mutableStateOf(setOf("sample_quest")) }

    var gamesList by remember {
        mutableStateOf(
            listOf(
                DesktopGameItem(
                    id = "sample_quest",
                    title = "Questopia Başlangıç Macerası",
                    author = "Questopia Ekibi",
                    version = "1.0.0",
                    description = "QSP motorunun yeteneklerini ve interaktif metin dünyasını keşfet.",
                    gameFilePath = ""
                )
            )
        )
    }

    fun playSelectedGame(game: DesktopGameItem) {
        activeGameId = game.id
        val file = if (game.gameFilePath.isNotBlank()) File(game.gameFilePath) else null
        engine.loadAndStartGame(file)
        currentScreen = DesktopScreen.PLAYING
    }

    QuestopiaDesktopTheme(
        themeMode = settings.themeMode,
        themeColor = settings.themeColor
    ) {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            Row(modifier = Modifier.fillMaxSize()) {
                // Left Collapsible Navigation Rail with direct game launcher
                DesktopNavigationRail(
                    currentScreen = currentScreen,
                    onScreenSelected = { currentScreen = it },
                    games = gamesList,
                    activeGameId = activeGameId,
                    onDirectPlayGame = { game -> playSelectedGame(game) },
                    isExpanded = isRailExpanded,
                    onToggleExpand = { isRailExpanded = !isRailExpanded }
                )

                // Vertical Divider between Side Rail and Content
                VerticalDivider(
                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f),
                    thickness = 1.dp
                )

                // Right Main Screen Area
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .background(MaterialTheme.colorScheme.background)
                ) {
                    when (currentScreen) {
                        DesktopScreen.LIBRARY -> {
                            LibraryScreen(
                                games = gamesList,
                                onAddGame = { file ->
                                    val newGame = DesktopGameItem(
                                        id = file.absolutePath.hashCode().toString(),
                                        title = file.nameWithoutExtension,
                                        author = "Yerel Görev",
                                        version = "1.0.0",
                                        description = "Dosya konumu: ${file.absolutePath}",
                                        gameFilePath = file.absolutePath,
                                        folderPath = file.parentFile?.absolutePath ?: "",
                                        fileSizeBytes = file.length(),
                                        lastPlayedTime = System.currentTimeMillis()
                                    )
                                    gamesList = listOf(newGame) + gamesList.filter { it.gameFilePath != file.absolutePath }
                                    downloadedGameIds = downloadedGameIds + newGame.id
                                    playSelectedGame(newGame)
                                },
                                onPlayGame = { game ->
                                    playSelectedGame(game)
                                },
                                onDeleteGame = { game ->
                                    if (activeGameId == game.id) activeGameId = null
                                    gamesList = gamesList.filter { it.id != game.id }
                                }
                            )
                        }
                        DesktopScreen.STOCK -> {
                            StockScreen(
                                downloadedGameIds = downloadedGameIds,
                                onDownloadGame = { game ->
                                    downloadedGameIds = downloadedGameIds + game.id
                                    if (gamesList.none { it.id == game.id }) {
                                        gamesList = listOf(game) + gamesList
                                    }
                                },
                                onPlayDownloadedGame = { game ->
                                    playSelectedGame(game)
                                }
                            )
                        }
                        DesktopScreen.PLAYING -> {
                            GamePlayScreen(
                                engine = engine,
                                settings = settings,
                                onBackToLibrary = { currentScreen = DesktopScreen.LIBRARY }
                            )
                        }
                        DesktopScreen.SETTINGS -> {
                            SettingsScreen(
                                settings = settings,
                                onSettingsChanged = { settings = it }
                            )
                        }
                    }
                }
            }
        }
    }
}

fun main() {
    try {
        if (System.getProperty("skiko.renderApi") == null) {
            System.setProperty("skiko.renderApi", "VULKAN")
        }
    } catch (ignored: Throwable) {}

    application {
        Window(
            onCloseRequest = ::exitApplication,
            title = "Questopia Desktop",
            state = rememberWindowState(width = 1200.dp, height = 800.dp)
        ) {
            DesktopApp()
        }
    }
}
