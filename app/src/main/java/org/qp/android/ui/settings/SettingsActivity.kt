package org.qp.android.ui.settings

import android.content.Context
import android.graphics.Color
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.Composable
import androidx.preference.PreferenceManager
import org.qp.android.helpers.utils.LocaleHelper
import org.qp.android.ui.theme.QuestopiaTheme

class SettingsActivity : ComponentActivity() {

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

        setContent {
            val prefs = PreferenceManager.getDefaultSharedPreferences(this)
            val themeMode = prefs.getString("themeMode", "system") ?: "system"
            val themeColor = prefs.getString("themeColor", "monochrome") ?: "monochrome"
            QuestopiaTheme(themeMode = themeMode, themeColor = themeColor) {
                SettingsApp(onFinish = { finish() }, showBackButton = true)
            }
        }
    }
}

@Composable
fun SettingsApp(
    onFinish: () -> Unit,
    searchQuery: String = "",
    isSearchActive: Boolean = false,
    showBackButton: Boolean = true,
    onSearchQueryChange: (String) -> Unit = {}
) {
    SettingsMainScreen(
        onBack = onFinish,
        searchQuery = searchQuery,
        isSearchActive = isSearchActive,
        showBackButton = showBackButton,
        onSearchQueryChange = onSearchQueryChange
    )
}
