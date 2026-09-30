package org.qp.android.model.service;

import android.content.Context;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import coil.Coil;
import coil.request.ImageRequest;
import coil.target.Target;

public class ImageProvider {

    private Drawable mDrawable;

    /**
     * Loads an image from a file using an Uri via Coil.
     *
     * @return uploaded image, or <code>null</code> if the image was not found
     */
    public Drawable getDrawableFromPath(Context context, Uri path) {
        if (path == null || path.toString().isEmpty()) return null;

        Log.d("QUESTLOGTEST", "ImageProvider getDrawableFromPath requesting path: " + path);

        var request = new ImageRequest.Builder(context)
                .data(path)
                .target(new Target() {
                    @Override
                    public void onStart(@Nullable Drawable placeholder) {
                        Log.d("QUESTLOGTEST", "ImageProvider load start for: " + path);
                    }

                    @Override
                    public void onError(@Nullable Drawable error) {
                        Log.e("QUESTLOGTEST", "ImageProvider load error for: " + path);
                    }

                    @Override
                    public void onSuccess(@NonNull Drawable result) {
                        Log.d("QUESTLOGTEST", "ImageProvider load success for: " + path);
                        mDrawable = result;
                    }
                })
                .build();

        Coil.imageLoader(context).enqueue(request);
        return mDrawable;
    }
}
