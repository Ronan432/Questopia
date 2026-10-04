package org.qp.android.ui.theme

import android.app.Activity
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.core.view.WindowCompat
import androidx.preference.PreferenceManager

// ============================================================================
// 1. MONOCHROME (Pure Neutral Grayscale)
// ============================================================================
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
    surfaceContainerLowest = Color(0xFFFFFFFF),
    surfaceContainerLow = Color(0xFFFAFAFA),
    surfaceContainer = Color(0xFFF2F2F2),
    surfaceContainerHigh = Color(0xFFE6E6E6),
    surfaceContainerHighest = Color(0xFFDADADA),
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
    surfaceContainerLowest = Color(0xFF000000),
    surfaceContainerLow = Color(0xFF0A0A0A),
    surfaceContainer = Color(0xFF141414),
    surfaceContainerHigh = Color(0xFF1E1E1E),
    surfaceContainerHighest = Color(0xFF282828),
    outline = Color(0xFF8E8E8E),
    outlineVariant = Color(0xFF333333)
)

// ============================================================================
// 2. BLUE (Material 3 Baseline Palette)
// ============================================================================
private val BlueLight = lightColorScheme(
    primary = Color(0xFF0061A4),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFD1E4FF),
    onPrimaryContainer = Color(0xFF001D36),
    secondary = Color(0xFF535F70),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFD7E3F7),
    onSecondaryContainer = Color(0xFF101C2B),
    tertiary = Color(0xFF6B5778),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFF2DAFF),
    onTertiaryContainer = Color(0xFF251431),
    background = Color(0xFFF8F9FF),
    onBackground = Color(0xFF191C20),
    surface = Color(0xFFF8F9FF),
    onSurface = Color(0xFF191C20),
    surfaceVariant = Color(0xFFDFE2EB),
    onSurfaceVariant = Color(0xFF43474E),
    surfaceContainerLowest = Color(0xFFFFFFFF),
    surfaceContainerLow = Color(0xFFF2F3FA),
    surfaceContainer = Color(0xFFECEEF4),
    surfaceContainerHigh = Color(0xFFE7E8EE),
    surfaceContainerHighest = Color(0xFFE1E2E8),
    outline = Color(0xFF73777F),
    outlineVariant = Color(0xFFC3C7D0)
)

private val BlueDark = darkColorScheme(
    primary = Color(0xFF9ECAFF),
    onPrimary = Color(0xFF003258),
    primaryContainer = Color(0xFF00497D),
    onPrimaryContainer = Color(0xFFD1E4FF),
    secondary = Color(0xFFBBC7DB),
    onSecondary = Color(0xFF253140),
    secondaryContainer = Color(0xFF3B4858),
    onSecondaryContainer = Color(0xFFD7E3F7),
    tertiary = Color(0xFFD6BEE4),
    onTertiary = Color(0xFF3B2948),
    tertiaryContainer = Color(0xFF523F5F),
    onTertiaryContainer = Color(0xFFF2DAFF),
    background = Color(0xFF111418),
    onBackground = Color(0xFFE1E2E8),
    surface = Color(0xFF111418),
    onSurface = Color(0xFFE1E2E8),
    surfaceVariant = Color(0xFF43474E),
    onSurfaceVariant = Color(0xFFC3C7D0),
    surfaceContainerLowest = Color(0xFF0C0E13),
    surfaceContainerLow = Color(0xFF191C20),
    surfaceContainer = Color(0xFF1D2024),
    surfaceContainerHigh = Color(0xFF272A2F),
    surfaceContainerHighest = Color(0xFF32353A),
    outline = Color(0xFF8D9199),
    outlineVariant = Color(0xFF43474E)
)

private val BlueAmoled = BlueDark.copy(
    background = Color(0xFF000000),
    surface = Color(0xFF000000),
    surfaceContainerLowest = Color(0xFF000000),
    surfaceContainerLow = Color(0xFF0E1116),
    surfaceContainer = Color(0xFF14171D),
    surfaceContainerHigh = Color(0xFF1B1F26),
    surfaceContainerHighest = Color(0xFF232730)
)

