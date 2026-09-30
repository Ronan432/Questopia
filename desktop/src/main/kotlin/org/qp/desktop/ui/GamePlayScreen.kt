package org.qp.desktop.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.qp.desktop.engine.DesktopQspEngine
import org.qp.desktop.model.DesktopAppSettings
import java.awt.FileDialog
import java.awt.Frame
import java.io.File

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GamePlayScreen(
    engine: DesktopQspEngine,
    settings: DesktopAppSettings,
    onBackToLibrary: () -> Unit,
    modifier: Modifier = Modifier
) {
    var mainDesc by remember { mutableStateOf("") }
    var varsDesc by remember { mutableStateOf("") }
    var actions by remember { mutableStateOf(listOf<String>()) }
    var objects by remember { mutableStateOf(listOf<String>()) }
    var userInputText by remember { mutableStateOf("") }
    var statusMessage by remember { mutableStateOf("Oyun Devam Ediyor") }

    val mainScrollState = rememberScrollState()

    fun refreshGameState() {
        try {
            mainDesc = engine.mainDesc ?: ""
            varsDesc = engine.varsDesc ?: ""
            val acts = engine.actions
            actions = acts?.map { it.name() } ?: emptyList()
            val objs = engine.objects
            objects = objs?.map { it.name() } ?: emptyList()
        } catch (e: Throwable) {
            statusMessage = "Hata: ${e.message}"
        }
    }

    LaunchedEffect(engine.activeGameFile) {
        engine.onStateUpdate = { refreshGameState() }
        refreshGameState()
    }

    // Dialog: Message Box
    engine.latestMessage?.let { msg ->
        AlertDialog(
            onDismissRequest = { engine.latestMessage = null },
            title = { Text("Oyun Mesajı") },
            text = { Text(msg) },
            confirmButton = {
                Button(onClick = { engine.latestMessage = null }) {
                    Text("Tamam")
                }
            },
            shape = RoundedCornerShape(16.dp)
        )
    }

    // Dialog: Input Box
    engine.activeInputBoxPrompt?.let { prompt ->
        var inputVal by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { engine.activeInputBoxPrompt = null },
            title = { Text("Girdi İsteği") },
            text = {
                Column {
                    Text(prompt)
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = inputVal,
                        onValueChange = { inputVal = it },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(onClick = {
                    engine.activeInputBoxPrompt = null
                    engine.inputBoxCallback?.invoke(inputVal)
                    engine.inputBoxCallback = null
                }) {
                    Text("Gönder")
                }
            },
            shape = RoundedCornerShape(16.dp)
        )
    }

    // Dialog: Select Menu
    engine.activeMenuOptions?.let { menuItems ->
        AlertDialog(
            onDismissRequest = { engine.activeMenuOptions = null },
            title = { Text("Seçim Yapın") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    menuItems.forEachIndexed { index, itemText ->
                        Surface(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(8.dp))
                                .clickable {
                                    engine.activeMenuOptions = null
                                    engine.menuCallback?.invoke(index)
                                    engine.menuCallback = null
                                    refreshGameState()
                                },
                            color = MaterialTheme.colorScheme.surfaceVariant
                        ) {
                            Text(
                                text = itemText,
                                modifier = Modifier.padding(12.dp),
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                    }
                }
            },
            confirmButton = {},
            shape = RoundedCornerShape(16.dp)
        )
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Game Top Bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onBackToLibrary) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Geri")
                }
                Spacer(modifier = Modifier.width(8.dp))
                Column {
                    Text(
                        text = engine.activeGameFile?.nameWithoutExtension ?: "Questopia",
                        style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = statusMessage,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.outline
                    )
                }
            }

            // In-Game Action Bar: Restart, Save, Load
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilledTonalIconButton(
                    onClick = {
                        val dialog = FileDialog(null as Frame?, "Kaydet (.sav)", FileDialog.SAVE)
                        dialog.file = "${engine.activeGameFile?.nameWithoutExtension ?: "save"}.sav"
                        dialog.isVisible = true
                        val file = dialog.file
                        val dir = dialog.directory
                        if (file != null && dir != null) {
                            val success = engine.saveGame(File(dir, file))
                            statusMessage = if (success) "Oyun kaydedildi!" else "Kayıt başarısız!"
                        }
                    }
                ) {
                    Icon(Icons.Outlined.Save, contentDescription = "Kaydet")
                }

                FilledTonalIconButton(
                    onClick = {
                        val dialog = FileDialog(null as Frame?, "Kayıt Dosyası Seç (.sav)", FileDialog.LOAD)
                        dialog.file = "*.sav"
                        dialog.isVisible = true
                        val file = dialog.file
                        val dir = dialog.directory
                        if (file != null && dir != null) {
                            val success = engine.loadSavedGame(File(dir, file))
                            statusMessage = if (success) "Kayıt yüklendi!" else "Yükleme başarısız!"
                            refreshGameState()
                        }
                    }
                ) {
                    Icon(Icons.Outlined.FileUpload, contentDescription = "Yükle")
                }

                FilledTonalIconButton(
                    onClick = {
                        engine.restartGame(true)
                        refreshGameState()
                        statusMessage = "Oyun yeniden başlatıldı"
                    }
                ) {
                    Icon(Icons.Outlined.RestartAlt, contentDescription = "Yeniden Başlat")
                }
            }
        }

        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f))
        Spacer(modifier = Modifier.height(12.dp))

        // Split Game View: Left Story/Stats (65%) | Right Actions/Inventory (35%)
        Row(
            modifier = Modifier.weight(1f).fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Left Column: Story Description & Variables
            Column(
                modifier = Modifier.weight(0.65f).fillMaxHeight()
            ) {
                // Main Story View
                Card(
                    modifier = Modifier.weight(0.7f).fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceContainer
                    )
                ) {
                    Box(modifier = Modifier.fillMaxSize().padding(18.dp)) {
                        Column(modifier = Modifier.verticalScroll(mainScrollState)) {
                            Text(
                                text = if (mainDesc.isBlank()) "Hikaye yükleniyor..." else mainDesc,
                                style = MaterialTheme.typography.bodyLarge.copy(
                                    fontSize = (settings.fontSize.toIntOrNull() ?: 16).sp,
                                    lineHeight = ((settings.fontSize.toIntOrNull() ?: 16) * 1.5).sp
                                ),
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Variables / Stats View
                Card(
                    modifier = Modifier.weight(0.3f).fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceContainerLow
                    )
                ) {
                    Box(modifier = Modifier.fillMaxSize().padding(14.dp)) {
                        Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
                            Text(
                                text = if (varsDesc.isBlank()) "Durum ve envanter bilgileri..." else varsDesc,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }

            // Right Column: Actions & Inventory
            Column(
                modifier = Modifier.weight(0.35f).fillMaxHeight(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Actions List Card
                Card(
                    modifier = Modifier.weight(0.6f).fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceContainer
                    )
                ) {
                    Column(modifier = Modifier.fillMaxSize().padding(14.dp)) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(bottom = 10.dp)
                        ) {
                            Icon(
                                Icons.Default.PlayArrow,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(Modifier.width(8.dp))
                            Text(
                                "Eylemler (${actions.size})",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold)
                            )
                        }

                        if (actions.isEmpty()) {
                            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                                Text(
                                    "Kullanılabilir eylem yok",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.outline
                                )
                            }
                        } else {
                            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                itemsIndexed(actions) { index, actionName ->
                                    Surface(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clip(RoundedCornerShape(10.dp))
                                            .clickable {
                                                engine.setSelActIndex(index, false)
                                                engine.execSelAction(true)
                                                refreshGameState()
                                            },
                                        color = MaterialTheme.colorScheme.primaryContainer,
                                        shape = RoundedCornerShape(10.dp)
                                    ) {
                                        Row(
                                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Text(
                                                text = "${index + 1}. $actionName",
                                                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium),
                                                color = MaterialTheme.colorScheme.onPrimaryContainer
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Inventory / Objects List Card
                Card(
                    modifier = Modifier.weight(0.4f).fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceContainerLow
                    )
                ) {
                    Column(modifier = Modifier.fillMaxSize().padding(14.dp)) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(bottom = 8.dp)
                        ) {
                            Icon(
                                Icons.Default.Inventory2,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.secondary,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(Modifier.width(8.dp))
                            Text(
                                "Envanter (${objects.size})",
                                style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold)
                            )
                        }

                        if (objects.isEmpty()) {
                            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                                Text(
                                    "Envanter boş",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.outline
                                )
                            }
                        } else {
                            LazyColumn(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                itemsIndexed(objects) { index, objName ->
                                    Surface(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clip(RoundedCornerShape(8.dp))
                                            .clickable {
                                                engine.setSelObjIndex(index, true)
                                                refreshGameState()
                                            },
                                        color = MaterialTheme.colorScheme.surface,
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text(
                                            text = objName,
                                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurface
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(10.dp))

        // Bottom User Input Box
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            OutlinedTextField(
                value = userInputText,
                onValueChange = { userInputText = it },
                modifier = Modifier.weight(1f),
                placeholder = { Text("Komut veya metin girin...") },
                singleLine = true,
                shape = RoundedCornerShape(16.dp)
            )

            Button(
                onClick = {
                    if (userInputText.isNotBlank()) {
                        engine.setInputStrText(userInputText)
                        engine.execUserInput(true)
                        userInputText = ""
                        refreshGameState()
                    }
                },
                shape = CircleShape,
                modifier = Modifier.height(52.dp),
                contentPadding = PaddingValues(horizontal = 24.dp)
            ) {
                Icon(Icons.Filled.Send, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text("Gönder", fontWeight = FontWeight.Bold)
            }
        }
    }
}
