package org.qp.desktop.theme

import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// --- Monochrome Schemes (High Contrast Pure White & Deep Black) ---
private val MonochromeLight = lightColorScheme(
    primary = Color(0xFF000000),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFE8E8E8),
    onPrimaryContainer = Color(0xFF000000),
    secondary = Color(0xFF333333),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFEEEEEE),
    onSecondaryContainer = Color(0xFF000000),
    tertiary = Color(0xFF555555),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFE0E0E0),
    onTertiaryContainer = Color(0xFF111111),
    background = Color(0xFFFBFBFB),
    onBackground = Color(0xFF000000),
    surface = Color(0xFFFFFFFF),
    onSurface = Color(0xFF000000),
    surfaceVariant = Color(0xFFEEEEEE),
    onSurfaceVariant = Color(0xFF333333),
    surfaceContainer = Color(0xFFF4F4F4),
    surfaceContainerHigh = Color(0xFFEBEBEB),
    surfaceContainerLow = Color(0xFFFAFAFA),
    outline = Color(0xFF757575),
    outlineVariant = Color(0xFFD0D0D0)
)

private val MonochromeDark = darkColorScheme(
    primary = Color(0xFFFFFFFF),
    onPrimary = Color(0xFF000000),
    primaryContainer = Color(0xFFFFFFFF),
    onPrimaryContainer = Color(0xFF000000),
    secondary = Color(0xFFE0E0E0),
    onSecondary = Color(0xFF000000),
    secondaryContainer = Color(0xFF2C2C2C),
    onSecondaryContainer = Color(0xFFFFFFFF),
    tertiary = Color(0xFFD6D6D6),
    onTertiary = Color(0xFF000000),
    tertiaryContainer = Color(0xFF383838),
    onTertiaryContainer = Color(0xFFFFFFFF),
    background = Color(0xFF121214),
    onBackground = Color(0xFFFFFFFF),
    surface = Color(0xFF121214),
    onSurface = Color(0xFFFFFFFF),
    surfaceVariant = Color(0xFF252528),
    onSurfaceVariant = Color(0xFFE0E0E0),
    surfaceContainer = Color(0xFF1C1C1F),
    surfaceContainerHigh = Color(0xFF26262A),
    surfaceContainerLow = Color(0xFF161618),
    outline = Color(0xFF9E9E9E),
    outlineVariant = Color(0xFF3E3E42)
)

private val MonochromeAmoled = darkColorScheme(
    primary = Color(0xFFFFFFFF),
    onPrimary = Color(0xFF000000),
    primaryContainer = Color(0xFFFFFFFF),
    onPrimaryContainer = Color(0xFF000000),
    secondary = Color(0xFFE0E0E0),
    onSecondary = Color(0xFF000000),
    secondaryContainer = Color(0xFF1A1A1A),
    onSecondaryContainer = Color(0xFFFFFFFF),
    tertiary = Color(0xFFCCCCCC),
    onTertiary = Color(0xFF000000),
    tertiaryContainer = Color(0xFF242424),
    onTertiaryContainer = Color(0xFFFFFFFF),
    background = Color(0xFF000000),
    onBackground = Color(0xFFFFFFFF),
    surface = Color(0xFF000000),
    onSurface = Color(0xFFFFFFFF),
    surfaceVariant = Color(0xFF181818),
    onSurfaceVariant = Color(0xFFE0E0E0),
    surfaceContainer = Color(0xFF121212),
    surfaceContainerHigh = Color(0xFF1C1C1C),
    surfaceContainerLow = Color(0xFF080808),
    outline = Color(0xFF9E9E9E),
    outlineVariant = Color(0xFF2A2A2A)
)

