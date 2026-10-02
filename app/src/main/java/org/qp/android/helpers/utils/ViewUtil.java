package org.qp.android.helpers.utils;

import android.graphics.Typeface;
import android.view.View;

import androidx.annotation.NonNull;

import com.google.android.material.snackbar.Snackbar;

import org.jetbrains.annotations.Contract;

public final class ViewUtil {

    public static void showSnackBar(View view, String text) {
        Snackbar.make(view, text, Snackbar.LENGTH_SHORT).show();
    }

    @NonNull
    @Contract(pure = true)
    public static String getFontStyle(Typeface typeface) {
        if (Typeface.SANS_SERIF.equals(typeface)) {
            return "sans-serif";
        } else if (Typeface.SERIF.equals(typeface)) {
            return "serif";
        } else if (Typeface.MONOSPACE.equals(typeface)) {
            return "monospace";
        } else if (Typeface.create("sans-serif-medium", Typeface.NORMAL).equals(typeface)) {
            return "sans-serif-medium";
        } else if (Typeface.create("sans-serif", Typeface.BOLD).equals(typeface)) {
            return "sans-serif-bold";
        } else if (Typeface.create("cursive", Typeface.NORMAL).equals(typeface)) {
            return "cursive";
        } else if (Typeface.create("sans-serif-light", Typeface.NORMAL).equals(typeface)) {
            return "sans-serif-light";
        } else if (Typeface.create("sans-serif-condensed", Typeface.NORMAL).equals(typeface)) {
            return "sans-serif-condensed";
        } else if (Typeface.create("sans-serif-black", Typeface.NORMAL).equals(typeface)) {
            return "sans-serif-black";
        } else if (Typeface.create("sans-serif-thin", Typeface.NORMAL).equals(typeface)) {
            return "sans-serif-thin";
        } else if (Typeface.create("casual", Typeface.NORMAL).equals(typeface)) {
            return "casual";
        } else if (Typeface.create("serif-monospace", Typeface.NORMAL).equals(typeface)) {
            return "serif, monospace";
        }
        return "sans-serif";
    }
}