// ============================================================================
// 3. GREEN (Material 3 Forest Palette)
// ============================================================================
private val GreenLight = lightColorScheme(
    primary = Color(0xFF2E6A3E),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFB0F2BA),
    onPrimaryContainer = Color(0xFF00210A),
    secondary = Color(0xFF516351),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFD4E8D2),
    onSecondaryContainer = Color(0xFF0F1F11),
    tertiary = Color(0xFF39656B),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFBCEBF1),
    onTertiaryContainer = Color(0xFF001F24),
    background = Color(0xFFF6FBF3),
    onBackground = Color(0xFF181D18),
    surface = Color(0xFFF6FBF3),
    onSurface = Color(0xFF181D18),
    surfaceVariant = Color(0xFFDEE5DA),
    onSurfaceVariant = Color(0xFF424941),
    surfaceContainerLowest = Color(0xFFFFFFFF),
    surfaceContainerLow = Color(0xFFF0F5ED),
    surfaceContainer = Color(0xFFEAEFE7),
    surfaceContainerHigh = Color(0xFFE5EAE2),
    surfaceContainerHighest = Color(0xFFDFE4DC),
    outline = Color(0xFF727970),
    outlineVariant = Color(0xFFC2C9BE)
)

private val GreenDark = darkColorScheme(
    primary = Color(0xFF95D5A0),
    onPrimary = Color(0xFF003915),
    primaryContainer = Color(0xFF145129),
    onPrimaryContainer = Color(0xFFB0F2BA),
    secondary = Color(0xFFB8CCB7),
    onSecondary = Color(0xFF233425),
    secondaryContainer = Color(0xFF3A4B3A),
    onSecondaryContainer = Color(0xFFD4E8D2),
    tertiary = Color(0xFFA1CED5),
    onTertiary = Color(0xFF00363C),
    tertiaryContainer = Color(0xFF1F4D53),
    onTertiaryContainer = Color(0xFFBCEBF1),
    background = Color(0xFF101510),
    onBackground = Color(0xFFDFE4DC),
    surface = Color(0xFF101510),
    onSurface = Color(0xFFDFE4DC),
    surfaceVariant = Color(0xFF424941),
    onSurfaceVariant = Color(0xFFC2C9BE),
    surfaceContainerLowest = Color(0xFF0B0F0B),
    surfaceContainerLow = Color(0xFF181D18),
    surfaceContainer = Color(0xFF1C211C),
    surfaceContainerHigh = Color(0xFF262C26),
    surfaceContainerHighest = Color(0xFF313631),
    outline = Color(0xFF8C9389),
    outlineVariant = Color(0xFF424941)
)

private val GreenAmoled = GreenDark.copy(
    background = Color(0xFF000000),
    surface = Color(0xFF000000),
    surfaceContainerLowest = Color(0xFF000000),
    surfaceContainerLow = Color(0xFF0D130E),
    surfaceContainer = Color(0xFF131913),
    surfaceContainerHigh = Color(0xFF1B221B),
    surfaceContainerHighest = Color(0xFF232B23)
)

// ============================================================================
// 4. PURPLE (Material 3 Orchid Palette)
// ============================================================================
private val PurpleLight = lightColorScheme(
    primary = Color(0xFF754B9E),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFF1DAFF),
    onPrimaryContainer = Color(0xFF2D0050),
    secondary = Color(0xFF665A6F),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFEDDEF6),
    onSecondaryContainer = Color(0xFF21182A),
    tertiary = Color(0xFF805158),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFFFD9DD),
    onTertiaryContainer = Color(0xFF321017),
    background = Color(0xFFFEF7FF),
    onBackground = Color(0xFF1D1A20),
    surface = Color(0xFFFEF7FF),
    onSurface = Color(0xFF1D1A20),
    surfaceVariant = Color(0xFFE8E0EB),
    onSurfaceVariant = Color(0xFF4A454E),
    surfaceContainerLowest = Color(0xFFFFFFFF),
    surfaceContainerLow = Color(0xFFF8F1FA),
    surfaceContainer = Color(0xFFF2ECF4),
    surfaceContainerHigh = Color(0xFFECE6EE),
    surfaceContainerHighest = Color(0xFFE6E0E9),
    outline = Color(0xFF7B757F),
    outlineVariant = Color(0xFFCBC4CF)
)

