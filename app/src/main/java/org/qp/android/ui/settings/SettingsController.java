package org.qp.android.ui.settings;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;

import androidx.annotation.NonNull;
import androidx.preference.PreferenceManager;

public class SettingsController {

    public int typeface;
    public int fontSize;
    public int backColor;
    public int textColor;
    public int linkColor;
    public int customWidthImage;
    public int customHeightImage;
    public int binaryPrefixes;
    public float actionsHeightRatio;
    public boolean isSoundEnabled;
    public boolean isImageDisabled;
    public boolean isUseAutoWidth;
    public boolean isUseAutoHeight;
    public boolean isUseSeparator;
    public boolean isUseGameFont;
    public boolean isUseAutoscroll;
    public boolean isUseExecString;
    public boolean isCheatsEnabled;
    public boolean isUseImmersiveMode;
    public boolean isUseGameTextColor;
    public boolean hasCustomTextColor;
    public boolean isUseGameBackgroundColor;
    public boolean hasCustomBackColor;
    public boolean isUseGameLinkColor;
    public boolean hasCustomLinkColor;
    public boolean isUseFullscreenImages;
    public boolean isUseImageDebug;
    public boolean isUseMusicDebug;
    public boolean isVideoMute;
    public boolean isPinchZoomEnabled;
    public boolean isSquarePosters;
    public boolean isAutosaveEnabled;
    public int autosaveClickInterval;
    public String language;
    private static SettingsController INSTANCE;

    @NonNull
    public static SettingsController newInstance(Context context) {
        if (INSTANCE == null) {
            INSTANCE = new SettingsController();
        }

        return from(PreferenceManager.getDefaultSharedPreferences(context));
    }

    @NonNull
    private static SettingsController from(@NonNull SharedPreferences preferences) {
        SettingsController settingsController = new SettingsController();
        String fontPref = preferences.getString("fontStyle", preferences.getString("typeface", "0"));
        settingsController.typeface = Integer.parseInt(fontPref != null ? fontPref : "0");
        settingsController.fontSize = Integer.parseInt(preferences.getString("fontSize", "16"));
        settingsController.binaryPrefixes = Integer.parseInt(preferences.getString("binPref", "1000"));
        settingsController.actionsHeightRatio = parseActionsHeightRatio(preferences.getString("actsHeight", "1/3"));
        settingsController.isUseAutoscroll = preferences.getBoolean("autoscroll", true);
        settingsController.isUseExecString = preferences.getBoolean("execString", false);
        settingsController.isCheatsEnabled = preferences.getBoolean("enableCheats", false);
        settingsController.isUseSeparator = preferences.getBoolean("separator", false);
        settingsController.isUseGameFont = preferences.getBoolean("isUseGameFont", preferences.getBoolean("useGameFont", false));
        settingsController.isUseImmersiveMode = preferences.getBoolean("immersiveMode", true);
        settingsController.isPinchZoomEnabled = preferences.getBoolean("pinchZoom", true);
        settingsController.isSquarePosters = preferences.getBoolean("squarePosters", false);
        settingsController.isAutosaveEnabled = preferences.getBoolean("autosave", false);
        settingsController.autosaveClickInterval = Math.max(10, preferences.getInt("autosaveInterval", 15));
        settingsController.language = preferences.getString("lang", "en");
        imageSettings(settingsController, preferences);
        colorSettings(settingsController, preferences);
        soundSettings(settingsController, preferences);
        return settingsController;
    }

    private static void colorSettings(@NonNull SettingsController settingsController,
                                      @NonNull SharedPreferences preferences) {
        settingsController.isUseGameTextColor = preferences.getBoolean("useGameTextColor", true);
        settingsController.hasCustomTextColor = preferences.contains("textColor");
        settingsController.textColor = preferences.getInt("textColor", Color.parseColor("#000000"));
        settingsController.isUseGameBackgroundColor = preferences.getBoolean("useGameBackgroundColor", true);
        settingsController.hasCustomBackColor = preferences.contains("backColor");
        settingsController.backColor = preferences.getInt("backColor", Color.parseColor("#e0e0e0"));
        settingsController.isUseGameLinkColor = preferences.getBoolean("useGameLinkColor", true);
        settingsController.hasCustomLinkColor = preferences.contains("linkColor");
        settingsController.linkColor = preferences.getInt("linkColor", Color.parseColor("#0000ff"));
    }

    private static void imageSettings(@NonNull SettingsController settingsController,
                                      @NonNull SharedPreferences preferences) {
        settingsController.isImageDisabled = preferences.getBoolean("pref_disable_image", false);
        settingsController.isUseAutoWidth = preferences.getBoolean("autoWidth", true);
        settingsController.customWidthImage = Integer.parseInt(preferences.getString("customWidthImage", "400"));
        settingsController.isUseAutoHeight = preferences.getBoolean("autoHeight", true);
        settingsController.customHeightImage = Integer.parseInt(preferences.getString("customHeightImage", "400"));
        settingsController.isUseFullscreenImages = preferences.getBoolean("fullScreenImage", false);
        settingsController.isUseImageDebug = preferences.getBoolean("debugImage", false);
    }

    private static void soundSettings(@NonNull SettingsController controller,
                                      @NonNull SharedPreferences preferences) {
        controller.isSoundEnabled = preferences.getBoolean("sound", true);
        controller.isVideoMute = preferences.getBoolean("videoMute", true);
        controller.isUseMusicDebug = preferences.getBoolean("debugMusic", false);
    }

    private static float parseActionsHeightRatio(@NonNull String str) {
        return switch (str) {
            case "1/5" -> 0.2f;
            case "1/4" -> 0.25f;
            case "1/3" -> 0.33f;
            case "1/2" -> 0.5f;
            case "2/3" -> 0.67f;
            default -> throw new RuntimeException("Unsupported value of actsHeight: " + str);
        };
    }

    public Typeface getTypeface() {
        return switch (typeface) {
            case 1 -> Typeface.SANS_SERIF;
            case 2 -> Typeface.SERIF;
            case 3 -> Typeface.MONOSPACE;
            case 4 -> Typeface.create("sans-serif-medium", Typeface.NORMAL);
            case 5 -> Typeface.create("sans-serif", Typeface.BOLD);
            case 6 -> Typeface.create("cursive", Typeface.NORMAL);
            case 7 -> Typeface.create("sans-serif-light", Typeface.NORMAL);
            case 8 -> Typeface.create("sans-serif-condensed", Typeface.NORMAL);
            case 9 -> Typeface.create("sans-serif-black", Typeface.NORMAL);
            case 10 -> Typeface.create("sans-serif-thin", Typeface.NORMAL);
            case 11 -> Typeface.create("casual", Typeface.NORMAL);
            case 12 -> Typeface.create("serif-monospace", Typeface.NORMAL);
            default -> Typeface.DEFAULT;
        };
    }
}
