package org.qp.android.model.service;

import static org.qp.android.helpers.utils.Base64Util.encodeBase64;
import static org.qp.android.helpers.utils.StringUtil.isNotEmpty;
import static org.qp.android.helpers.utils.StringUtil.isNullOrEmpty;

import android.content.Context;
import android.util.Base64;

import androidx.annotation.NonNull;
import androidx.documentfile.provider.DocumentFile;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Element;
import org.jsoup.safety.Safelist;
import org.qp.android.helpers.utils.MediaUtil;
import org.qp.android.ui.settings.SettingsController;

import java.util.ArrayList;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.regex.Pattern;

public class HtmlProcessor {

    private final String TAG = this.getClass().getSimpleName();

    private static final Pattern EXEC_PATTERN = Pattern.compile(
            "href\\s*=\\s*(?:\"exec:(.*?)\"|'exec:(.*?)'|\\\\\"exec:(.*?)\\\\\"|\"\"exec:(.*?)\"\"|exec:([^\">\\s]+))",
            Pattern.CASE_INSENSITIVE | Pattern.DOTALL
    );
    private static final Pattern HTML_PATTERN = Pattern.compile("<(\"[^\"]*\"|'[^']*'|[^'\">])*>");

    private final ExecutorService executors = Executors.newSingleThreadExecutor();

    private final ImageProvider imageProvider;
    private SettingsController controller;
    private DocumentFile curGameDir;

    public String getSrcDir(String html) {
        var document = Jsoup.parse(html);
        var imageElement = document.select("img").first();
        if (imageElement == null) return "";
        return imageElement.attr("src");
    }

    /**
     * Bring the HTML code <code>html</code> obtained from the library to
     * HTML code acceptable for display in {@linkplain android.webkit.WebView}.
     */
    public String getCleanHtmlAndMedia(@NonNull Context context ,
                                       @NonNull String dirtyHtml) {
        if (isNullOrEmpty(dirtyHtml)) return "";

        var webHtml = convertLibHtmlToWebHtml(dirtyHtml);
        var document = Jsoup.parseBodyFragment(webHtml);
        document.outputSettings().prettyPrint(false);
        var body = document.body();
        convertVideoImagesToVideoTags(body);
        handleImagesInHtml(context , body);
        handleVideosInHtml(body);

        return body.html();
    }

    public String getCleanHtmlRemMedia(String dirtyHtml) {
        if (isNullOrEmpty(dirtyHtml)) return "";

        var webHtml = convertLibHtmlToWebHtml(dirtyHtml);
        var document = Jsoup.parseBodyFragment(webHtml);
        document.outputSettings().prettyPrint(false);
        var body = document.body();
        body.select("img").remove();
        body.select("video").remove();

        return body.html();
    }

    public String getTestHtml(String dirtyHtml) {
        if (isNullOrEmpty(dirtyHtml)) return "";

        var document = Jsoup.parse(convertLibHtmlToWebHtml(dirtyHtml));
        document.outputSettings().prettyPrint(false);
        var body = document.body();
        body.select("img").remove();
        body.select("video").remove();

        return document.toString();
    }

    public HtmlProcessor setController(SettingsController controller) {
        this.controller = controller;
        return this;
    }

    public HtmlProcessor setCurGameDir(DocumentFile curGameDir) {
        this.curGameDir = curGameDir;
        return this;
    }

    public boolean isContainsHtmlTags(String text){
        return HTML_PATTERN.matcher(text).find();
    }

    public HtmlProcessor(ImageProvider imageProvider) {
        this.imageProvider = imageProvider;
    }

    public String convertLibHtmlToWebHtml(String html) {
        if (isNullOrEmpty(html)) return "";
        var result = unescapeQuotes(html);
        result = encodeExec(result);
        return lineBreaksInHTML(result);
    }

    /**
     * Convert the string <code>str</code> obtained from the library to HTML code,
     * acceptable for display in {@linkplain android.webkit.WebView}.
     */
    public String convertLibStrToHtml(String str) {
        return isNotEmpty(str) ? lineBreaksInHTML(str) : "";
    }

    /**
     * Remove HTML tags from the <code>html</code> string and return the resulting string.
     */
    public String removeHtmlTags(String html) {
        if (isNullOrEmpty(html)) return "";

        html = html.replace("<br>", "\n")
                   .replace("<br/>", "\n")
                   .replace("<br />", "\n")
                   .replace("<BR>", "\n")
                   .replace("<BR/>", "\n")
                   .replace("<BR />", "\n");

        var result = new StringBuilder();
        var len = html.length();
        var fromIdx = 0;

        while (fromIdx < len) {
            var idx = html.indexOf('<', fromIdx);
            if (idx == -1) {
                result.append(html.substring(fromIdx));
                break;
            }
            result.append(html, fromIdx, idx);
            var endIdx = html.indexOf('>', idx + 1);
            if (endIdx == -1) {
                return Jsoup.clean(html , Safelist.none());
            }
            fromIdx = endIdx + 1;
        }

        return result.toString();
    }