private val PurpleDark = darkColorScheme(
    primary = Color(0xFFDFB8FF),
    onPrimary = Color(0xFF44186C),
    primaryContainer = Color(0xFF5C3284),
    onPrimaryContainer = Color(0xFFF1DAFF),
    secondary = Color(0xFFD1C2DA),
    onSecondary = Color(0xFF362C3F),
    secondaryContainer = Color(0xFF4D4256),
    onSecondaryContainer = Color(0xFFEDDEF6),
    tertiary = Color(0xFFF3B7BF),
    onTertiary = Color(0xFF4B252B),
    tertiaryContainer = Color(0xFF653A41),
    onTertiaryContainer = Color(0xFFFFD9DD),
    background = Color(0xFF151218),
    onBackground = Color(0xFFE6E0E9),
    surface = Color(0xFF151218),
    onSurface = Color(0xFFE6E0E9),
    surfaceVariant = Color(0xFF4A454E),
    onSurfaceVariant = Color(0xFFCBC4CF),
    surfaceContainerLowest = Color(0xFF100D13),
    surfaceContainerLow = Color(0xFF1D1A20),
    surfaceContainer = Color(0xFF211E24),
    surfaceContainerHigh = Color(0xFF2C292F),
    surfaceContainerHighest = Color(0xFF37333A),
    outline = Color(0xFF958E99),
    outlineVariant = Color(0xFF4A454E)
)

private val PurpleAmoled = PurpleDark.copy(
    background = Color(0xFF000000),
    surface = Color(0xFF000000),
    surfaceContainerLowest = Color(0xFF000000),
    surfaceContainerLow = Color(0xFF120E15),
    surfaceContainer = Color(0xFF18131C),
    surfaceContainerHigh = Color(0xFF221C27),
    surfaceContainerHighest = Color(0xFF2C2532)
)

// ============================================================================
// 5. ORANGE (Material 3 Tangerine Palette)
// ============================================================================
private val OrangeLight = lightColorScheme(
    primary = Color(0xFF8B5000),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFFFDCBE),
    onPrimaryContainer = Color(0xFF2C1600),
    secondary = Color(0xFF735A42),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFFEDCBE),
    onSecondaryContainer = Color(0xFF2A1706),
    tertiary = Color(0xFF59633B),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFDDE9B5),
    onTertiaryContainer = Color(0xFF171E01),
    background = Color(0xFFFFF8F4),
    onBackground = Color(0xFF211A14),
    surface = Color(0xFFFFF8F4),
    onSurface = Color(0xFF211A14),
    surfaceVariant = Color(0xFFF2DFD1),
    onSurfaceVariant = Color(0xFF51443B),
    surfaceContainerLowest = Color(0xFFFFFFFF),
    surfaceContainerLow = Color(0xFFFBF2EB),
    surfaceContainer = Color(0xFFF5ECE5),
    surfaceContainerHigh = Color(0xFFEFE6DF),
    surfaceContainerHighest = Color(0xFFEAE0DA),
    outline = Color(0xFF83746A),
    outlineVariant = Color(0xFFD5C3B6)
)

