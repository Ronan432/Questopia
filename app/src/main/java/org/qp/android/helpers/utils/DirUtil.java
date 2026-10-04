package org.qp.android.helpers.utils;

import static org.qp.android.helpers.utils.FileUtil.documentWrap;
import static org.qp.android.helpers.utils.FileUtil.fromRelPath;
import static org.qp.android.helpers.utils.FileUtil.isWritableDir;

import android.content.Context;
import android.net.Uri;

import androidx.annotation.Nullable;
import androidx.annotation.NonNull;
import androidx.annotation.WorkerThread;
import androidx.documentfile.provider.DocumentFile;

import com.anggrayudi.storage.file.DocumentFileCompat;
import com.anggrayudi.storage.file.DocumentFileType;
import com.anggrayudi.storage.file.DocumentFileUtils;
import com.anggrayudi.storage.file.MimeType;

import java.util.Collections;
import java.util.List;
import java.util.Locale;

public final class DirUtil {

    public static final String MOD_DIR_NAME = "mods";

    public static class GameFileLocation {
        public final DocumentFile gameFile;
        public final DocumentFile gameDir;

        public GameFileLocation(DocumentFile gameFile, DocumentFile gameDir) {
            this.gameFile = gameFile;
            this.gameDir = gameDir;
        }
    }

    @Nullable
    @WorkerThread
    public static GameFileLocation findGameFileDeep(@Nullable DocumentFile rootDir, int maxDepth) {
        if (rootDir == null || !rootDir.exists()) return null;
        var directFiles = rootDir.listFiles();
        if (directFiles != null) {
            for (var file : directFiles) {
                if (file.isFile()) {
                    var ext = documentWrap(file).getExtension().toLowerCase(Locale.ROOT);
                    if (ext.endsWith("qsp") || ext.endsWith("gam") || ext.endsWith("qsps") || ext.endsWith("aqsp")) {
                        return new GameFileLocation(file, rootDir);
                    }
                }
            }
            if (maxDepth > 0) {
                for (var file : directFiles) {
                    if (file.isDirectory()) {
                        var found = findGameFileDeep(file, maxDepth - 1);
                        if (found != null) return found;
                    }
                }
            }
        }
        return null;
    }

    @WorkerThread
    public static boolean isDirContainsGameFile(@NonNull Context context,
                                                @NonNull Uri dirUri) {
        var targetDir = DocumentFileCompat.fromUri(context, dirUri);
        if (!isWritableDir(context, targetDir)) return false;
        return findGameFileDeep(targetDir, 4) != null;
    }

    public static boolean isModDirExist(@NonNull Context context,
                                        @NonNull Uri dirUri) {
        if (dirUri == Uri.EMPTY) {
            return false;
        }

        var targetDir = DocumentFileCompat.fromUri(context, dirUri);
        if (targetDir == null) return false;
        return isWritableDir(context, fromRelPath(context, MOD_DIR_NAME, targetDir));
    }

    public static List<String> getNamesDir(@NonNull Context context,
                                           @NonNull List<Uri> dirUris) {
        if (dirUris == Uri.EMPTY) {
            return Collections.emptyList();
        }

        return dirUris.stream()
                .map(uri -> DocumentFileCompat.fromUri(context, uri))
                .filter(d -> d != null && d.getName() != null)
                .map(DocumentFile::getName)
                .toList();
    }

    @WorkerThread
    public static long calculateDirSize(DocumentFile dir) {
        if (dir != null && dir.exists()) {
            long result = 0;
            var fileList = dir.listFiles();
            for (var file : fileList) {
                if (file.isDirectory()) {
                    result += calculateDirSize(file);
                } else {
                    result += file.length();
                }
            }
            return result;
        }
        return 0;
    }

    @WorkerThread
    public static long calculateDirSize(java.io.File dir) {
        if (dir != null && dir.exists()) {
            long result = 0;
            var fileList = dir.listFiles();
            if (fileList != null) {
                for (var file : fileList) {
                    if (file.isDirectory()) {
                        result += calculateDirSize(file);
                    } else {
                        result += file.length();
                    }
                }
            }
            return result;
        }
        return 0;
    }

}
