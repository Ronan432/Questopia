package org.qp.android.ui.game

import android.widget.Toast
import androidx.activity.compose.BackHandler
import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.runtime.*
import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.preference.PreferenceManager
import com.libqsp.jni.QSPLib
import org.qp.android.R
import org.qp.android.ui.common.MorphingButton
import org.qp.android.ui.common.MorphingOutlinedButton

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CheatModesSheet(
    viewModel: GameViewModel,
    activity: GameActivity,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
    val isAmoled = prefs.getString("themeMode", "system") == "3" || prefs.getString("themeMode", "system") == "amoled"
    val sheetBg = if (isAmoled) Color(0xFF000000) else Color(0xFF121318)
    val cardBg = if (isAmoled) Color(0xFF0C0D10) else MaterialTheme.colorScheme.surfaceContainerHigh

    // 1. Initial Snapshot for 100% Rollback Safety
    val initialSnapshot = remember { viewModel.saveData }
    var isAppliedOrSaved by remember { mutableStateOf(false) }

    // Live State
    var variables by remember { mutableStateOf(viewModel.allVariables?.toList() ?: emptyList()) }
    var locations by remember { mutableStateOf(viewModel.allLocations?.toList() ?: emptyList()) }
    val objectsList by viewModel.objsListLiveData.observeAsState(emptyList())

    fun refreshState() {
        variables = viewModel.allVariables?.toList() ?: emptyList()
        locations = viewModel.allLocations?.toList() ?: emptyList()
    }

    // Rollback Handler
    fun handleRollbackAndClose() {
        if (!isAppliedOrSaved && initialSnapshot != null) {
            viewModel.loadSaveData(initialSnapshot)
            Toast.makeText(context, "Değişiklikler iptal edildi, eski kayıt geri yüklendi.", Toast.LENGTH_SHORT).show()
        }
        onDismiss()
    }

    BackHandler {
        handleRollbackAndClose()
    }

    // Navigation Tabs
    var selectedTab by remember { mutableIntStateOf(0) }
    val tabs = listOf(
        "Değişkenler" to Icons.Outlined.EditNote,
        "Dondurucu" to Icons.Outlined.AcUnit,
        "Işınlanma" to Icons.Outlined.Explore,
        "Envanter" to Icons.Outlined.Inventory2,
        "Konsol" to Icons.Outlined.Terminal,
        "Farklar" to Icons.Outlined.Difference
    )

    // Search state for variables & locations
    var searchQuery by remember { mutableStateOf("") }
    var filterType by remember { mutableIntStateOf(0) } // 0: All, 1: Numbers, 2: Strings, 3: Arrays

    // Frozen variables state
    val frozenMap = remember { mutableStateMapOf<String, String>() }

    // Edit Variable Dialog State
    var editingVar by remember { mutableStateOf<QSPLib.VarItem?>(null) }
    var editVarValue by remember { mutableStateOf("") }

    ModalBottomSheet(
        onDismissRequest = { handleRollbackAndClose() },
        containerColor = sheetBg,
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
        dragHandle = {
            BottomSheetDefaults.DragHandle(
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
            )
        },
        modifier = Modifier.fillMaxHeight(0.92f)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp)
        ) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(
                        shape = CircleShape,
                        color = MaterialTheme.colorScheme.primaryContainer,
                        modifier = Modifier.size(36.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = Icons.Outlined.Code,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(10.dp))
                    Column {
                        Text(
                            text = stringResource(R.string.cheatModesTitle),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = "Canlı Save & QSP Motor Editörü",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    // Export Save Button
                    FilledTonalIconButton(
                        onClick = {
                            isAppliedOrSaved = true
                            activity.startReadOrWriteSave(GameActivity.SAVE)
                        },
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Save,
                            contentDescription = "Save Kaydet",
                            modifier = Modifier.size(18.dp)
                        )
                    }

                    // Import Save Button
                    FilledTonalIconButton(
                        onClick = {
                            isAppliedOrSaved = true
                            activity.startReadOrWriteSave(GameActivity.LOAD)
                            refreshState()
                        },
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.FolderOpen,
                            contentDescription = "Save Yükle",
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }

            // Scrollable Tab Row
            ScrollableTabRow(
                selectedTabIndex = selectedTab,
                containerColor = Color.Transparent,
                contentColor = MaterialTheme.colorScheme.primary,
                edgePadding = 0.dp,
                divider = {},
                indicator = { tabPositions ->
                    TabRowDefaults.SecondaryIndicator(
                        Modifier.tabIndicatorOffset(tabPositions[selectedTab]),
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            ) {
                tabs.forEachIndexed { index, (label, icon) ->
                    Tab(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        text = {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(icon, contentDescription = null, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(label, fontSize = 13.sp, fontWeight = if (selectedTab == index) FontWeight.Bold else FontWeight.Normal)
                            }
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Tab Content
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
            ) {
                when (selectedTab) {
                    // 1. Değişken Editörü
                    0 -> {
                        Column(modifier = Modifier.fillMaxSize()) {
                            // Search bar
                            OutlinedTextField(
                                value = searchQuery,
                                onValueChange = { searchQuery = it },
                                placeholder = { Text("Değişken adı veya değer ara...") },
                                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                                trailingIcon = {
                                    if (searchQuery.isNotEmpty()) {
                                        IconButton(onClick = { searchQuery = "" }) {
                                            Icon(Icons.Default.Close, contentDescription = null)
                                        }
                                    }
                                },
                                singleLine = true,
                                shape = RoundedCornerShape(16.dp),
                                modifier = Modifier.fillMaxWidth()
                            )

                            Spacer(modifier = Modifier.height(8.dp))

                            // Filter Chips
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                val filters = listOf("Tümü", "Sayılar", "Metin ($)", "Diziler")
                                filters.forEachIndexed { idx, fLabel ->
                                    FilterChip(
                                        selected = filterType == idx,
                                        onClick = { filterType = idx },
                                        label = { Text(fLabel, fontSize = 12.sp) },
                                        shape = RoundedCornerShape(10.dp)
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(6.dp))

                            val filteredVars = remember(variables, searchQuery, filterType) {
                                variables.filter { item ->
                                    val nameMatch = item.name().contains(searchQuery, ignoreCase = true)
                                    val valMatch = if (item.isString()) {
                                        item.strValue()?.contains(searchQuery, ignoreCase = true) == true
                                    } else {
                                        item.numValue().toString().contains(searchQuery)
                                    }
                                    val matchesSearch = searchQuery.isBlank() || nameMatch || valMatch

                                    val matchesFilter = when (filterType) {
                                        1 -> !item.isString() && item.count() <= 1
                                        2 -> item.isString() && item.count() <= 1
                                        3 -> item.count() > 1
                                        else -> true
                                    }
                                    matchesSearch && matchesFilter
                                }
                            }

                            if (filteredVars.isEmpty()) {
                                Box(
                                    modifier = Modifier.fillMaxSize(),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = if (searchQuery.isBlank()) "Değişken bulunamadı" else "Aramaya uygun değişken yok",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            } else {
                                LazyColumn(
                                    modifier = Modifier.fillMaxSize(),
                                    contentPadding = PaddingValues(vertical = 4.dp),
                                    verticalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    items(filteredVars, key = { it.name() }) { v ->
                                        VariableCard(
                                            item = v,
                                            cardBg = cardBg,
                                            isFrozen = frozenMap.containsKey(v.name()),
                                            onToggleFreeze = {
                                                if (frozenMap.containsKey(v.name())) {
                                                    frozenMap.remove(v.name())
                                                } else {
                                                    val valStr = if (v.isString()) "'${v.strValue() ?: ""}'" else v.numValue().toString()
                                                    frozenMap[v.name()] = valStr
                                                }
                                                viewModel.setFrozenVariables(frozenMap)
                                            },
                                            onQuickAddNum = { delta ->
                                                val newNum = v.numValue() + delta
                                                viewModel.executeCode("${v.name()} = $newNum")
                                                refreshState()
                                            },
                                            onSetMaxNum = {
                                                viewModel.executeCode("${v.name()} = 999999")
                                                refreshState()
                                            },
                                            onSetZero = {
                                                if (v.isString()) {
                                                    viewModel.executeCode("${v.name()} = ''")
                                                } else {
                                                    viewModel.executeCode("${v.name()} = 0")
                                                }
                                                refreshState()
                                            },
                                            onEditClick = {
                                                editingVar = v
                                                editVarValue = if (v.isString()) v.strValue() ?: "" else v.numValue().toString()
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // 2. Değişken Dondurucu (Variable Freezer)
                    1 -> {
                        Column(modifier = Modifier.fillMaxSize()) {
                            Text(
                                text = "Kilitli Değişkenler (Her döngüde sabit tutulur)",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(bottom = 8.dp)
                            )

                            if (frozenMap.isEmpty()) {
                                Box(
                                    modifier = Modifier
                                        .weight(1f)
                                        .fillMaxWidth(),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = "Henüz kilitlenen değişken yok.\nDeğişkenler sekmesindeki kar tanesi (❄️) ikonuna dokunarak değişkenleri dondurabilirsiniz.",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            } else {
                                LazyColumn(
                                    modifier = Modifier.weight(1f),
                                    verticalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    items(frozenMap.entries.toList(), key = { it.key }) { entry ->
                                        Surface(
                                            shape = RoundedCornerShape(16.dp),
                                            color = cardBg,
                                            border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)),
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Row(
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .padding(12.dp),
                                                verticalAlignment = Alignment.CenterVertically,
                                                horizontalArrangement = Arrangement.SpaceBetween
                                            ) {
                                                Row(verticalAlignment = Alignment.CenterVertically) {
                                                    Icon(Icons.Outlined.AcUnit, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                                                    Spacer(modifier = Modifier.width(10.dp))
                                                    Column {
                                                        Text(entry.key, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.bodyLarge)
                                                        Text("Kilitli Değer: ${entry.value}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.primary)
                                                    }
                                                }
                                                IconButton(
                                                    onClick = {
                                                        frozenMap.remove(entry.key)
                                                        viewModel.setFrozenVariables(frozenMap)
                                                    }
                                                ) {
                                                    Icon(Icons.Outlined.Delete, contentDescription = "Kaldır", tint = MaterialTheme.colorScheme.error)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 3. Sahne / Lokasyon Atlama (Location Warper)
                    2 -> {
                        var locSearch by remember { mutableStateOf("") }
                        val filteredLocs = remember(locations, locSearch) {
                            locations.filter { it.contains(locSearch, ignoreCase = true) }
                        }

                        Column(modifier = Modifier.fillMaxSize()) {
                            OutlinedTextField(
                                value = locSearch,
                                onValueChange = { locSearch = it },
                                placeholder = { Text("Sahne / Lokasyon ara...") },
                                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                                singleLine = true,
                                shape = RoundedCornerShape(16.dp),
                                modifier = Modifier.fillMaxWidth()
                            )

                            Spacer(modifier = Modifier.height(8.dp))

                            LazyColumn(
                                modifier = Modifier.fillMaxSize(),
                                verticalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                items(filteredLocs) { loc ->
                                    Surface(
                                        shape = RoundedCornerShape(14.dp),
                                        color = cardBg,
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Row(
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .padding(horizontal = 14.dp, vertical = 10.dp),
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.SpaceBetween
                                        ) {
                                            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
                                                Icon(Icons.Outlined.Place, contentDescription = null, tint = MaterialTheme.colorScheme.secondary)
                                                Spacer(modifier = Modifier.width(8.dp))
                                                Text(
                                                    text = loc,
                                                    style = MaterialTheme.typography.bodyMedium,
                                                    fontWeight = FontWeight.Medium,
                                                    maxLines = 1,
                                                    overflow = TextOverflow.Ellipsis
                                                )
                                            }
                                            FilledTonalButton(
                                                onClick = {
                                                    viewModel.executeCode("gt '$loc'")
                                                    Toast.makeText(context, "$loc sahnesine ışınlanıldı!", Toast.LENGTH_SHORT).show()
                                                    refreshState()
                                                },
                                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                                                shape = RoundedCornerShape(10.dp)
                                            ) {
                                                Text("Işınlan", fontSize = 12.sp)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 4. Envanter & Eşya (Item Spawner)
                    3 -> {
                        var newItemName by remember { mutableStateOf("") }

                        Column(modifier = Modifier.fillMaxSize()) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                OutlinedTextField(
                                    value = newItemName,
                                    onValueChange = { newItemName = it },
                                    placeholder = { Text("Eşya adı (Örn: Altın Anahtar)") },
                                    singleLine = true,
                                    shape = RoundedCornerShape(14.dp),
                                    modifier = Modifier.weight(1f)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                MorphingButton(
                                    onClick = {
                                        if (newItemName.isNotBlank()) {
                                            viewModel.executeCode("addobj '$newItemName'")
                                            newItemName = ""
                                            Toast.makeText(context, "Eşya envantere eklendi!", Toast.LENGTH_SHORT).show()
                                        }
                                    }
                                ) {
                                    Text("Ekle")
                                }
                            }

                            Spacer(modifier = Modifier.height(10.dp))
                            Text(
                                text = "Mevcut Envanter (${objectsList.size} Eşya)",
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(6.dp))

                            if (objectsList.isEmpty()) {
                                Box(
                                    modifier = Modifier
                                        .weight(1f)
                                        .fillMaxWidth(),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text("Envanter boş.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            } else {
                                LazyColumn(
                                    modifier = Modifier.weight(1f),
                                    verticalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    itemsIndexed(objectsList) { _, item ->
                                        Surface(
                                            shape = RoundedCornerShape(14.dp),
                                            color = cardBg,
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Row(
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .padding(horizontal = 14.dp, vertical = 10.dp),
                                                verticalAlignment = Alignment.CenterVertically,
                                                horizontalArrangement = Arrangement.SpaceBetween
                                            ) {
                                                Row(verticalAlignment = Alignment.CenterVertically) {
                                                    Icon(Icons.Outlined.Category, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                                                    Spacer(modifier = Modifier.width(10.dp))
                                                    Text(item.name(), fontWeight = FontWeight.Medium)
                                                }
                                                IconButton(
                                                    onClick = {
                                                        viewModel.executeCode("delobj '${item.name()}'")
                                                    }
                                                ) {
                                                    Icon(Icons.Outlined.Delete, contentDescription = "Sil", tint = MaterialTheme.colorScheme.error)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 5. Hile Konsolu & Makrolar (Cheat Console)
                    4 -> {
                        var customCommand by remember { mutableStateOf("") }
                        var consoleOutput by remember { mutableStateOf("") }

                        Column(modifier = Modifier.fillMaxSize()) {
                            Text(
                                text = "Hızlı Hile Presetleri",
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(6.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                FilledTonalButton(
                                    onClick = {
                                        viewModel.executeCode("money += 100000 & gold += 100000")
                                        refreshState()
                                        consoleOutput = "Çalıştırıldı: +100.000 Para / Altın eklendi."
                                    },
                                    modifier = Modifier.weight(1f),
                                    shape = RoundedCornerShape(10.dp)
                                ) {
                                    Text("+100k Para", fontSize = 11.sp)
                                }
                                FilledTonalButton(
                                    onClick = {
                                        viewModel.executeCode("hp = 100 & health = 100 & energy = 100 & stamina = 100")
                                        refreshState()
                                        consoleOutput = "Çalıştırıldı: Can ve Enerji 100 yapıldı."
                                    },
                                    modifier = Modifier.weight(1f),
                                    shape = RoundedCornerShape(10.dp)
                                ) {
                                    Text("Full Can", fontSize = 11.sp)
                                }
                                FilledTonalButton(
                                    onClick = {
                                        viewModel.executeCode("DEBUG = 1")
                                        refreshState()
                                        consoleOutput = "Çalıştırıldı: DEBUG = 1 modu açıldı."
                                    },
                                    modifier = Modifier.weight(1f),
                                    shape = RoundedCornerShape(10.dp)
                                ) {
                                    Text("Debug Aç", fontSize = 11.sp)
                                }
                            }

                            Spacer(modifier = Modifier.height(12.dp))

                            Text(
                                text = "Özel QSP Kodu Çalıştır",
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(4.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                OutlinedTextField(
                                    value = customCommand,
                                    onValueChange = { customCommand = it },
                                    placeholder = { Text("Örn: money = 50000 & pl 'Hile Aktif'") },
                                    singleLine = true,
                                    shape = RoundedCornerShape(14.dp),
                                    modifier = Modifier.weight(1f)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                IconButton(
                                    onClick = {
                                        if (customCommand.isNotBlank()) {
                                            viewModel.executeCode(customCommand)
                                            consoleOutput = "Çalıştırıldı: $customCommand"
                                            customCommand = ""
                                            refreshState()
                                        }
                                    }
                                ) {
                                    Icon(Icons.AutoMirrored.Outlined.Send, contentDescription = "Çalıştır", tint = MaterialTheme.colorScheme.primary)
                                }
                            }

                            Spacer(modifier = Modifier.height(10.dp))

                            if (consoleOutput.isNotBlank()) {
                                Surface(
                                    shape = RoundedCornerShape(12.dp),
                                    color = cardBg,
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text(
                                        text = consoleOutput,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.padding(12.dp)
                                    )
                                }
                            }
                        }
                    }

                    // 6. Save Karşılaştırıcı (Save Diff)
                    5 -> {
                        val initialVars = remember(initialSnapshot) {
                            variables // snapshot of current when opened
                        }
                        val diffList = remember(variables) {
                            variables.filter { cur ->
                                val orig = initialVars.find { it.name() == cur.name() }
                                orig != null && (orig.numValue() != cur.numValue() || orig.strValue() != cur.strValue())
                            }
                        }

                        Column(modifier = Modifier.fillMaxSize()) {
                            Text(
                                text = "Menü Açılışından Bu Yana Değişen Değişkenler",
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(8.dp))

                            if (diffList.isEmpty()) {
                                Box(
                                    modifier = Modifier.fillMaxSize(),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text("Henüz hiçbir değişken değişmedi.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            } else {
                                LazyColumn(
                                    modifier = Modifier.fillMaxSize(),
                                    verticalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    items(diffList) { v ->
                                        val orig = initialVars.find { it.name() == v.name() }
                                        Surface(
                                            shape = RoundedCornerShape(14.dp),
                                            color = cardBg,
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Column(modifier = Modifier.padding(12.dp)) {
                                                Text(v.name(), fontWeight = FontWeight.Bold)
                                                Spacer(modifier = Modifier.height(2.dp))
                                                Row(
                                                    modifier = Modifier.fillMaxWidth(),
                                                    horizontalArrangement = Arrangement.SpaceBetween
                                                ) {
                                                    val origVal = if (orig?.isString() == true) orig.strValue() else orig?.numValue().toString()
                                                    val curVal = if (v.isString()) v.strValue() else v.numValue().toString()
                                                    Text("Eski: $origVal", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
                                                    Text("Yeni: $curVal", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Bottom Action Bar (Apply / Revert)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                MorphingOutlinedButton(
                    onClick = { handleRollbackAndClose() },
                    modifier = Modifier.weight(1f)
                ) {
                    Text("İptal & Geri Dön")
                }

                MorphingButton(
                    onClick = {
                        isAppliedOrSaved = true
                        Toast.makeText(context, "Değişiklikler oyuna uygulandı.", Toast.LENGTH_SHORT).show()
                        onDismiss()
                    },
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Uygula & Kaydet")
                }
            }
        }
    }

    // Edit Variable Modal Dialog
    if (editingVar != null) {
        val targetVar = editingVar!!
        Dialog(onDismissRequest = { editingVar = null }) {
            Surface(
                shape = RoundedCornerShape(24.dp),
                color = cardBg,
                tonalElevation = 6.dp,
                modifier = Modifier
                    .fillMaxWidth()
                    .wrapContentHeight()
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text(
                        text = "Değişkeni Düzenle",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = targetVar.name(),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.primary
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedTextField(
                        value = editVarValue,
                        onValueChange = { editVarValue = it },
                        label = { Text(if (targetVar.isString()) "Metin Değeri" else "Sayısal Değer") },
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End
                    ) {
                        TextButton(onClick = { editingVar = null }) {
                            Text("İptal")
                        }
                        Spacer(modifier = Modifier.width(8.dp))
                        MorphingButton(
                            onClick = {
                                if (targetVar.isString()) {
                                    val escaped = editVarValue.replace("'", "''")
                                    viewModel.executeCode("${targetVar.name()} = '$escaped'")
                                } else {
                                    val num = editVarValue.toLongOrNull() ?: 0L
                                    viewModel.executeCode("${targetVar.name()} = $num")
                                }
                                refreshState()
                                editingVar = null
                            }
                        ) {
                            Text("Tamam")
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun VariableCard(
    item: QSPLib.VarItem,
    cardBg: Color,
    isFrozen: Boolean,
    onToggleFreeze: () -> Unit,
    onQuickAddNum: (Long) -> Unit,
    onSetMaxNum: () -> Unit,
    onSetZero: () -> Unit,
    onEditClick: () -> Unit
) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = cardBg,
        border = if (isFrozen) BorderStroke(1.dp, MaterialTheme.colorScheme.primary) else null,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = if (item.isString()) MaterialTheme.colorScheme.tertiaryContainer else MaterialTheme.colorScheme.primaryContainer,
                        modifier = Modifier.size(28.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text(
                                text = if (item.isString()) "$" else "#",
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp,
                                color = if (item.isString()) MaterialTheme.colorScheme.onTertiaryContainer else MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Column {
                        Text(
                            text = item.name(),
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        if (item.count() > 1) {
                            Text(
                                text = "${item.count()} elemanlı dizi",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(
                        onClick = onToggleFreeze,
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.AcUnit,
                            contentDescription = "Dondur",
                            tint = if (isFrozen) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                            modifier = Modifier.size(18.dp)
                        )
                    }

                    IconButton(
                        onClick = onEditClick,
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Edit,
                            contentDescription = "Düzenle",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(6.dp))

            // Value Display
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(8.dp))
                    .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.5f))
                    .clickable { onEditClick() }
                    .padding(horizontal = 10.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = if (item.isString()) {
                        item.strValue()?.ifEmpty { "(Boş Metin)" } ?: "(Boş)"
                    } else {
                        item.numValue().toString()
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                Text(
                    text = "Değiştir",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.primary
                )
            }

            // Quick Number Buttons if numeric
            if (!item.isString() && item.count() <= 1) {
                Spacer(modifier = Modifier.height(6.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    SuggestionChip(
                        onClick = { onQuickAddNum(100) },
                        label = { Text("+100", fontSize = 11.sp) },
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.height(28.dp)
                    )
                    SuggestionChip(
                        onClick = { onQuickAddNum(1000) },
                        label = { Text("+1k", fontSize = 11.sp) },
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.height(28.dp)
                    )
                    SuggestionChip(
                        onClick = { onQuickAddNum(10000) },
                        label = { Text("+10k", fontSize = 11.sp) },
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.height(28.dp)
                    )
                    SuggestionChip(
                        onClick = { onSetMaxNum() },
                        label = { Text("MAX", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.height(28.dp)
                    )
                    SuggestionChip(
                        onClick = { onSetZero() },
                        label = { Text("0", fontSize = 11.sp) },
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.height(28.dp)
                    )
                }
            }
        }
    }
}
