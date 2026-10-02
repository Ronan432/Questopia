package org.qp.desktop.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import org.qp.desktop.model.DesktopGameItem
import org.qp.desktop.ui.common.DesktopMorphingSurface

@Composable
fun StockScreen(
    downloadedGameIds: Set<String>,
    onDownloadGame: (DesktopGameItem) -> Unit,
    onPlayDownloadedGame: (DesktopGameItem) -> Unit,
    modifier: Modifier = Modifier
) {
    var searchQuery by remember { mutableStateOf("") }

    val stockGames = remember {
        listOf(
            DesktopGameItem(
                id = "stock_1",
                title = "Labyrinth of Splendor",
                author = "Questopia Community",
                version = "1.2.0",
                description = "Solve mysterious puzzles in ancient dungeons and find the lost treasure.",
                gameFilePath = ""
            ),
            DesktopGameItem(
                id = "stock_2",
                title = "Night Shift",
                author = "T. Kara",
                version = "2.0.1",
                description = "A suspense and survival adventure set in an abandoned research station.",
                gameFilePath = ""
            ),
            DesktopGameItem(
                id = "stock_3",
                title = "Beyond Time",
                author = "E. Demir",
                version = "1.0.4",
                description = "An interactive story of a detective solving time-travel paradoxes.",
                gameFilePath = ""
            ),
            DesktopGameItem(
                id = "stock_4",
                title = "Interstellar Voyager",
                author = "CosmoStudio",
                version = "3.1.0",
                description = "Survival and starship management in an unknown galaxy.",
                gameFilePath = ""
            )
        )
    }

    val filteredList = remember(searchQuery) {
        if (searchQuery.isBlank()) stockGames
        else stockGames.filter {
            it.title.contains(searchQuery, ignoreCase = true) ||
            it.description.contains(searchQuery, ignoreCase = true)
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 28.dp, vertical = 24.dp)
    ) {
        // Top Toolbar
        OutlinedTextField(
            value = searchQuery,
            onValueChange = { searchQuery = it },
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("Katalogda ara...") },
            leadingIcon = {
                Icon(
                    Icons.Outlined.Search,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            },
            trailingIcon = {
                if (searchQuery.isNotBlank()) {
                    IconButton(onClick = { searchQuery = "" }) {
                        Icon(Icons.Default.Clear, contentDescription = "Temizle")
                    }
                }
            },
            singleLine = true,
            shape = CircleShape
        )

        Spacer(modifier = Modifier.height(24.dp))

        LazyVerticalGrid(
            columns = GridCells.Adaptive(minSize = 340.dp),
            horizontalArrangement = Arrangement.spacedBy(18.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
            modifier = Modifier.fillMaxSize()
        ) {
            items(filteredList, key = { it.id }) { game ->
                val isDownloaded = downloadedGameIds.contains(game.id)

                DesktopMorphingSurface(
                    onClick = {
                        if (isDownloaded) {
                            onPlayDownloadedGame(game)
                        } else {
                            onDownloadGame(game)
                        }
                    },
                    restingCorner = 22.dp,
                    pressedCorner = 30.dp,
                    color = MaterialTheme.colorScheme.surfaceContainer
                ) {
                    Column(modifier = Modifier.padding(18.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Surface(
                                shape = CircleShape,
                                color = MaterialTheme.colorScheme.tertiaryContainer,
                                modifier = Modifier.size(54.dp)
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Icon(
                                        imageVector = if (isDownloaded) Icons.Filled.CheckCircle else Icons.Filled.CloudDownload,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.onTertiaryContainer,
                                        modifier = Modifier.size(28.dp)
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.width(16.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = game.title,
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Text(
                                    text = "Yazar: ${game.author}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.outline
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = game.description,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        if (isDownloaded) {
                            Button(
                                onClick = { onPlayDownloadedGame(game) },
                                modifier = Modifier.fillMaxWidth(),
                                shape = CircleShape,
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.primary
                                )
                            ) {
                                Icon(Icons.Filled.PlayArrow, contentDescription = null, modifier = Modifier.size(18.dp))
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Oyna", fontWeight = FontWeight.Bold)
                            }
                        } else {
                            FilledTonalButton(
                                onClick = { onDownloadGame(game) },
                                modifier = Modifier.fillMaxWidth(),
                                shape = CircleShape
                            ) {
                                Icon(Icons.Filled.Download, contentDescription = null, modifier = Modifier.size(18.dp))
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("İndir", fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }
        }
    }
}