private val OrangeDark = darkColorScheme(
    primary = Color(0xFFFFB870),
    onPrimary = Color(0xFF4A2800),
    primaryContainer = Color(0xFF693B00),
    onPrimaryContainer = Color(0xFFFFDCBE),
    secondary = Color(0xFFE2C0A5),
    onSecondary = Color(0xFF412C18),
    secondaryContainer = Color(0xFF59422C),
    onSecondaryContainer = Color(0xFFFEDCBE),
    tertiary = Color(0xFFC1CD9B),
    onTertiary = Color(0xFF2C3411),
    tertiaryContainer = Color(0xFF424B25),
    onTertiaryContainer = Color(0xFFDDE9B5),
    background = Color(0xFF18120D),
    onBackground = Color(0xFFEAE0DA),
    surface = Color(0xFF18120D),
    onSurface = Color(0xFFEAE0DA),
    surfaceVariant = Color(0xFF51443B),
    onSurfaceVariant = Color(0xFFD5C3B6),
    surfaceContainerLowest = Color(0xFF120D08),
    surfaceContainerLow = Color(0xFF211A14),
    surfaceContainer = Color(0xFF251E18),
    surfaceContainerHigh = Color(0xFF302822),
    surfaceContainerHighest = Color(0xFF3B332D),
    outline = Color(0xFF9E8E83),
    outlineVariant = Color(0xFF51443B)
)

private val OrangeAmoled = OrangeDark.copy(
    background = Color(0xFF000000),
    surface = Color(0xFF000000),
    surfaceContainerLowest = Color(0xFF000000),
    surfaceContainerLow = Color(0xFF140F0A),
    surfaceContainer = Color(0xFF1C150E),
    surfaceContainerHigh = Color(0xFF261E16),
    surfaceContainerHighest = Color(0xFF31271D)
)

// ============================================================================
// 6. RED (Material 3 Crimson Palette)
// ============================================================================
private val RedLight = lightColorScheme(
    primary = Color(0xFFB3261E),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFF9DEDC),
    onPrimaryContainer = Color(0xFF410E0B),
    secondary = Color(0xFF775652),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFFFDAD6),
    onSecondaryContainer = Color(0xFF2D1512),
    tertiary = Color(0xFF705B2E),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFFBDE97),
    onTertiaryContainer = Color(0xFF261900),
    background = Color(0xFFFFF8F6),
    onBackground = Color(0xFF231918),
    surface = Color(0xFFFFF8F6),
    onSurface = Color(0xFF231918),
    surfaceVariant = Color(0xFFF5DDDA),
    onSurfaceVariant = Color(0xFF534341),
    surfaceContainerLowest = Color(0xFFFFFFFF),
    surfaceContainerLow = Color(0xFFFDF1EE),
    surfaceContainer = Color(0xFFF7EBE8),
    surfaceContainerHigh = Color(0xFFF2E5E2),
    surfaceContainerHighest = Color(0xFFECE0DD),
    outline = Color(0xFF857371),
    outlineVariant = Color(0xFFD8C2BF)
)

private val RedDark = darkColorScheme(
    primary = Color(0xFFF2B8B5),
    onPrimary = Color(0xFF601410),
    primaryContainer = Color(0xFF8C1D18),
    onPrimaryContainer = Color(0xFFF9DEDC),
    secondary = Color(0xFFE7BDB7),
    onSecondary = Color(0xFF442926),
    secondaryContainer = Color(0xFF5D3F3B),
    onSecondaryContainer = Color(0xFFFFDAD6),
    tertiary = Color(0xFFDEC287),
    onTertiary = Color(0xFF3E2E04),
    tertiaryContainer = Color(0xFF564419),
    onTertiaryContainer = Color(0xFFFBDE97),
    background = Color(0xFF1A1110),
    onBackground = Color(0xFFECE0DD),
    surface = Color(0xFF1A1110),
    onSurface = Color(0xFFECE0DD),
    surfaceVariant = Color(0xFF534341),
    onSurfaceVariant = Color(0xFFD8C2BF),
    surfaceContainerLowest = Color(0xFF140C0B),
    surfaceContainerLow = Color(0xFF231918),
    surfaceContainer = Color(0xFF271D1C),
    surfaceContainerHigh = Color(0xFF322826),
    surfaceContainerHighest = Color(0xFF3E3231),
    outline = Color(0xFFA08C8A),
    outlineVariant = Color(0xFF534341)
)

private val RedAmoled = RedDark.copy(
    background = Color(0xFF000000),
    surface = Color(0xFF000000),
    surfaceContainerLowest = Color(0xFF000000),
    surfaceContainerLow = Color(0xFF150C0B),
    surfaceContainer = Color(0xFF1D1211),
    surfaceContainerHigh = Color(0xFF271A19),
    surfaceContainerHighest = Color(0xFF322321)
)

