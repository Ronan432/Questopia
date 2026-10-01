package org.qp.android.ui.game

import android.util.Log
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
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
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
import androidx.compose.ui.window.DialogProperties
import androidx.core.text.HtmlCompat
import androidx.preference.PreferenceManager
import org.json.JSONObject
import com.libqsp.jni.QSPLib
import org.qp.android.R
import org.qp.android.ui.common.MorphingButton
import org.qp.android.ui.common.MorphingOutlinedButton
import org.qp.android.ui.common.MorphingSurface
import org.qp.android.ui.common.getGroupedItemShape

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
    val sheetBg = if (isAmoled) Color(0xFF000000) else MaterialTheme.colorScheme.surfaceContainerLow
    val cardBg = if (isAmoled) Color(0xFF0D0D0D) else MaterialTheme.colorScheme.surfaceContainer

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
            Toast.makeText(context, context.getString(R.string.cancelledRestored), Toast.LENGTH_SHORT).show()
        }
        viewModel.refreshGameUi()
        onDismiss()
    }

    BackHandler {
        handleRollbackAndClose()
    }

    // Navigation Tabs
    var selectedTab by remember { mutableIntStateOf(0) }
    val tabs = listOf(
        stringResource(R.string.cheatVariablesTab) to Icons.Outlined.EditNote,
        stringResource(R.string.cheatLocksTab) to Icons.Outlined.Lock,
        stringResource(R.string.cheatTeleportTab) to Icons.Outlined.Explore,
        stringResource(R.string.cheatInventoryTab) to Icons.Outlined.Inventory2,
        stringResource(R.string.cheatConsoleTab) to Icons.Outlined.Terminal,
        stringResource(R.string.cheatDiffTab) to Icons.Outlined.Difference
    )

    // Search state for variables & locations
    var searchQuery by remember { mutableStateOf("") }
    var filterType by remember { mutableIntStateOf(0) } // 0: All, 1: Numbers, 2: Strings, 3: Arrays

    // Frozen variables state
    val frozenMap = remember {
        mutableStateMapOf<String, String>().apply {
            val saved = prefs.getString(activity.frozenVariablesKey(), null)
            if (!saved.isNullOrBlank()) {
                runCatching {
                    val json = JSONObject(saved)
                    json.keys().forEach { key -> put(key, json.getString(key)) }
                }
            }
        }
    }

    // Local instant overrides for variables
    val localNumOverrides = remember { mutableStateMapOf<String, Long>() }
    val localStrOverrides = remember { mutableStateMapOf<String, String>() }

    // Item deletion confirmation
    var deletingObject by remember { mutableStateOf<QSPLib.ListItem?>(null) }

    fun persistLocks() {
        prefs.edit().putString(
            activity.frozenVariablesKey(),
            JSONObject(frozenMap as Map<*, *>).toString()
        ).apply()
        viewModel.setFrozenVariables(frozenMap)
    }
    LaunchedEffect(Unit) { viewModel.setFrozenVariables(frozenMap) }

    fun updateVarValue(item: QSPLib.VarItem, newNum: Long? = null, newStr: String? = null) {
        val varName = item.name()
        if (item.isString()) {
            val str = newStr ?: ""
            localStrOverrides[varName] = str
            val escaped = str.replace("'", "''")
            Log.d("CheatModesSheet", "Updating string var $varName = '$escaped'")
            viewModel.executeCode("$varName = '$escaped'")
            if (frozenMap.containsKey(varName)) {
                frozenMap[varName] = "'$escaped'"
                persistLocks()
            }
        } else {
            val num = newNum ?: 0L
            localNumOverrides[varName] = num
            Log.d("CheatModesSheet", "Updating numeric var $varName = $num")
            viewModel.executeCode("$varName = $num")
            if (frozenMap.containsKey(varName)) {
                frozenMap[varName] = num.toString()
                persistLocks()
            }
        }
    }

    // Edit Variable Dialog State
    var editingVar by remember { mutableStateOf<QSPLib.VarItem?>(null) }
    var editVarValue by remember { mutableStateOf("") }

    Dialog(
        onDismissRequest = { handleRollbackAndClose() },
        properties = DialogProperties(
            usePlatformDefaultWidth = false,
            decorFitsSystemWindows = true
        )
    ) {
        Surface(
            color = sheetBg,
            shape = RoundedCornerShape(20.dp),
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
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
                    Column {
                        Text(
                            text = stringResource(R.string.cheatModesTitle),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
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
                                contentDescription = stringResource(R.string.saveTitle),
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
                                contentDescription = stringResource(R.string.loadTitle),
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
                                OutlinedTextField(
                                    value = searchQuery,
                                    onValueChange = { searchQuery = it },
                                    placeholder = { Text(stringResource(R.string.variableSearchPlaceholder)) },
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

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    val filters = listOf(
                                        stringResource(R.string.filterAll),
                                        stringResource(R.string.filterNumbers),
                                        stringResource(R.string.filterStrings),
                                        stringResource(R.string.filterArrays)
                                    )
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
                                            text = stringResource(if (searchQuery.isBlank()) R.string.noVariablesFound else R.string.noMatchingVariables),
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
                                                overrideNum = localNumOverrides[v.name()],
                                                overrideStr = localStrOverrides[v.name()],
                                                onToggleFreeze = {
                                                    val varName = v.name()
                                                    if (frozenMap.containsKey(varName)) {
                                                        Log.d("CheatModesSheet", "Unfreezing variable: $varName")
                                                        frozenMap.remove(varName)
                                                    } else {
                                                        val valStr = if (v.isString()) {
                                                            val str = localStrOverrides[varName] ?: v.strValue() ?: ""
                                                            val escaped = str.replace("'", "''")
                                                            "'$escaped'"
                                                        } else {
                                                            val num = localNumOverrides[varName] ?: v.numValue()
                                                            num.toString()
                                                        }
                                                        Log.d("CheatModesSheet", "Freezing variable: $varName = $valStr")
                                                        frozenMap[varName] = valStr
                                                    }
                                                    persistLocks()
                                                },
                                                onQuickAddNum = { delta ->
                                                    val currentNum = localNumOverrides[v.name()] ?: v.numValue()
                                                    val newNum = currentNum + delta
                                                    updateVarValue(v, newNum = newNum)
                                                },
                                                onSetMaxNum = {
                                                    updateVarValue(v, newNum = 999999L)
                                                },
                                                onSetZero = {
                                                    if (v.isString()) {
                                                        updateVarValue(v, newStr = "")
                                                    } else {
                                                        updateVarValue(v, newNum = 0L)
                                                    }
                                                },
                                                onEditClick = {
                                                    editingVar = v
                                                    editVarValue = localStrOverrides[v.name()] ?: if (v.isString()) v.strValue() ?: "" else (localNumOverrides[v.name()] ?: v.numValue()).toString()
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
                                    text = stringResource(R.string.lockedVariablesTitle),
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
                                            text = stringResource(R.string.noLockedVariables),
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
                                                        Icon(Icons.Outlined.Lock, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                                                        Spacer(modifier = Modifier.width(10.dp))
                                                        Column {
                                                            Text(entry.key, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.bodyLarge)
                                                            Text(stringResource(R.string.lockedValue, entry.value), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.primary)
                                                        }
                                                    }
                                                    IconButton(
                                                        onClick = {
                                                            frozenMap.remove(entry.key)
                                                            persistLocks()
                                                        }
                                                    ) {
                                                        Icon(Icons.Outlined.Delete, contentDescription = stringResource(R.string.unlock), tint = MaterialTheme.colorScheme.error)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 3. Sahne / Lokasyon Atlama (Location Warper - Grouped Cards with Morph Shaping)
                        2 -> {
                            var locSearch by remember { mutableStateOf("") }
                            val filteredLocs = remember(locations, locSearch) {
                                locations.filter { it.contains(locSearch, ignoreCase = true) }
                            }

                            Column(modifier = Modifier.fillMaxSize()) {
                                OutlinedTextField(
                                    value = locSearch,
                                    onValueChange = { locSearch = it },
                                    placeholder = { Text(stringResource(R.string.locationSearchPlaceholder)) },
                                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                                    singleLine = true,
                                    shape = RoundedCornerShape(16.dp),
                                    modifier = Modifier.fillMaxWidth()
                                )

                                Spacer(modifier = Modifier.height(10.dp))

                                LazyColumn(
                                    modifier = Modifier.fillMaxSize(),
                                    verticalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    itemsIndexed(filteredLocs) { index, loc ->
                                        val shape = getGroupedItemShape(index, filteredLocs.size, outerRadius = 24.dp, innerRadius = 4.dp)
                                        MorphingSurface(
                                            shape = shape,
                                            color = cardBg,
                                            pressedRadius = 28.dp,
                                            onClick = {
                                                viewModel.executeCode("gt '$loc'")
                                                Toast.makeText(context, context.getString(R.string.locationTeleported, loc), Toast.LENGTH_SHORT).show()
                                                refreshState()
                                            },
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Row(
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .padding(horizontal = 16.dp, vertical = 12.dp),
                                                verticalAlignment = Alignment.CenterVertically,
                                                horizontalArrangement = Arrangement.SpaceBetween
                                            ) {
                                                Row(
                                                    verticalAlignment = Alignment.CenterVertically,
                                                    modifier = Modifier.weight(1f)
                                                ) {
                                                    Surface(
                                                        shape = CircleShape,
                                                        color = MaterialTheme.colorScheme.primaryContainer,
                                                        modifier = Modifier.size(36.dp)
                                                    ) {
                                                        Box(contentAlignment = Alignment.Center) {
                                                            Icon(
                                                                imageVector = Icons.Outlined.Place,
                                                                contentDescription = null,
                                                                tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                                                modifier = Modifier.size(20.dp)
                                                            )
                                                        }
                                                    }
                                                    Spacer(modifier = Modifier.width(12.dp))
                                                    Text(
                                                        text = loc,
                                                        style = MaterialTheme.typography.bodyLarge,
                                                        fontWeight = FontWeight.Bold,
                                                        color = MaterialTheme.colorScheme.onSurface,
                                                        maxLines = 1,
                                                        overflow = TextOverflow.Ellipsis
                                                    )
                                                }
                                                Icon(
                                                    imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                                                    contentDescription = null,
                                                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                                                )
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
                                        placeholder = { Text(stringResource(R.string.itemNamePlaceholder)) },
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
                                                Toast.makeText(context, context.getString(R.string.itemAddedToast), Toast.LENGTH_SHORT).show()
                                            }
                                        }
                                    ) {
                                        Text(stringResource(R.string.cheatAdd))
                                    }
                                }

                                Spacer(modifier = Modifier.height(10.dp))
                                Text(
                                    text = stringResource(R.string.inventoryCount, objectsList.size),
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
                                        Text(stringResource(R.string.emptyInventoryShort), color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    }
                                } else {
                                    LazyColumn(
                                        modifier = Modifier.weight(1f),
                                        verticalArrangement = Arrangement.spacedBy(4.dp)
                                    ) {
                                        itemsIndexed(objectsList) { index, item ->
                                            val shape = getGroupedItemShape(index, objectsList.size, outerRadius = 24.dp, innerRadius = 4.dp)
                                            val cleanName = remember(item.name()) {
                                                HtmlCompat.fromHtml(item.name(), HtmlCompat.FROM_HTML_MODE_LEGACY).toString().trim().ifEmpty { item.name() }
                                            }

                                            MorphingSurface(
                                                shape = shape,
                                                color = cardBg,
                                                pressedRadius = 28.dp,
                                                onClick = { deletingObject = item },
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
                                                        Surface(
                                                            shape = CircleShape,
                                                            color = MaterialTheme.colorScheme.primaryContainer,
                                                            modifier = Modifier.size(32.dp)
                                                        ) {
                                                            Box(contentAlignment = Alignment.Center) {
                                                                Icon(
                                                                    imageVector = Icons.Outlined.Category,
                                                                    contentDescription = null,
                                                                    tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                                                    modifier = Modifier.size(18.dp)
                                                                )
                                                            }
                                                        }
                                                        Spacer(modifier = Modifier.width(10.dp))
                                                        Text(
                                                            text = cleanName,
                                                            fontWeight = FontWeight.Medium,
                                                            color = MaterialTheme.colorScheme.onSurface,
                                                            maxLines = 1,
                                                            overflow = TextOverflow.Ellipsis
                                                        )
                                                    }
                                                    IconButton(
                                                        onClick = { deletingObject = item }
                                                    ) {
                                                        Icon(
                                                            imageVector = Icons.Outlined.Delete,
                                                            contentDescription = stringResource(R.string.deleteGameTitle),
                                                            tint = MaterialTheme.colorScheme.error
                                                        )
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
                                    text = stringResource(R.string.quickCheatPresets),
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
                                            consoleOutput = context.getString(R.string.executedMoney)
                                        },
                                        modifier = Modifier.weight(1f),
                                        shape = RoundedCornerShape(10.dp)
                                    ) {
                                        Text(stringResource(R.string.moneyPreset), fontSize = 11.sp)
                                    }
                                    FilledTonalButton(
                                        onClick = {
                                            viewModel.executeCode("DEBUG = 1")
                                            refreshState()
                                            consoleOutput = context.getString(R.string.executedDebug)
                                        },
                                        modifier = Modifier.weight(1f),
                                        shape = RoundedCornerShape(10.dp)
                                    ) {
                                        Text(stringResource(R.string.debugOn), fontSize = 11.sp)
                                    }
                                }

                                Spacer(modifier = Modifier.height(12.dp))

                                Text(
                                    text = stringResource(R.string.customQspCommand),
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
                                        placeholder = { Text(stringResource(R.string.commandPlaceholder)) },
                                        singleLine = true,
                                        shape = RoundedCornerShape(14.dp),
                                        modifier = Modifier.weight(1f)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    IconButton(
                                        onClick = {
                                            if (customCommand.isNotBlank()) {
                                                viewModel.executeCode(customCommand)
                                                consoleOutput = context.getString(R.string.executedCommand, customCommand)
                                                customCommand = ""
                                                refreshState()
                                            }
                                        }
                                    ) {
                                        Icon(Icons.AutoMirrored.Outlined.Send, contentDescription = stringResource(R.string.run), tint = MaterialTheme.colorScheme.primary)
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
                                    text = stringResource(R.string.changedSinceOpen),
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold
                                )
                                Spacer(modifier = Modifier.height(8.dp))

                                if (diffList.isEmpty()) {
                                    Box(
                                        modifier = Modifier.fillMaxSize(),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(stringResource(R.string.noVariablesChanged), color = MaterialTheme.colorScheme.onSurfaceVariant)
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
                                                        Text(stringResource(R.string.oldValue, origVal), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
                                                        Text(stringResource(R.string.newValue, curVal), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
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
                        Text(stringResource(R.string.cancelAndReturn))
                    }

                    MorphingButton(
                        onClick = {
                            isAppliedOrSaved = true
                            viewModel.refreshGameUi()
                            Toast.makeText(context, context.getString(R.string.cheatApplied), Toast.LENGTH_SHORT).show()
                            onDismiss()
                        },
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(stringResource(R.string.applyAndSave))
                    }
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
                        text = stringResource(R.string.editVariable),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
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
                        label = { Text(stringResource(if (targetVar.isString()) R.string.textValue else R.string.numericValue)) },
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
                            Text(stringResource(R.string.editCancel))
                        }
                        Spacer(modifier = Modifier.width(8.dp))
                        MorphingButton(
                            onClick = {
                                if (targetVar.isString()) {
                                    updateVarValue(targetVar, newStr = editVarValue)
                                } else {
                                    val num = editVarValue.toLongOrNull() ?: 0L
                                    updateVarValue(targetVar, newNum = num)
                                }
                                editingVar = null
                            }
                        ) {
                            Text(stringResource(R.string.confirm))
                        }
                    }
                }
            }
        }
    }

    // Inventory Item Deletion Confirmation Dialog
    if (deletingObject != null) {
        val targetItem = deletingObject!!
        val cleanName = remember(targetItem.name()) {
            HtmlCompat.fromHtml(targetItem.name(), HtmlCompat.FROM_HTML_MODE_LEGACY).toString().trim().ifEmpty { targetItem.name() }
        }
        AlertDialog(
            onDismissRequest = { deletingObject = null },
            title = {
                Text(
                    text = stringResource(R.string.deleteGameTitle),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
            },
            text = {
                Text(
                    text = "'$cleanName' eşyasını envanterden silmek istediğinize emin misiniz?",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            },
            confirmButton = {
                MorphingButton(
                    onClick = {
                        viewModel.executeCode("delobj '${targetItem.name()}'")
                        deletingObject = null
                    }
                ) {
                    Text(stringResource(R.string.deleteGameTitle))
                }
            },
            dismissButton = {
                MorphingOutlinedButton(
                    onClick = { deletingObject = null }
                ) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }
}

@Composable
fun VariableCard(
    item: QSPLib.VarItem,
    cardBg: Color,
    isFrozen: Boolean,
    overrideNum: Long? = null,
    overrideStr: String? = null,
    onToggleFreeze: () -> Unit,
    onQuickAddNum: (Long) -> Unit,
    onSetMaxNum: () -> Unit,
    onSetZero: () -> Unit,
    onEditClick: () -> Unit
) {
    val displayValue = if (item.isString()) {
        overrideStr ?: item.strValue()?.ifEmpty { "(Boş Metin)" } ?: "(Boş)"
    } else {
        (overrideNum ?: item.numValue()).toString()
    }

    Surface(
        shape = RoundedCornerShape(18.dp),
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
                        shape = CircleShape,
                        color = if (item.isString()) MaterialTheme.colorScheme.tertiaryContainer else MaterialTheme.colorScheme.primaryContainer,
                        modifier = Modifier.size(32.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text(
                                text = if (item.isString()) "$" else "#",
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                color = if (item.isString()) MaterialTheme.colorScheme.onTertiaryContainer else MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(10.dp))
                    Column {
                        Text(
                            text = item.name(),
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        if (item.count() > 1) {
                            Text(
                                text = stringResource(R.string.arrayItemCount, item.count()),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Surface(
                        shape = CircleShape,
                        color = if (isFrozen) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainerHigh,
                        modifier = Modifier
                            .size(32.dp)
                            .clip(CircleShape)
                            .clickable { onToggleFreeze() }
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = Icons.Outlined.Lock,
                                contentDescription = stringResource(if (isFrozen) R.string.unlock else R.string.lock),
                                tint = if (isFrozen) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }

                    Surface(
                        shape = CircleShape,
                        color = MaterialTheme.colorScheme.surfaceContainerHigh,
                        modifier = Modifier
                            .size(32.dp)
                            .clip(CircleShape)
                            .clickable { onEditClick() }
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = Icons.Outlined.Edit,
                                contentDescription = stringResource(R.string.editVariable),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Value Display
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.surfaceContainerHighest)
                    .clickable { onEditClick() }
                    .padding(horizontal = 14.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = displayValue,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                Text(
                    text = stringResource(R.string.changeValue),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Quick Number Buttons if numeric
            if (!item.isString() && item.count() <= 1) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    SuggestionChip(
                        onClick = { onQuickAddNum(100) },
                        label = { Text("+100", fontSize = 11.sp, fontWeight = FontWeight.SemiBold) },
                        shape = CircleShape,
                        modifier = Modifier.height(30.dp)
                    )
                    SuggestionChip(
                        onClick = { onQuickAddNum(1000) },
                        label = { Text("+1k", fontSize = 11.sp, fontWeight = FontWeight.SemiBold) },
                        shape = CircleShape,
                        modifier = Modifier.height(30.dp)
                    )
                    SuggestionChip(
                        onClick = { onQuickAddNum(10000) },
                        label = { Text("+10k", fontSize = 11.sp, fontWeight = FontWeight.SemiBold) },
                        shape = CircleShape,
                        modifier = Modifier.height(30.dp)
                    )
                    SuggestionChip(
                        onClick = { onSetMaxNum() },
                        label = { Text("MAX", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                        shape = CircleShape,
                        modifier = Modifier.height(30.dp)
                    )
                    SuggestionChip(
                        onClick = { onSetZero() },
                        label = { Text("0", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                        shape = CircleShape,
                        modifier = Modifier.height(30.dp)
                    )
                }
            }
        }
    }
}
