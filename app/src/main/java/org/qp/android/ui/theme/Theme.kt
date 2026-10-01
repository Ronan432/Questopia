package org.qp.android.ui.theme

import android.content.Context
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.preference.PreferenceManager

// --- Monochrome Schemes (High Contrast Black & White / Grayscale) ---
private val MonochromeLight = lightColorScheme(
    primary = Color(0xFF000000),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFE2E2E2),
    onPrimaryContainer = Color(0xFF000000),
    secondary = Color(0xFF424242),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFECECEC),
    onSecondaryContainer = Color(0xFF141414),
    tertiary = Color(0xFF616161),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFE0E0E0),
    onTertiaryContainer = Color(0xFF111111),
    background = Color(0xFFFFFFFF),
    onBackground = Color(0xFF000000),
    surface = Color(0xFFFFFFFF),
    onSurface = Color(0xFF000000),
    surfaceVariant = Color(0xFFE0E0E0),
    onSurfaceVariant = Color(0xFF424242),
    surfaceContainer = Color(0xFFF2F2F2),
    surfaceContainerHigh = Color(0xFFE6E6E6),
    surfaceContainerLow = Color(0xFFFAFAFA),
    outline = Color(0xFF757575),
    outlineVariant = Color(0xFFCCCCCC)
)

private val MonochromeDark = darkColorScheme(
    primary = Color(0xFFFFFFFF),
    onPrimary = Color(0xFF000000),
    primaryContainer = Color(0xFF333333),
    onPrimaryContainer = Color(0xFFFFFFFF),
    secondary = Color(0xFFCCCCCC),
    onSecondary = Color(0xFF000000),
    secondaryContainer = Color(0xFF242424),
    onSecondaryContainer = Color(0xFFEEEEEE),
    tertiary = Color(0xFFBDBDBD),
    onTertiary = Color(0xFF000000),
    tertiaryContainer = Color(0xFF333333),
    onTertiaryContainer = Color(0xFFEEEEEE),
    background = Color(0xFF121212),
    onBackground = Color(0xFFFFFFFF),
    surface = Color(0xFF121212),
    onSurface = Color(0xFFFFFFFF),
    surfaceVariant = Color(0xFF2C2C2C),
    onSurfaceVariant = Color(0xFFC7C7C7),
    surfaceContainerLowest = Color(0xFF0F0F0F),
    surfaceContainerLow = Color(0xFF181818),
    surfaceContainer = Color(0xFF1E1E1E),
    surfaceContainerHigh = Color(0xFF262626),
    surfaceContainerHighest = Color(0xFF303030),
    outline = Color(0xFF8E8E8E),
    outlineVariant = Color(0xFF484848)
)

private val MonochromeAmoled = darkColorScheme(
    primary = Color(0xFFFFFFFF),
    onPrimary = Color(0xFF000000),
    primaryContainer = Color(0xFF222222),
    onPrimaryContainer = Color(0xFFFFFFFF),
    secondary = Color(0xFFCCCCCC),
    onSecondary = Color(0xFF000000),
    secondaryContainer = Color(0xFF161616),
    onSecondaryContainer = Color(0xFFEEEEEE),
    tertiary = Color(0xFFBDBDBD),
    onTertiary = Color(0xFF000000),
    tertiaryContainer = Color(0xFF222222),
    onTertiaryContainer = Color(0xFFEEEEEE),
    background = Color(0xFF000000),
    onBackground = Color(0xFFFFFFFF),
    surface = Color(0xFF000000),
    onSurface = Color(0xFFFFFFFF),
    surfaceVariant = Color(0xFF1E1E1E),
    onSurfaceVariant = Color(0xFFCCCCCC),
    surfaceContainer = Color(0xFF141414),
    surfaceContainerHigh = Color(0xFF1E1E1E),
    surfaceContainerLow = Color(0xFF0A0A0A),
    outline = Color(0xFF8E8E8E),
    outlineVariant = Color(0xFF333333)
)