// ============================================================================
// 7. PINK (Material 3 Rose Palette)
// ============================================================================
private val PinkLight = lightColorScheme(
    primary = Color(0xFF984061),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFFFD9E2),
    onPrimaryContainer = Color(0xFF3E001D),
    secondary = Color(0xFF74565F),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFFFD9E2),
    onSecondaryContainer = Color(0xFF2B151C),
    tertiary = Color(0xFF7C5635),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFFFDCC1),
    onTertiaryContainer = Color(0xFF2E1500),
    background = Color(0xFFFFF8F8),
    onBackground = Color(0xFF22191C),
    surface = Color(0xFFFFF8F8),
    onSurface = Color(0xFF22191C),
    surfaceVariant = Color(0xFFF2DDE1),
    onSurfaceVariant = Color(0xFF514347),
    surfaceContainerLowest = Color(0xFFFFFFFF),
    surfaceContainerLow = Color(0xFFFCF1F3),
    surfaceContainer = Color(0xFFF6EBED),
    surfaceContainerHigh = Color(0xFFF1E5E8),
    surfaceContainerHighest = Color(0xFFEBE0E2),
    outline = Color(0xFF837377),
    outlineVariant = Color(0xFFD5C2C6)
)

private val PinkDark = darkColorScheme(
    primary = Color(0xFFFFB1C8),
    onPrimary = Color(0xFF5E1133),
    primaryContainer = Color(0xFF7B2949),
    onPrimaryContainer = Color(0xFFFFD9E2),
    secondary = Color(0xFFE2BDC6),
    onSecondary = Color(0xFF422931),
    secondaryContainer = Color(0xFF5B3F47),
    onSecondaryContainer = Color(0xFFFFD9E2),
    tertiary = Color(0xFFEFBD94),
    onTertiary = Color(0xFF472A0C),
    tertiaryContainer = Color(0xFF613F20),
    onTertiaryContainer = Color(0xFFFFDCC1),
    background = Color(0xFF191113),
    onBackground = Color(0xFFEBE0E2),
    surface = Color(0xFF191113),
    onSurface = Color(0xFFEBE0E2),
    surfaceVariant = Color(0xFF514347),
    onSurfaceVariant = Color(0xFFD5C2C6),
    surfaceContainerLowest = Color(0xFF130C0E),
    surfaceContainerLow = Color(0xFF22191C),
    surfaceContainer = Color(0xFF261D20),
    surfaceContainerHigh = Color(0xFF31272A),
    surfaceContainerHighest = Color(0xFF3C3235),
    outline = Color(0xFF9E8C90),
    outlineVariant = Color(0xFF514347)
)

private val PinkAmoled = PinkDark.copy(
    background = Color(0xFF000000),
    surface = Color(0xFF000000),
    surfaceContainerLowest = Color(0xFF000000),
    surfaceContainerLow = Color(0xFF150C0F),
    surfaceContainer = Color(0xFF1E1216),
    surfaceContainerHigh = Color(0xFF281B20),
    surfaceContainerHighest = Color(0xFF33242A)
)

// ============================================================================
// 8. TEAL (Material 3 Cyan/Marine Palette)
// ============================================================================
private val TealLight = lightColorScheme(
    primary = Color(0xFF006A6A),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFF70F7F6),
    onPrimaryContainer = Color(0xFF002020),
    secondary = Color(0xFF4A6363),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFCCE8E7),
    onSecondaryContainer = Color(0xFF051F1F),
    tertiary = Color(0xFF4B607C),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFD3E4FF),
    onTertiaryContainer = Color(0xFF041C35),
    background = Color(0xFFF4FBFA),
    onBackground = Color(0xFF161D1D),
    surface = Color(0xFFF4FBFA),
    onSurface = Color(0xFF161D1D),
    surfaceVariant = Color(0xFFDAE5E4),
    onSurfaceVariant = Color(0xFF3F4948),
    surfaceContainerLowest = Color(0xFFFFFFFF),
    surfaceContainerLow = Color(0xFFEEF5F4),
    surfaceContainer = Color(0xFFE8EFEF),
    surfaceContainerHigh = Color(0xFFE2EAE9),
    surfaceContainerHighest = Color(0xFFDCE4E3),
    outline = Color(0xFF6F7978),
    outlineVariant = Color(0xFFBEC9C8)
)

