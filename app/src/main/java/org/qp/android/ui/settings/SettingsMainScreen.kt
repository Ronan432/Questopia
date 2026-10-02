package org.qp.android.ui.settings
import androidx.compose.runtime.setValue
import androidx.compose.runtime.getValue

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import android.view.HapticFeedbackConstants
import org.qp.android.ui.common.ExpressiveSearchBar
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.VolumeOff
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.BlurOn
import androidx.compose.material.icons.outlined.Brightness4
import androidx.compose.material.icons.outlined.Code
import androidx.compose.material.icons.outlined.FormatSize
import androidx.compose.material.icons.outlined.Fullscreen
import androidx.compose.material.icons.outlined.ImageNotSupported
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material.icons.outlined.Style
import androidx.compose.material.icons.outlined.TableRows
import androidx.compose.material.icons.outlined.TextFields
import androidx.compose.material.icons.outlined.VerticalAlignBottom
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringArrayResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.preference.PreferenceManager
import org.qp.android.BuildConfig
import org.qp.android.R
import org.qp.android.helpers.utils.LocaleHelper

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsMainScreen(
    onBack: () -> Unit = {},
    searchQuery: String = "",
    isSearchActive: Boolean = false,
    showBackButton: Boolean = true,
    onSearchQueryChange: (String) -> Unit = {}
) {
    val context = LocalContext.current
    val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }
    val view = LocalView.current
    val focusManager = LocalFocusManager.current
    val searchFocusRequester = remember { FocusRequester() }

    // Dialog state
    var showAboutDialog by remember { mutableStateOf(false) }
    var showVersionDialog by remember { mutableStateOf(false) }

    // Search state
    var localSearchActive by remember { mutableStateOf(false) }
    var localSearchQuery by remember { mutableStateOf("") }

    // Preferences
    var themeMode by remember { mutableStateOf(prefs.getString("themeMode", "system") ?: "system") }
    var themeColor by remember { mutableStateOf(prefs.getString("themeColor", "monochrome") ?: "monochrome") }
    var lang by remember { mutableStateOf(LocaleHelper.getEffectiveLanguage(context)) }
    var separator by remember { mutableStateOf(prefs.getBoolean("separator", false)) }
    var immersiveMode by remember { mutableStateOf(prefs.getBoolean("immersiveMode", true)) }
    var autoscroll by remember { mutableStateOf(prefs.getBoolean("autoscroll", true)) }

    var fontStyle by remember { mutableStateOf(prefs.getString("fontStyle", "0") ?: "0") }
    var fontSize by remember { mutableStateOf(prefs.getString("fontSize", "16") ?: "16") }
    var isUseGameFont by remember { mutableStateOf(prefs.getBoolean("isUseGameFont", false)) }
    var textColor by remember { mutableIntStateOf(prefs.getInt("textColor", -16777216)) }

    var disableImage by remember { mutableStateOf(prefs.getBoolean("pref_disable_image", false)) }
    var permImgDialog by remember { mutableStateOf(prefs.getBoolean("permImgDialog", false)) }

    var isAudioPlay by remember { mutableStateOf(prefs.getBoolean("pref_audio_play", true)) }
    var isMuteVideo by remember { mutableStateOf(prefs.getBoolean("pref_mute_video", false)) }
    var enableCheats by remember { mutableStateOf(prefs.getBoolean("enableCheats", false)) }

    LaunchedEffect(localSearchActive) {
        if (localSearchActive) {
            searchFocusRequester.requestFocus()
        }
    }

    val activeQuery = localSearchQuery.ifBlank { searchQuery }

    fun matchQuery(title: String, subtitle: String? = null): Boolean {
        if (activeQuery.isBlank()) return true
        if (title.contains(activeQuery, ignoreCase = true)) return true
        if (subtitle != null && subtitle.contains(activeQuery, ignoreCase = true)) return true
        return false
    }

    // String resources
    val appThemeTitle = stringResource(R.string.appThemeTitle)
    val themeColorTitle = stringResource(R.string.themeColorTitle)
    val navBarBlurTitle = stringResource(R.string.navBarBlurTitle)
    val navBarBlurSum = stringResource(R.string.navBarBlurSum)
    val langTitle = stringResource(R.string.langTitle)
    val immTitle = stringResource(R.string.immersiveModeTitle)
    val sepTitle = stringResource(R.string.separatorTitle)
    val sepSum = stringResource(R.string.separatorSum)
    val autoTitle = stringResource(R.string.autoscrollTitle)
    val edgeFeedbackTitle = stringResource(R.string.edgeFeedbackTitle)
    val cheatsTitle = stringResource(R.string.cheatModesTitle)
    val cheatsSum = stringResource(R.string.cheatModesSummary)

    val styleTitle = stringResource(R.string.fontStyleTitle)
    val sizeTitle = stringResource(R.string.fontSizeTitle)
    val gameFontTitle = stringResource(R.string.useGameFontTitle)
    val txtColorTitle = stringResource(R.string.textColorTitle)

    val disableImgTitle = stringResource(R.string.pref_disable_image)
    val permTitle = stringResource(R.string.permImgDialogTitle)
    val fullScreenImageSum = stringResource(R.string.fullScreenImageSum)

    val playTitle = stringResource(R.string.pref_audio_play)
    val muteTitle = stringResource(R.string.pref_mute_video)

    val aboutTitle = stringResource(R.string.aboutTitle)
    val versionTitle = stringResource(R.string.versionInfoTitle)

    val langNames = stringArrayResource(R.array.langName).toList()
    val langValues = stringArrayResource(R.array.langValue).toList()
    val fontNames = stringArrayResource(R.array.fontName).toList()
    val fontValues = stringArrayResource(R.array.fontValue).toList()
    val fontSizes = stringArrayResource(R.array.fontSize).toList()

    val themeModeEntries = listOf(
        stringResource(R.string.themeModeSystem),
        stringResource(R.string.themeModeLight),
        stringResource(R.string.themeModeDark),
        stringResource(R.string.themeModeAmoled)
    )
    val themeModeValues = listOf("0", "1", "2", "3")

    val themeColorEntries = listOf(
        stringResource(R.string.themeColorDynamic),
        stringResource(R.string.themeColorBlue),
        stringResource(R.string.themeColorGreen),
        stringResource(R.string.themeColorOrange),
        stringResource(R.string.themeColorPurple),
        stringResource(R.string.themeColorPink),
        stringResource(R.string.themeColorTeal),
        stringResource(R.string.themeColorAmber),
        stringResource(R.string.themeColorMonochrome)
    )
    val themeColorValues = listOf(
        "dynamic", "blue", "green", "orange", "purple", "pink", "teal", "amber", "monochrome"
    )

    val nestedScrollConnection = remember {
        object : NestedScrollConnection {
            var topVibrated = false
            var bottomVibrated = false

            fun triggerVibration() {
                try {
                    val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        context.getSystemService(VibratorManager::class.java)?.defaultVibrator
                    } else {
                        @Suppress("DEPRECATION")
                        context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                    }
                    if (vibrator?.hasVibrator() == true) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            vibrator.vibrate(VibrationEffect.createOneShot(12L, 40))
                        } else {
                            @Suppress("DEPRECATION") vibrator.vibrate(12L)
                        }
                    }
                } catch (e: Exception) {
                    Log.e("QUEST_EDGE_VIBRATION", "Vibration error", e)
                }
            }

            override fun onPostScroll(
                consumed: Offset,
                available: Offset,
                source: NestedScrollSource
            ): Offset {
                if (available.y > 8f && !topVibrated) {
                    triggerVibration()
                    topVibrated = true
                } else if (available.y <= 0f) {
                    topVibrated = false
                }

                if (available.y < -8f && !bottomVibrated) {
                    triggerVibration()
                    bottomVibrated = true
                } else if (available.y >= 0f) {
                    bottomVibrated = false
                }

                return Offset.Zero
            }
        }
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.surface
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .nestedScroll(nestedScrollConnection),
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 0.dp, bottom = 120.dp)
        ) {
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 4.dp, bottom = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (showBackButton) {
                        Surface(
                            shape = CircleShape,
                            color = MaterialTheme.colorScheme.surfaceContainerHigh,
                            modifier = Modifier
                                .padding(end = 10.dp)
                                .size(48.dp)
                                .clip(CircleShape)
                                .clickable {
                                    view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                    onBack()
                                }
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                    contentDescription = stringResource(R.string.cancel),
                                    tint = MaterialTheme.colorScheme.onSurface,
                                    modifier = Modifier.size(22.dp)
                                )
                            }
                        }
                    }

                    ExpressiveSearchBar(
                        query = localSearchQuery,
                        onQueryChange = { localSearchQuery = it },
                        placeholderText = stringResource(R.string.searchSettingsPlaceholder),
                        isFocused = localSearchActive,
                        onFocusChanged = { localSearchActive = it },
                        focusRequester = searchFocusRequester,
                        onSearch = { focusManager.clearFocus() },
                        onCancel = {
                            localSearchActive = false
                            localSearchQuery = ""
                            focusManager.clearFocus()
                        },
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            // --- SECTION 1: Appearance & Language ---
            val showThemeMode = matchQuery(appThemeTitle) || activeQuery.isBlank()
            val showThemeColor = matchQuery(themeColorTitle) || activeQuery.isBlank()
            val showLang = matchQuery(langTitle)
            val showImm = matchQuery(immTitle)
            val showSep = matchQuery(sepTitle)
            val showAuto = matchQuery(autoTitle)
            val showCheats = matchQuery(cheatsTitle, cheatsSum)

            val appearanceItems = buildList<@Composable (Shape) -> Unit> {
                if (showThemeMode) {
                    add { shape ->
                        ExpressiveListPreferenceItem(
                            title = appThemeTitle,
                            entries = themeModeEntries,
                            entryValues = themeModeValues,
                            currentValue = themeMode,
                            shape = shape,
                            onValueSelected = { newTheme ->
                                themeMode = newTheme
                                prefs.edit().putString("themeMode", newTheme).apply()
                            },
                            icon = Icons.Outlined.Brightness4
                        )
                    }
                }
                if (showThemeColor) {
                    add { shape ->
                        ExpressiveListPreferenceItem(
                            title = themeColorTitle,
                            entries = themeColorEntries,
                            entryValues = themeColorValues,
                            currentValue = themeColor,
                            shape = shape,
                            onValueSelected = { newColor ->
                                themeColor = newColor
                                prefs.edit().putString("themeColor", newColor).apply()
                            },
                            icon = Icons.Outlined.Palette
                        )
                    }
                }
                if (showLang) {
                    add { shape ->
                        ExpressiveListPreferenceItem(
                            title = langTitle,
                            entries = langNames,
                            entryValues = langValues,
                            currentValue = lang,
                            shape = shape,
                            onValueSelected = { newLang ->
                                lang = newLang
                                prefs.edit().putString("lang", newLang).commit()
                                LocaleHelper.applyAppLanguage(context)
                            },
                            icon = Icons.Outlined.Language
                        )
                    }
                }
            }

            if (appearanceItems.isNotEmpty()) {
                item {
                    ExpressiveSettingsGroup(items = appearanceItems)
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }

            val generalItems = buildList<@Composable (Shape) -> Unit> {
                if (showImm) {
                    add { shape ->
                        ExpressiveSwitchPreferenceItem(
                            title = immTitle,
                            checked = immersiveMode,
                            shape = shape,
                            onCheckedChange = {
                                immersiveMode = it
                                prefs.edit().putBoolean("immersiveMode", it).apply()
                            },
                            icon = Icons.Outlined.Fullscreen
                        )
                    }
                }
                if (showSep) {
                    add { shape ->
                        ExpressiveSwitchPreferenceItem(
                            title = sepTitle,
                            checked = separator,
                            shape = shape,
                            onCheckedChange = {
                                separator = it
                                prefs.edit().putBoolean("separator", it).apply()
                            },
                            icon = Icons.Outlined.TableRows
                        )
                    }
                }
                if (showAuto) {
                    add { shape ->
                        ExpressiveSwitchPreferenceItem(
                            title = autoTitle,
                            checked = autoscroll,
                            shape = shape,
                            onCheckedChange = {
                                autoscroll = it
                                prefs.edit().putBoolean("autoscroll", it).apply()
                            },
                            icon = Icons.Outlined.VerticalAlignBottom
                        )
                    }
                }
                if (showCheats) {
                    add { shape ->
                        ExpressiveSwitchPreferenceItem(
                            title = cheatsTitle,
                            checked = enableCheats,
                            shape = shape,
                            onCheckedChange = {
                                enableCheats = it
                                prefs.edit().putBoolean("enableCheats", it).apply()
                            },
                            icon = Icons.Outlined.Code
                        )
                    }
                }
            }

            if (generalItems.isNotEmpty()) {
                item {
                    ExpressiveSettingsGroup(items = generalItems)
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }

            // --- SECTION 2: Typography & text ---
            val showStyle = matchQuery(styleTitle)
            val showSize = matchQuery(sizeTitle)
            val showGameFont = matchQuery(gameFontTitle)
            val showTxtColor = matchQuery(txtColorTitle)

            val section2Items = buildList<@Composable (Shape) -> Unit> {
                if (showStyle) {
                    add { shape ->
                        ExpressiveListPreferenceItem(
                            title = styleTitle,
                            entries = fontNames,
                            entryValues = fontValues,
                            currentValue = fontStyle,
                            shape = shape,
                            onValueSelected = {
                                fontStyle = it
                                prefs.edit().putString("fontStyle", it).apply()
                            },
                            icon = Icons.Outlined.Style
                        )
                    }
                }
                if (showSize) {
                    add { shape ->
                        ExpressiveListPreferenceItem(
                            title = sizeTitle,
                            entries = fontSizes,
                            entryValues = fontSizes,
                            currentValue = fontSize,
                            shape = shape,
                            onValueSelected = {
                                fontSize = it
                                prefs.edit().putString("fontSize", it).apply()
                            },
                            icon = Icons.Outlined.FormatSize
                        )
                    }
                }
                if (showGameFont) {
                    add { shape ->
                        ExpressiveSwitchPreferenceItem(
                            title = gameFontTitle,
                            checked = isUseGameFont,
                            shape = shape,
                            onCheckedChange = {
                                isUseGameFont = it
                                prefs.edit().putBoolean("isUseGameFont", it).apply()
                            },
                            icon = Icons.Outlined.TextFields
                        )
                    }
                }
                if (showTxtColor) {
                    add { shape ->
                        ExpressiveColorPreferenceItem(
                            title = txtColorTitle,
                            color = textColor,
                            shape = shape,
                            onColorSelected = {
                                textColor = it
                                prefs.edit().putInt("textColor", it).apply()
                            },
                            icon = Icons.Outlined.Palette
                        )
                    }
                }
            }

            if (section2Items.isNotEmpty()) {
                item {
                    ExpressiveSettingsGroup(items = section2Items)
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }

            // --- SECTION 3: Images & graphics ---
            val showDisableImg = matchQuery(disableImgTitle)
            val showPerm = matchQuery(permTitle)

            val section3Items = buildList<@Composable (Shape) -> Unit> {
                if (showDisableImg) {
                    add { shape ->
                        ExpressiveSwitchPreferenceItem(
                            title = disableImgTitle,
                            checked = disableImage,
                            shape = shape,
                            onCheckedChange = {
                                disableImage = it
                                prefs.edit().putBoolean("pref_disable_image", it).apply()
                            },
                            icon = Icons.Outlined.ImageNotSupported
                        )
                    }
                }
                if (showPerm) {
                    add { shape ->
                        ExpressiveSwitchPreferenceItem(
                            title = permTitle,
                            checked = permImgDialog,
                            shape = shape,
                            onCheckedChange = {
                                permImgDialog = it
                                prefs.edit().putBoolean("permImgDialog", it).apply()
                            },
                            icon = Icons.Outlined.Code
                        )
                    }
                }
            }

            if (section3Items.isNotEmpty()) {
                item {
                    ExpressiveSettingsGroup(items = section3Items)
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }

            // --- SECTION 4: Sound & media ---
            val showPlay = matchQuery(playTitle)
            val showMute = matchQuery(muteTitle)

            val section4Items = buildList<@Composable (Shape) -> Unit> {
                if (showPlay) {
                    add { shape ->
                        ExpressiveSwitchPreferenceItem(
                            title = playTitle,
                            checked = isAudioPlay,
                            shape = shape,
                            onCheckedChange = {
                                isAudioPlay = it
                                prefs.edit().putBoolean("pref_audio_play", it).apply()
                            },
                            icon = Icons.AutoMirrored.Outlined.VolumeUp
                        )
                    }
                }
                if (showMute) {
                    add { shape ->
                        ExpressiveSwitchPreferenceItem(
                            title = muteTitle,
                            checked = isMuteVideo,
                            shape = shape,
                            onCheckedChange = {
                                isMuteVideo = it
                                prefs.edit().putBoolean("pref_mute_video", it).apply()
                            },
                            icon = Icons.AutoMirrored.Outlined.VolumeOff
                        )
                    }
                }
            }

            if (section4Items.isNotEmpty()) {
                item {
                    ExpressiveSettingsGroup(items = section4Items)
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }

            // --- SECTION 5: Information & About ---
            val showAbout = matchQuery(aboutTitle)
            val showVer = matchQuery(versionTitle)

            val section5Items = buildList<@Composable (Shape) -> Unit> {
                if (showAbout) {
                    add { shape ->
                        ExpressivePreferenceItem(
                            title = aboutTitle,
                            shape = shape,
                            icon = Icons.Outlined.Info,
                            onClick = { showAboutDialog = true }
                        )
                    }
                }
                if (showVer) {
                    add { shape ->
                        ExpressivePreferenceItem(
                            title = stringResource(R.string.appVersionTitle, BuildConfig.VERSION_NAME),
                            shape = shape,
                            icon = Icons.Outlined.Code,
                            onClick = { showVersionDialog = true }
                        )
                    }
                }
            }

            if (section5Items.isNotEmpty()) {
                item {
                    ExpressiveSettingsGroup(items = section5Items)
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }

            // Empty state when search yields no matches
            if (generalItems.isEmpty() && section2Items.isEmpty() && section3Items.isEmpty() && section4Items.isEmpty() && section5Items.isEmpty() && activeQuery.isNotBlank()) {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 48.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(
                                imageVector = Icons.Default.Search,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f),
                                modifier = Modifier.size(48.dp)
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            Text(
                                text = stringResource(R.string.noSearchResults, activeQuery),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }

            item {
                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }

    if (showAboutDialog) {
        AboutDialog(onDismiss = { showAboutDialog = false })
    }

    if (showVersionDialog) {
        VersionDialog(onDismiss = { showVersionDialog = false })
    }
}