// --- Preset Accent Palettes ---
private fun getPresetScheme(
    themeMode: String,
    isDark: Boolean,
    primaryLight: Color,
    primaryContainerLight: Color,
    onPrimaryContainerLight: Color,
    primaryDark: Color,
    primaryContainerDark: Color,
    onPrimaryContainerDark: Color
): ColorScheme {
    return if (themeMode == "amoled" || themeMode == "3") {
        darkColorScheme(
            primary = primaryDark,
            onPrimary = Color(0xFF001E30),
            primaryContainer = primaryContainerDark,
            onPrimaryContainer = onPrimaryContainerDark,
            secondary = primaryDark.copy(alpha = 0.8f),
            onSecondary = Color(0xFF1A1A1A),
            secondaryContainer = Color(0xFF1E1E1E),
            onSecondaryContainer = onPrimaryContainerDark,
            background = Color(0xFF000000),
            onBackground = Color(0xFFEEEEEE),
            surface = Color(0xFF000000),
            onSurface = Color(0xFFEEEEEE),
            surfaceVariant = Color(0xFF1E1E1E),
            onSurfaceVariant = Color(0xFFCCCCCC),
            surfaceContainerLowest = Color(0xFF000000),
            surfaceContainerLow = Color(0xFF0A0A0A),
            surfaceContainer = Color(0xFF141414),
            surfaceContainerHigh = Color(0xFF1E1E1E),
            surfaceContainerHighest = Color(0xFF282828)
        )
    } else if (isDark) {
        darkColorScheme(
            primary = primaryDark,
            onPrimary = Color(0xFF003258),
            primaryContainer = primaryContainerDark,
            onPrimaryContainer = onPrimaryContainerDark,
            secondary = primaryDark.copy(alpha = 0.8f),
            onSecondary = Color(0xFF253140),
            secondaryContainer = Color(0xFF3B4858),
            onSecondaryContainer = onPrimaryContainerDark,
            background = Color(0xFF121212),
            onBackground = Color(0xFFE2E2E6),
            surface = Color(0xFF121212),
            onSurface = Color(0xFFE2E2E6),
            surfaceVariant = Color(0xFF2C2C2C),
            onSurfaceVariant = Color(0xFFC3C7D0),
            surfaceContainerLowest = Color(0xFF0F0F0F),
            surfaceContainerLow = Color(0xFF181818),
            surfaceContainer = Color(0xFF1E1E1E),
            surfaceContainerHigh = Color(0xFF262626),
            surfaceContainerHighest = Color(0xFF303030)
        )
    } else {
        lightColorScheme(
            primary = primaryLight,
            onPrimary = Color(0xFFFFFFFF),
            primaryContainer = primaryContainerLight,
            onPrimaryContainer = onPrimaryContainerLight,
            secondary = primaryLight.copy(alpha = 0.8f),
            onSecondary = Color(0xFFFFFFFF),
            secondaryContainer = primaryContainerLight.copy(alpha = 0.6f),
            onSecondaryContainer = onPrimaryContainerLight,
            background = Color(0xFFFDFCFF),
            onBackground = Color(0xFF1A1C1E),
            surface = Color(0xFFFDFCFF),
            onSurface = Color(0xFF1A1C1E),
            surfaceVariant = Color(0xFFDFE2EB),
            onSurfaceVariant = Color(0xFF43474E),
            surfaceContainer = Color(0xFFEDEEF2),
            surfaceContainerHigh = Color(0xFFE7E8EC),
            surfaceContainerLow = Color(0xFFF3F3F7)
        )
    }
}