private val TealDark = darkColorScheme(
    primary = Color(0xFF4DDADA),
    onPrimary = Color(0xFF003737),
    primaryContainer = Color(0xFF004F4F),
    onPrimaryContainer = Color(0xFF70F7F6),
    secondary = Color(0xFFB0CCCC),
    onSecondary = Color(0xFF1B3435),
    secondaryContainer = Color(0xFF324B4B),
    onSecondaryContainer = Color(0xFFCCE8E7),
    tertiary = Color(0xFFB3C8E9),
    onTertiary = Color(0xFF1C314B),
    tertiaryContainer = Color(0xFF334863),
    onTertiaryContainer = Color(0xFFD3E4FF),
    background = Color(0xFF0E1515),
    onBackground = Color(0xFFDCE4E3),
    surface = Color(0xFF0E1515),
    onSurface = Color(0xFFDCE4E3),
    surfaceVariant = Color(0xFF3F4948),
    onSurfaceVariant = Color(0xFFBEC9C8),
    surfaceContainerLowest = Color(0xFF090F0F),
    surfaceContainerLow = Color(0xFF161D1D),
    surfaceContainer = Color(0xFF1A2121),
    surfaceContainerHigh = Color(0xFF252B2B),
    surfaceContainerHighest = Color(0xFF2F3636),
    outline = Color(0xFF899392),
    outlineVariant = Color(0xFF3F4948)
)

private val TealAmoled = TealDark.copy(
    background = Color(0xFF000000),
    surface = Color(0xFF000000),
    surfaceContainerLowest = Color(0xFF000000),
    surfaceContainerLow = Color(0xFF0C1414),
    surfaceContainer = Color(0xFF111A1A),
    surfaceContainerHigh = Color(0xFF192323),
    surfaceContainerHighest = Color(0xFF212D2D)
)

// ============================================================================
// 9. AMBER (Material 3 Gold/Honey Palette)
// ============================================================================
private val AmberLight = lightColorScheme(
    primary = Color(0xFF785900),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFFFDF9E),
    onPrimaryContainer = Color(0xFF261A00),
    secondary = Color(0xFF6B5D3F),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFF5E1BB),
    onSecondaryContainer = Color(0xFF241A04),
    tertiary = Color(0xFF4A6547),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFCCEBC4),
    onTertiaryContainer = Color(0xFF072109),
    background = Color(0xFFFFF8F1),
    onBackground = Color(0xFF1F1B13),
    surface = Color(0xFFFFF8F1),
    onSurface = Color(0xFF1F1B13),
    surfaceVariant = Color(0xFFEDE1CF),
    onSurfaceVariant = Color(0xFF4D4639),
    surfaceContainerLowest = Color(0xFFFFFFFF),
    surfaceContainerLow = Color(0xFFFBF2E6),
    surfaceContainer = Color(0xFFF5EDE0),
    surfaceContainerHigh = Color(0xFFEFE7DB),
    surfaceContainerHighest = Color(0xFFE9E1D5),
    outline = Color(0xFF7F7667),
    outlineVariant = Color(0xFFD0C5B4)
)

