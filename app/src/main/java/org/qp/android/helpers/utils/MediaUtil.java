package org.qp.android.helpers.utils;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.documentfile.provider.DocumentFile;

import java.util.Locale;

/**
 * Utility class providing centralized MIME type resolution, media and game file detection,
 * and robust case-insensitive file resolution for QSP game assets.
 */
public final class MediaUtil {

    private MediaUtil() {}

    @NonNull
    public static String getMimeType(@Nullable String pathOrName) {
        if (pathOrName == null || pathOrName.isBlank()) {
            return "application/octet-stream";
        }
        String lower = pathOrName.toLowerCase(Locale.ROOT);
        int queryIdx = lower.indexOf('?');
        if (queryIdx != -1) {
            lower = lower.substring(0, queryIdx);
        }

        if (lower.endsWith(".ogv") || lower.endsWith(".ogg")) {
            return "video/ogg";
        } else if (lower.endsWith(".mp4") || lower.endsWith(".m4v")) {
            return "video/mp4";
        } else if (lower.endsWith(".webm")) {
            return "video/webm";
        } else if (lower.endsWith(".mkv")) {
            return "video/x-matroska";
        } else if (lower.endsWith(".avi")) {
            return "video/x-msvideo";
        } else if (lower.endsWith(".mp3")) {
            return "audio/mpeg";
        } else if (lower.endsWith(".wav")) {
            return "audio/wav";
        } else if (lower.endsWith(".flac")) {
            return "audio/flac";
        } else if (lower.endsWith(".mid") || lower.endsWith(".midi")) {
            return "audio/midi";
        } else if (lower.endsWith(".png")) {
            return "image/png";
        } else if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
            return "image/jpeg";
        } else if (lower.endsWith(".gif")) {
            return "image/gif";
        } else if (lower.endsWith(".webp")) {
            return "image/webp";
        } else if (lower.endsWith(".svg")) {
            return "image/svg+xml";
        } else if (lower.endsWith(".bmp")) {
            return "image/bmp";
        } else if (lower.endsWith(".wasm")) {
            return "application/wasm";
        } else if (lower.endsWith(".js")) {
            return "application/javascript";
        } else if (lower.endsWith(".css")) {
            return "text/css";
        } else if (lower.endsWith(".html") || lower.endsWith(".htm")) {
            return "text/html";
        } else if (lower.endsWith(".json")) {
            return "application/json";
        } else if (lower.endsWith(".txt")) {
            return "text/plain";
        }
        return "application/octet-stream";
    }

    public static boolean isVideoExtension(@Nullable String path) {
        if (path == null) return false;
        String lower = path.toLowerCase(Locale.ROOT);
        return lower.endsWith(".ogv") || lower.endsWith(".ogg") ||
               lower.endsWith(".mp4") || lower.endsWith(".m4v") ||
               lower.endsWith(".webm") || lower.endsWith(".mkv") ||
               lower.endsWith(".avi");
    }

    public static boolean isAudioExtension(@Nullable String path) {
        if (path == null) return false;
        String lower = path.toLowerCase(Locale.ROOT);
        return lower.endsWith(".mp3") || lower.endsWith(".wav") ||
               lower.endsWith(".flac") || lower.endsWith(".ogg") ||
               lower.endsWith(".mid") || lower.endsWith(".midi");
    }

    public static boolean isImageExtension(@Nullable String path) {
        if (path == null) return false;
        String lower = path.toLowerCase(Locale.ROOT);
        return lower.endsWith(".png") || lower.endsWith(".jpg") ||
               lower.endsWith(".jpeg") || lower.endsWith(".gif") ||
               lower.endsWith(".webp") || lower.endsWith(".svg") ||
               lower.endsWith(".bmp");
    }

    public static boolean isGameExtension(@Nullable String path) {
        if (path == null) return false;
        String lower = path.toLowerCase(Locale.ROOT);
        return lower.endsWith(".qsp") || lower.endsWith(".gam") ||
               lower.endsWith(".qsps") || lower.endsWith(".aqsp");
    }

    @Nullable
    public static DocumentFile findFileCaseInsensitive(@Nullable DocumentFile dir, @NonNull String relPath) {
        if (dir == null || !dir.isDirectory() || relPath.isBlank()) return null;
        String cleanPath = relPath.replace("\\", "/");
        if (cleanPath.startsWith("./")) {
            cleanPath = cleanPath.substring(2);
        }
        if (cleanPath.startsWith("/")) {
            cleanPath = cleanPath.substring(1);
        }

        String[] segments = cleanPath.split("/");
        DocumentFile current = dir;

        for (int i = 0; i < segments.length; i++) {
            String segment = segments[i].trim();
            if (segment.isEmpty() || segment.equals(".")) continue;
            if (current == null || !current.isDirectory()) return null;

            DocumentFile[] children = current.listFiles();
            if (children == null) return null;

            DocumentFile match = null;
            for (DocumentFile child : children) {
                if (segment.equalsIgnoreCase(child.getName())) {
                    match = child;
                    break;
                }
            }

            if (match == null) {
                if (i == segments.length - 1) {
                    return findFileRecursive(current, segment);
                }
                return null;
            }
            current = match;
        }
        return current;
    }

    @Nullable
    public static DocumentFile findFileRecursive(@Nullable DocumentFile dir, @NonNull String fileName) {
        if (dir == null || !dir.isDirectory()) return null;
        DocumentFile[] files = dir.listFiles();
        if (files == null) return null;

        for (DocumentFile f : files) {
            if (f.isFile() && fileName.equalsIgnoreCase(f.getName())) {
                return f;
            }
        }
        for (DocumentFile f : files) {
            if (f.isDirectory()) {
                DocumentFile found = findFileRecursive(f, fileName);
                if (found != null) return found;
            }
        }
        return null;
    }
}
