package org.qp.android;

import android.app.Application;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.os.Build;

import androidx.annotation.NonNull;

import org.qp.android.helpers.utils.LocaleHelper;
import org.qp.android.model.lib.LibIProxy;
import org.qp.android.model.lib.LibProxyImpl;
import org.qp.android.model.service.AudioPlayer;
import org.qp.android.model.service.HtmlProcessor;
import org.qp.android.model.service.ImageProvider;
import org.qp.android.ui.settings.SettingsController;

import java.io.File;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.io.StringWriter;

import coil.ImageLoader;
import coil.ImageLoaderFactory;
import coil.disk.DiskCache;
import coil.memory.MemoryCache;

public class QuestopiaApplication extends Application implements ImageLoaderFactory {

    public static final int UNPACK_GAME_NOTIFICATION_ID = 1800;
    public static final String UNPACK_GAME_CHANNEL_ID = "org.qp.android.channel.unpack_game";

    public final ImageProvider imageProvider = new ImageProvider();
    private final HtmlProcessor htmlProcessor = new HtmlProcessor(imageProvider);
    public final AudioPlayer audioPlayer = new AudioPlayer(this);
    public final LibProxyImpl libProxy = new LibProxyImpl(this);

    @Override
    protected void attachBaseContext(Context base) {
        super.attachBaseContext(LocaleHelper.wrapContext(base));
    }

    @Override
    public void onCreate() {
        super.onCreate();
        LocaleHelper.applyAppLanguage(this);
        createNotificationChannels();
        final Thread.UncaughtExceptionHandler previous = Thread.getDefaultUncaughtExceptionHandler();
        Thread.setDefaultUncaughtExceptionHandler((thread, throwable) -> {
            try {
                StringWriter stack = new StringWriter();
                throwable.printStackTrace(new PrintWriter(stack));
                String logcat = "";
                try {
                    Process process = Runtime.getRuntime().exec(new String[]{"logcat", "-d", "-t", "250"});
                    java.io.InputStream input = process.getInputStream();
                    logcat = new java.io.BufferedReader(new java.io.InputStreamReader(input, java.nio.charset.StandardCharsets.UTF_8)).lines()
                            .collect(java.util.stream.Collectors.joining("\n"));
                    process.destroy();
                } catch (Exception ignored) { }
                try (FileWriter writer = new FileWriter(new File(getFilesDir(), "last_crash.txt"), false)) {
                    writer.write("Questopia crash report\n\nException:\n");
                    writer.write(stack.toString());
                    writer.write("\n\nLast logcat:\n");
                    writer.write(logcat);
                }
            } catch (Exception ignored) { }
            if (previous != null) previous.uncaughtException(thread, throwable);
        });
    }

    @NonNull
    @Override
    public ImageLoader newImageLoader() {
        return new ImageLoader.Builder(this)
                .memoryCache(() -> new MemoryCache.Builder(this)
                        .maxSizePercent(0.25)
                        .build())
                .diskCache(() -> new DiskCache.Builder()
                        .directory(new File(getCacheDir(), "image_cache"))
                        .maxSizeBytes(100 * 1024 * 1024)
                        .build())
                .crossfade(true)
                .respectCacheHeaders(false)
                .build();
    }

    public HtmlProcessor getHtmlProcessor() {
        return htmlProcessor
                .setController(SettingsController.newInstance(this));
    }

    public LibIProxy getLibProxy() {
        return libProxy;
    }

    public void createNotificationChannels() {
        var notificationManager = getSystemService(NotificationManager.class);
        var importance = NotificationManager.IMPORTANCE_DEFAULT;

        var name = getString(R.string.channelInstallGame);
        var channel = new NotificationChannel(UNPACK_GAME_CHANNEL_ID , name , importance);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            channel.setAllowBubbles(true);
        }
        notificationManager.createNotificationChannel(channel);
    }

}