private val AmberDark = darkColorScheme(
    primary = Color(0xFFFABD00),
    onPrimary = Color(0xFF3F2E00),
    primaryContainer = Color(0xFF5B4300),
    onPrimaryContainer = Color(0xFFFFDF9E),
    secondary = Color(0xFFD8C5A1),
    onSecondary = Color(0xFF3B2F15),
    secondaryContainer = Color(0xFF53452A),
    onSecondaryContainer = Color(0xFFF5E1BB),
    tertiary = Color(0xFFB0CFAA),
    onTertiary = Color(0xFF1D361C),
    tertiaryContainer = Color(0xFF334D31),
    onTertiaryContainer = Color(0xFFCCEBC4),
    background = Color(0xFF17130B),
    onBackground = Color(0xFFE9E1D5),
    surface = Color(0xFF17130B),
    onSurface = Color(0xFFE9E1D5),
    surfaceVariant = Color(0xFF4D4639),
    onSurfaceVariant = Color(0xFFD0C5B4),
    surfaceContainerLowest = Color(0xFF110E07),
    surfaceContainerLow = Color(0xFF1F1B13),
    surfaceContainer = Color(0xFF241F17),
    surfaceContainerHigh = Color(0xFF2E2A21),
    surfaceContainerHighest = Color(0xFF39342B),
    outline = Color(0xFF999080),
    outlineVariant = Color(0xFF4D4639)
)

private val AmberAmoled = AmberDark.copy(
    background = Color(0xFF000000),
    surface = Color(0xFF000000),
    surfaceContainerLowest = Color(0xFF000000),
    surfaceContainerLow = Color(0xFF131008),
    surfaceContainer = Color(0xFF1B160D),
    surfaceContainerHigh = Color(0xFF241E14),
    surfaceContainerHighest = Color(0xFF2E271B)
)

// ============================================================================
// THEME RESOLUTION FUNCTION
// ============================================================================
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

    val normalizedColor = when (themeColor.lowercase()) {
        "dynamic", "0" -> "dynamic"
        "monochrome" -> "monochrome"
        "green" -> "green"
        "purple" -> "purple"
        "orange" -> "orange"
        "red" -> "red"
        "pink" -> "pink"
        "teal" -> "teal"
        "amber" -> "amber"
        "blue" -> "blue"
        else -> "dynamic"
    }

    return when (normalizedColor) {
        "monochrome" -> {
            when {
                normalizedMode == "amoled" -> MonochromeAmoled
                isDark -> MonochromeDark
                else -> MonochromeLight
            }
        }
        "blue" -> {
            when {
                normalizedMode == "amoled" -> BlueAmoled
                isDark -> BlueDark
                else -> BlueLight
            }
        }
        "green" -> {
            when {
                normalizedMode == "amoled" -> GreenAmoled
                isDark -> GreenDark
                else -> GreenLight
            }
        }
        "purple" -> {
            when {
                normalizedMode == "amoled" -> PurpleAmoled
                isDark -> PurpleDark
                else -> PurpleLight
            }
        }
        "orange" -> {
            when {
                normalizedMode == "amoled" -> OrangeAmoled
                isDark -> OrangeDark
                else -> OrangeLight
            }
        }
        "red" -> {
            when {
                normalizedMode == "amoled" -> RedAmoled
                isDark -> RedDark
                else -> RedLight
            }
        }
        "pink" -> {
            when {
                normalizedMode == "amoled" -> PinkAmoled
                isDark -> PinkDark
                else -> PinkLight
            }
        }
        "teal" -> {
            when {
                normalizedMode == "amoled" -> TealAmoled
                isDark -> TealDark
                else -> TealLight
            }
        }
        "amber" -> {
            when {
                normalizedMode == "amoled" -> AmberAmoled
                isDark -> AmberDark
                else -> AmberLight
            }
        }
        else -> { // "dynamic" - Material You Wallpaper / Dynamic Theme
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
                when {
                    normalizedMode == "amoled" -> BlueAmoled
                    isDark -> BlueDark
                    else -> BlueLight
                }
            }
        }
    }
}

