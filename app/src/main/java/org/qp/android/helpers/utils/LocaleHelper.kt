package org.qp.android.helpers.utils

import android.content.Context
import android.content.res.Configuration
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import androidx.preference.PreferenceManager
import java.util.Locale

object LocaleHelper {
    private val RUSSIAN_SPEAKING_LANGS = setOf("ru", "be", "kk", "uk", "ky", "tg", "uz", "tk", "az", "hy", "mo")

    @JvmStatic
    fun getDefaultLanguage(): String {
        val systemLang = Locale.getDefault().language.lowercase(Locale.ROOT)
        return when {
            systemLang == "tr" -> "tr"
            RUSSIAN_SPEAKING_LANGS.contains(systemLang) -> "ru"
            else -> "en"
        }
    }

    @JvmStatic
    fun getEffectiveLanguage(context: Context): String {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val savedLang = prefs.getString("lang", null)
        if (savedLang != null && savedLang.isNotBlank()) {
            return savedLang
        }
        val defaultLang = getDefaultLanguage()
        prefs.edit().putString("lang", defaultLang).apply()
        return defaultLang
    }

    @JvmStatic
    fun wrapContext(context: Context): Context {
        val lang = getEffectiveLanguage(context)
        val locale = Locale.forLanguageTag(lang)
        Locale.setDefault(locale)
        val config = Configuration(context.resources.configuration)
        config.setLocale(locale)
        config.setLayoutDirection(locale)
        return context.createConfigurationContext(config)
    }

    @JvmStatic
    fun applyAppLanguage(context: Context) {
        val lang = getEffectiveLanguage(context)
        val locale = Locale.forLanguageTag(lang)
        Locale.setDefault(locale)
        AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(lang))
    }
}

