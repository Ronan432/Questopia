package org.qp.android.helpers;

import android.content.Context;
import android.widget.ImageView;

import androidx.annotation.DrawableRes;
import androidx.annotation.Nullable;

import coil.Coil;
import coil.request.ImageRequest;

import org.qp.android.R;

public final class CoilHelper {

    private CoilHelper() { }

    public static void load(ImageView imageView, @Nullable Object data) {
        load(imageView, data, R.drawable.baseline_broken_image_24);
    }

    public static void load(ImageView imageView, @Nullable Object data, @DrawableRes int fallbackRes) {
        if (imageView == null) return;
        Context context = imageView.getContext();
        ImageRequest.Builder builder = new ImageRequest.Builder(context)
                .data(data)
                .target(imageView)
                .crossfade(true);

        if (fallbackRes != 0) {
            builder.placeholder(fallbackRes).error(fallbackRes);
        }

        Coil.imageLoader(context).enqueue(builder.build());
    }
}