fun getColorScheme(
    themeMode: String,
    themeColor: String,
    context: Context,
    systemInDark: Boolean
): ColorScheme {
    val normalizedMode = when (themeMode.lowercase()) {
        "1", "light" -> "light"
        "2", "dark" -> "dark"
        "3", "amoled" -> "amoled"
        "0", "system" -> "system"
        else -> themeMode.lowercase()
    }

    val isDark = when (normalizedMode) {
        "dark", "amoled" -> true
        "light" -> false
        else -> systemInDark
    }

    return when (themeColor) {
        "monochrome" -> {
            when (normalizedMode) {
                "amoled" -> MonochromeAmoled
                "dark" -> MonochromeDark
                "light" -> MonochromeLight
                else -> if (systemInDark) MonochromeDark else MonochromeLight
            }
        }
        "green" -> getPresetScheme(
            normalizedMode, isDark,
            Color(0xFF2E6C38), Color(0xFFB0F4B2), Color(0xFF002206),
            Color(0xFF95D797), Color(0xFF135322), Color(0xFFB0F4B2)
        )
        "purple" -> getPresetScheme(
            normalizedMode, isDark,
            Color(0xFF77539D), Color(0xFFF0DBFF), Color(0xFF2C0B4F),
            Color(0xFFDCB8FF), Color(0xFF5D3B83), Color(0xFFF0DBFF)
        )
        "orange" -> getPresetScheme(
            normalizedMode, isDark,
            Color(0xFF924C00), Color(0xFFFFDCC1), Color(0xFF301400),
            Color(0xFFFFB77B), Color(0xFF703700), Color(0xFFFFDCC1)
        )
        "red" -> getPresetScheme(
            normalizedMode, isDark,
            Color(0xFFB3261E), Color(0xFFF9DEDC), Color(0xFF410E0B),
            Color(0xFFF2B8B5), Color(0xFF8C1D18), Color(0xFFF9DEDC)
        )
        "pink" -> getPresetScheme(
            normalizedMode, isDark,
            Color(0xFF9B4061), Color(0xFFFFD9E2), Color(0xFF3E001D),
            Color(0xFFFFAFD0), Color(0xFF7D2949), Color(0xFFFFD9E2)
        )
        "teal" -> getPresetScheme(
            normalizedMode, isDark,
            Color(0xFF006A6A), Color(0xFF6FF7F6), Color(0xFF002020),
            Color(0xFF4DDAD9), Color(0xFF004F4F), Color(0xFF6FF7F6)
        )
        "amber" -> getPresetScheme(
            normalizedMode, isDark,
            Color(0xFF7C5800), Color(0xFFFFDEA5), Color(0xFF271900),
            Color(0xFFFBBD00), Color(0xFF5E4100), Color(0xFFFFDEA5)
        )
        "dynamic" -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (normalizedMode == "amoled") {
                    val dynamic = dynamicDarkColorScheme(context)
                    dynamic.copy(
                        background = Color(0xFF000000),
                        surface = Color(0xFF000000),
                        surfaceContainerLowest = Color(0xFF000000),
                        surfaceContainerLow = Color(0xFF0A0A0A),
                        surfaceContainer = Color(0xFF141414),
                        surfaceContainerHigh = Color(0xFF1E1E1E),
                        surfaceContainerHighest = Color(0xFF282828),
                        surfaceVariant = Color(0xFF1E1E1E)
                    )
                } else if (isDark) {
                    dynamicDarkColorScheme(context)
                } else {
                    dynamicLightColorScheme(context)
                }
            } else {
                getPresetScheme(
                    normalizedMode, isDark,
                    Color(0xFF0061A4), Color(0xFFD1E4FF), Color(0xFF001D36),
                    Color(0xFF9ECAFF), Color(0xFF00497D), Color(0xFFD1E4FF)
                )
            }
        }
        else -> { // "blue" / default
            getPresetScheme(
                normalizedMode, isDark,
                Color(0xFF0061A4), Color(0xFFD1E4FF), Color(0xFF001D36),
                Color(0xFF9ECAFF), Color(0xFF00497D), Color(0xFFD1E4FF)
            )
        }
    }
}

@Composable
fun QuestopiaTheme(
    themeMode: String? = null,
    themeColor: String? = null,
    content: @Composable () -> Unit
) {
    val context = LocalContext.current
    val systemInDark = isSystemInDarkTheme()
    val prefs = PreferenceManager.getDefaultSharedPreferences(context)

    val effectiveMode = themeMode ?: prefs.getString("themeMode", "system") ?: "system"
    val effectiveColor = themeColor ?: prefs.getString("themeColor", "monochrome") ?: "monochrome"

    val colorScheme = getColorScheme(
        themeMode = effectiveMode,
        themeColor = effectiveColor,
        context = context,
        systemInDark = systemInDark
    )

    MaterialTheme(
        colorScheme = colorScheme,
        content = content
    )
}