    @NonNull
    private String unescapeQuotes(String str) {
        return str.replace("\\\"", "\"");
    }

    @NonNull
    private String encodeExec(String html) {
        if (isNullOrEmpty(html)) return "";
        var matcher = EXEC_PATTERN.matcher(html);
        var buffer = new StringBuilder();
        int lastEnd = 0;
        while (matcher.find()) {
            buffer.append(html, lastEnd, matcher.start());
            String exec = null;
            for (int i = 1; i <= matcher.groupCount(); i++) {
                if (matcher.group(i) != null) {
                    exec = matcher.group(i);
                    break;
                }
            }
            if (exec != null) {
                exec = normalizePathsInExec(exec);
                exec = exec.replace("&amp;", "&")
                           .replace("&quot;", "\"")
                           .replace("&lt;", "<")
                           .replace("&gt;", ">")
                           .replace("&apos;", "'");
                var encodedExec = encodeBase64(exec, Base64.NO_WRAP);
                buffer.append("href=\"exec:").append(encodedExec).append("\"");
            } else {
                buffer.append(matcher.group(0));
            }
            lastEnd = matcher.end();
        }
        buffer.append(html, lastEnd, html.length());
        return buffer.toString();
    }

    @NonNull
    private String normalizePathsInExec(@NonNull String exec) {
        return exec.replace("\\", "/");
    }

    @NonNull
    private String lineBreaksInHTML(@NonNull String s) {
        return s.replace("\n", "<br>")
                .replace("\r", "");
    }

    private void handleImagesInHtml(@NonNull Context context,
                                    @NonNull Element documentBody) {
        if (controller.isUseFullscreenImages) {
            var dynBlackList = new ArrayList<String>();
            documentBody.select("a").forEach(element -> {
                if (element.attr("href").contains("exec:")) {
                    dynBlackList.add(element.select("img").attr("src"));
                }
            });

            documentBody.select("img").forEach(img -> {
                if (!dynBlackList.contains(img.attr("src"))) {
                    img.attr("onclick", "img.onClickImage(this.src);");
                }
                img.attr("oncontextmenu", "img.onLongClickImage(this.src); return false;");
            });
        }

        documentBody.select("img").forEach(img -> {
            if (controller.isUseAutoWidth && controller.isUseAutoHeight) {
                img.attr("style", "display: inline; height: auto; max-width: 100%;");
            } else {
                if (!controller.isUseAutoWidth) {
                    img.attr("style" , "max-width:" + controller.customWidthImage+";");
                }
                if (!controller.isUseAutoHeight) {
                    img.attr("style" , "max-height:" + controller.customHeightImage+";");
                }
            }
        });
    }

    private void convertVideoImagesToVideoTags(Element documentBody) {
        documentBody.select("[src]").forEach(el -> {
            var src = el.attr("src");
            if (src.contains("\\")) {
                el.attr("src", src.replace("\\", "/"));
            }
        });

        var images = documentBody.select("img");
        for (var img : images) {
            var src = img.attr("src");
            if (src == null || src.isEmpty()) continue;
            if (MediaUtil.isVideoExtension(src)) {
                var video = new Element("video");
                video.attr("src", src);
                video.attr("autoplay", "autoplay");
                video.attr("loop", "loop");
                video.attr("playsinline", "true");
                video.attr("webkit-playsinline", "true");
                video.attr("preload", "auto");
                video.attr("style", "max-width:100%; height:auto;");
                if (controller != null && controller.isVideoMute) {
                    video.attr("muted", "true");
                }
                img.replaceWith(video);
                android.util.Log.i(TAG, "convertVideoImagesToVideoTags: converted <img src=\"" + src + "\"> to <video>");
            }
        }
    }

    private void handleVideosInHtml(Element documentBody) {
        var videoElements = documentBody.select("video");
        for (var videoElement : videoElements) {
            videoElement.attr("style", "max-width:100%; height:auto;");
            videoElement.attr("playsinline", "true");
            videoElement.attr("webkit-playsinline", "true");
            videoElement.attr("preload", "auto");
            videoElement.attr("autoplay", "autoplay");
            videoElement.attr("loop", "loop");
            if (controller != null && controller.isVideoMute) {
                videoElement.attr("muted", "true");
            }
            android.util.Log.i(TAG, "handleVideosInHtml: configured <video src=\"" + videoElement.attr("src") + "\">");
        }
    }
}