fun getTypography(fontStyle: String): Typography {
    val fontFamily = when (fontStyle) {
        "1" -> FontFamily.Serif
        "2" -> FontFamily.Monospace
        "3", "4", "6", "7", "8", "9" -> FontFamily.SansSerif
        "5", "10" -> FontFamily.Cursive
        "11" -> FontFamily.Serif
        else -> FontFamily.Default
    }
    val weightOverride = when (fontStyle) {
        "3" -> FontWeight.Medium
        "4" -> FontWeight.Bold
        "6" -> FontWeight.Light
        "8" -> FontWeight.Black
        "9" -> FontWeight.Thin
        else -> null
    }

    val defaultTypography = Typography()
    fun TextStyle.applyFont(): TextStyle {
        return this.copy(
            fontFamily = fontFamily,
            fontWeight = weightOverride ?: this.fontWeight
        )
    }

    return Typography(
        displayLarge = defaultTypography.displayLarge.applyFont(),
        displayMedium = defaultTypography.displayMedium.applyFont(),
        displaySmall = defaultTypography.displaySmall.applyFont(),
        headlineLarge = defaultTypography.headlineLarge.applyFont(),
        headlineMedium = defaultTypography.headlineMedium.applyFont(),
        headlineSmall = defaultTypography.headlineSmall.applyFont(),
        titleLarge = defaultTypography.titleLarge.applyFont(),
        titleMedium = defaultTypography.titleMedium.applyFont(),
        titleSmall = defaultTypography.titleSmall.applyFont(),
        bodyLarge = defaultTypography.bodyLarge.applyFont(),
        bodyMedium = defaultTypography.bodyMedium.applyFont(),
        bodySmall = defaultTypography.bodySmall.applyFont(),
        labelLarge = defaultTypography.labelLarge.applyFont(),
        labelMedium = defaultTypography.labelMedium.applyFont(),
        labelSmall = defaultTypography.labelSmall.applyFont()
    )
}

@Composable
fun QuestopiaTheme(
    themeMode: String? = null,
    themeColor: String? = null,
    fontStyle: String? = null,
    content: @Composable () -> Unit
) {
    val context = LocalContext.current
    val systemInDark = isSystemInDarkTheme()
    val prefs = remember { PreferenceManager.getDefaultSharedPreferences(context) }

    var currentMode by remember { mutableStateOf(prefs.getString("themeMode", "system") ?: "system") }
    var currentColor by remember { mutableStateOf(prefs.getString("themeColor", "dynamic") ?: "dynamic") }
    var currentFontStyle by remember { mutableStateOf(prefs.getString("fontStyle", "0") ?: "0") }

    DisposableEffect(prefs) {
        val listener = SharedPreferences.OnSharedPreferenceChangeListener { sp, key ->
            when (key) {
                "themeMode" -> currentMode = sp.getString("themeMode", "system") ?: "system"
                "themeColor" -> currentColor = sp.getString("themeColor", "dynamic") ?: "dynamic"
                "fontStyle" -> currentFontStyle = sp.getString("fontStyle", "0") ?: "0"
            }
        }
        prefs.registerOnSharedPreferenceChangeListener(listener)
        onDispose {
            prefs.unregisterOnSharedPreferenceChangeListener(listener)
        }
    }

    val effectiveMode = themeMode ?: currentMode
    val effectiveColor = themeColor ?: currentColor
    val effectiveFontStyle = fontStyle ?: currentFontStyle

    val colorScheme = getColorScheme(
        themeMode = effectiveMode,
        themeColor = effectiveColor,
        context = context,
        systemInDark = systemInDark
    )
    val typography = getTypography(effectiveFontStyle)

    val view = LocalView.current
    if (!view.isInEditMode) {
        val normalizedMode = when (effectiveMode.lowercase()) {
            "1", "light" -> "light"
            "2", "dark" -> "dark"
            "3", "amoled" -> "amoled"
            else -> if (systemInDark) "dark" else "light"
        }
        val isDark = normalizedMode == "dark" || normalizedMode == "amoled"

        SideEffect {
            val window = (view.context as? Activity)?.window
            if (window != null) {
                WindowCompat.setDecorFitsSystemWindows(window, false)
                val insetsController = WindowCompat.getInsetsController(window, view)
                insetsController.isAppearanceLightStatusBars = !isDark
                insetsController.isAppearanceLightNavigationBars = !isDark
            }
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = typography,
        content = content
    )
}