// --- Preset Accent Palettes ---
private fun getPresetScheme(
    themeMode: String,
    primaryLight: Color,
    primaryContainerLight: Color,
    onPrimaryContainerLight: Color,
    primaryDark: Color,
    primaryContainerDark: Color,
    onPrimaryContainerDark: Color
): ColorScheme {
    return if (themeMode == "amoled") {
        darkColorScheme(
            primary = primaryDark,
            onPrimary = Color(0xFF001E30),
            primaryContainer = primaryDark,
            onPrimaryContainer = Color(0xFF000000),
            secondary = primaryDark.copy(alpha = 0.85f),
            onSecondary = Color(0xFF000000),
            secondaryContainer = Color(0xFF1A1A1A),
            onSecondaryContainer = Color(0xFFFFFFFF),
            background = Color(0xFF000000),
            onBackground = Color(0xFFFFFFFF),
            surface = Color(0xFF000000),
            onSurface = Color(0xFFFFFFFF),
            surfaceVariant = Color(0xFF161616),
            onSurfaceVariant = Color(0xFFDDDDDD),
            surfaceContainer = Color(0xFF101010),
            surfaceContainerHigh = Color(0xFF1A1A1A),
            surfaceContainerLow = Color(0xFF060606),
            outline = Color(0xFF8E8E8E),
            outlineVariant = Color(0xFF2A2A2A)
        )
    } else if (themeMode == "dark") {
        darkColorScheme(
            primary = primaryDark,
            onPrimary = Color(0xFF000000),
            primaryContainer = primaryContainerDark,
            onPrimaryContainer = onPrimaryContainerDark,
            secondary = primaryDark.copy(alpha = 0.85f),
            onSecondary = Color(0xFF000000),
            secondaryContainer = Color(0xFF2C2C30),
            onSecondaryContainer = onPrimaryContainerDark,
            background = Color(0xFF121214),
            onBackground = Color(0xFFFFFFFF),
            surface = Color(0xFF121214),
            onSurface = Color(0xFFFFFFFF),
            surfaceVariant = Color(0xFF26262A),
            onSurfaceVariant = Color(0xFFDDDDDD),
            surfaceContainer = Color(0xFF1C1C1F),
            surfaceContainerHigh = Color(0xFF27272C),
            surfaceContainerLow = Color(0xFF151518),
            outline = Color(0xFF8E8E8E),
            outlineVariant = Color(0xFF38383D)
        )
    } else {
        lightColorScheme(
            primary = primaryLight,
            onPrimary = Color(0xFFFFFFFF),
            primaryContainer = primaryContainerLight,
            onPrimaryContainer = onPrimaryContainerLight,
            secondary = primaryLight.copy(alpha = 0.85f),
            onSecondary = Color(0xFFFFFFFF),
            secondaryContainer = primaryContainerLight.copy(alpha = 0.6f),
            onSecondaryContainer = onPrimaryContainerLight,
            background = Color(0xFFFDFCFF),
            onBackground = Color(0xFF1A1C1E),
            surface = Color(0xFFFFFFFF),
            onSurface = Color(0xFF1A1C1E),
            surfaceVariant = Color(0xFFDFE2EB),
            onSurfaceVariant = Color(0xFF43474E),
            surfaceContainer = Color(0xFFF2F3F7),
            surfaceContainerHigh = Color(0xFFE8E9EE),
            surfaceContainerLow = Color(0xFFF8F9FD)
        )
    }
}

fun getDesktopColorScheme(
    themeMode: String,
    themeColor: String
): ColorScheme {
    val mode = if (themeMode == "light" || themeMode == "amoled") themeMode else "dark"

    return when (themeColor) {
        "monochrome" -> {
            when (mode) {
                "amoled" -> MonochromeAmoled
                "light" -> MonochromeLight
                else -> MonochromeDark
            }
        }
        "green" -> getPresetScheme(
            mode,
            Color(0xFF2E6C38), Color(0xFFB0F4B2), Color(0xFF002206),
            Color(0xFF95D797), Color(0xFF135322), Color(0xFFB0F4B2)
        )
        "purple" -> getPresetScheme(
            mode,
            Color(0xFF77539D), Color(0xFFF0DBFF), Color(0xFF2C0B4F),
            Color(0xFFDCB8FF), Color(0xFF5D3B83), Color(0xFFF0DBFF)
        )
        "orange" -> getPresetScheme(
            mode,
            Color(0xFF924C00), Color(0xFFFFDCC1), Color(0xFF301400),
            Color(0xFFFFB77B), Color(0xFF703700), Color(0xFFFFDCC1)
        )
        "red" -> getPresetScheme(
            mode,
            Color(0xFFB3261E), Color(0xFFF9DEDC), Color(0xFF410E0B),
            Color(0xFFF2B8B5), Color(0xFF8C1D18), Color(0xFFF9DEDC)
        )
        "pink" -> getPresetScheme(
            mode,
            Color(0xFF9B4061), Color(0xFFFFD9E2), Color(0xFF3E001D),
            Color(0xFFFFAFD0), Color(0xFF7D2949), Color(0xFFFFD9E2)
        )
        "teal" -> getPresetScheme(
            mode,
            Color(0xFF006A6A), Color(0xFF6FF7F6), Color(0xFF002020),
            Color(0xFF4DDAD9), Color(0xFF004F4F), Color(0xFF6FF7F6)
        )
        "amber" -> getPresetScheme(
            mode,
            Color(0xFF7C5800), Color(0xFFFFDEA5), Color(0xFF271900),
            Color(0xFFFBBD00), Color(0xFF5E4100), Color(0xFFFFDEA5)
        )
        else -> { // "blue" / default
            getPresetScheme(
                mode,
                Color(0xFF0061A4), Color(0xFFD1E4FF), Color(0xFF001D36),
                Color(0xFF9ECAFF), Color(0xFF00497D), Color(0xFFD1E4FF)
            )
        }
    }
}

@Composable
fun QuestopiaDesktopTheme(
    themeMode: String = "dark",
    themeColor: String = "monochrome",
    content: @Composable () -> Unit
) {
    val colorScheme = getDesktopColorScheme(
        themeMode = themeMode,
        themeColor = themeColor
    )

    MaterialTheme(
        colorScheme = colorScheme,
        content = content
    )
}
