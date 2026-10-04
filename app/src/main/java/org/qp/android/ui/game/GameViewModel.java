package org.qp.android.ui.game;

import static org.qp.android.helpers.utils.Base64Util.decodeBase64;
import static org.qp.android.helpers.utils.Base64Util.isBase64;
import static org.qp.android.helpers.utils.ColorUtil.convertRGBAtoBGRA;
import static org.qp.android.helpers.utils.ColorUtil.getHexColor;
import static org.qp.android.helpers.utils.FileUtil.findOrCreateFolder;
import static org.qp.android.helpers.utils.FileUtil.fromRelPath;
import static org.qp.android.helpers.utils.FileUtil.isWritableFile;
import static org.qp.android.helpers.utils.PathUtil.getExtension;
import static org.qp.android.helpers.utils.StringUtil.isNotEmptyOrBlank;
import static org.qp.android.helpers.utils.ThreadUtil.assertNonUiThread;
import static org.qp.android.helpers.utils.ViewUtil.getFontStyle;
import static org.qp.android.ui.game.GameActivity.LOAD;
import org.qp.android.helpers.utils.MediaUtil;

import android.annotation.SuppressLint;
import android.app.Application;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.graphics.Color;
import android.net.Uri;
import android.os.Handler;
import android.os.ParcelFileDescriptor;
import android.util.Log;
import android.view.View;
import android.webkit.MimeTypeMap;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.documentfile.provider.DocumentFile;
import androidx.fragment.app.DialogFragment;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.preference.PreferenceManager;

import com.anggrayudi.storage.file.DocumentFileCompat;
import com.google.android.material.textfield.TextInputLayout;
import com.libqsp.jni.QSPLib;

import org.qp.android.QuestopiaApplication;
import org.qp.android.R;
import org.qp.android.helpers.ErrorType;
import org.qp.android.model.lib.LibGameState;
import org.qp.android.model.lib.LibIConfig;
import org.qp.android.model.lib.LibIProxy;
import org.qp.android.model.lib.LibRefIRequest;
import org.qp.android.model.lib.LibWindowType;
import org.qp.android.model.service.AudioPlayer;
import org.qp.android.model.service.HtmlProcessor;
import org.qp.android.ui.dialogs.GameDialogType;
import org.qp.android.ui.settings.SettingsController;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.CountDownLatch;

public class GameViewModel extends AndroidViewModel implements GameInterface {

    private static final String TAG = "GameViewModel";
    private static final String PAGE_HEAD_TEMPLATE = """
            <!DOCTYPE html>
            <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=0.5, maximum-scale=5.0, user-scalable=yes">
            <style type="text/css">
              body {
                margin: 0;
                padding: 12px;
                color: QSPTEXTCOLOR;
                background-color: QSPBACKCOLOR;
                font-size: QSPFONTSIZEpx;
                font-family: QSPFONTSTYLE;
                line-height: 1.45;
                word-wrap: break-word;
              }
              img {
                display: block;
                max-width: 100%;
                height: auto;
                margin: 8px auto;
                border-radius: 8px;
              }
              video, ogvjs {
                display: block !important;
                max-width: 100% !important;
                width: 100% !important;
                height: auto !important;
                margin: 8px auto !important;
                border-radius: 8px !important;
                position: relative !important;
                background-color: transparent !important;
                overflow: hidden !important;
              }
              ogvjs canvas {
                position: absolute !important;
                top: 0 !important;
                left: 0 !important;
                width: 100% !important;
                height: 100% !important;
                object-fit: fill !important;
              }
              a { color: QSPLINKCOLOR; text-decoration: underline; }
              a:link, a:visited, a:active { color: QSPLINKCOLOR; }
            </style>
            <script src="ogv/ogv.js"></script>
            <script>
              if (typeof OGVLoader !== 'undefined') {
                OGVLoader.base = 'ogv';
              }
              function initOgvElements() {
                if (typeof OGVPlayer === 'undefined') return;
                if (typeof OGVLoader !== 'undefined' && OGVLoader.base !== 'ogv') {
                  OGVLoader.base = 'ogv';
                }
                var videoElements = document.querySelectorAll('video');
                for (var i = 0; i < videoElements.length; i++) {
                  var v = videoElements[i];
                  if (v.dataset.ogvReady) continue;

                  var src = v.getAttribute('src');
                  var ogvUrl = null;
                  if (src && (src.toLowerCase().indexOf('.ogv') !== -1 || src.toLowerCase().indexOf('.ogg') !== -1)) {
                    ogvUrl = src;
                  } else {
                    var sources = v.querySelectorAll('source');
                    for (var j = 0; j < sources.length; j++) {
                      var sSrc = sources[j].getAttribute('src');
                      if (sSrc && (sSrc.toLowerCase().indexOf('.ogv') !== -1 || sSrc.toLowerCase().indexOf('.ogg') !== -1)) {
                        ogvUrl = sSrc;
                        break;
                      }
                    }
                  }

                  if (ogvUrl) {
                    v.dataset.ogvReady = 'true';
                    console.log('[OGVPlayer] Initializing OGV player for: ' + ogvUrl);
                    try {
                      var player = new OGVPlayer({
                        worker: false
                      });
                      function fitPlayer(p) {
                        if (p.videoWidth && p.videoHeight) {
                          p.style.setProperty('width', '100%', 'important');
                          p.style.setProperty('max-width', '100%', 'important');
                          p.style.setProperty('height', 'auto', 'important');
                          p.style.setProperty('aspect-ratio', p.videoWidth + ' / ' + p.videoHeight, 'important');
                        }
                      }
                      player.style.width = '100%';
                      player.style.maxWidth = '100%';
                      player.style.display = 'block';
                      player.style.margin = '8px auto';
                      player.style.borderRadius = '8px';
                      if (v.hasAttribute('autoplay') || v.autoplay) player.autoplay = true;
                      if (v.hasAttribute('loop') || v.loop) player.loop = true;
                      if (v.hasAttribute('muted') || v.muted) player.muted = true;
                      player.addEventListener('loadedmetadata', function() {
                        fitPlayer(player);
                        console.log('[OGVPlayer] metadata loaded: ' + player.videoWidth + 'x' + player.videoHeight);
                      });
                      player.addEventListener('resize', function() { fitPlayer(player); });
                      player.addEventListener('play', function() { fitPlayer(player); });
                      player.addEventListener('playing', function() { fitPlayer(player); });
                      player.onframecallback = function() { fitPlayer(player); };
                      player.addEventListener('error', function(err) {
                        console.error('[OGVPlayer] error event: ' + err);
                      });
                      if (v.parentNode) {
                        v.parentNode.replaceChild(player, v);
                      }
                      player.src = ogvUrl;
                      player.play();
                    } catch (e) {
                      console.error('[OGVPlayer] Error initializing player: ' + e);
                    }
                  }
                }
              }
              document.addEventListener('DOMContentLoaded', initOgvElements);
              setInterval(initOgvElements, 300);
            </script>
            </head>
            """;
    private static final String PAGE_BODY_TEMPLATE = "<body>REPLACETEXT</body>";
    private final QuestopiaApplication questopiaApplication;
    private final MutableLiveData<SettingsController> controllerObserver = new MutableLiveData<>();
    private final MutableLiveData<String> mainDescLiveData = new MutableLiveData<>();
    private final MutableLiveData<String> varsDescLiveData = new MutableLiveData<>();
    public final MutableLiveData<List<QSPLib.ListItem>> actsListLiveData = new MutableLiveData<>();
    public final MutableLiveData<List<QSPLib.ListItem>> objsListLiveData = new MutableLiveData<>();
    private final Handler counterHandler = new Handler();
    public MutableLiveData<String> outputTextObserver = new MutableLiveData<>();
    public MutableLiveData<Integer> outputIntObserver = new MutableLiveData<>();
    public MutableLiveData<Boolean> outputBooleanObserver = new MutableLiveData<>(false);
    public MutableLiveData<GameActivity> activityObserver = new MutableLiveData<>();
    public String pageTemplate = "";
    public SharedPreferences preferences;
    private Uri gameDirUri;
    public boolean showActions = true;
    SharedPreferences.OnSharedPreferenceChangeListener preferenceChangeListener = (sharedPreferences, key) -> {
        controllerObserver.postValue(getSettingsController());
        updatePageTemplate();
        refreshMainDesc();
        refreshVarsDesc();
        refreshActionsRecycler();
        refreshObjectsRecycler();
    };
    private int counterInterval = 500;
    private final Runnable counterTask = new Runnable() {
        @Override
        public void run() {
            if (getLibProxy() == null) return;
            getLibProxy().executeCounter();
            counterHandler.postDelayed(this, counterInterval);
        }
    };

    public GameViewModel(@NonNull Application application) {
        super(application);
        preferences = PreferenceManager.getDefaultSharedPreferences(application);
        preferences.registerOnSharedPreferenceChangeListener(preferenceChangeListener);
        questopiaApplication = (QuestopiaApplication) getApplication();
    }

    private HtmlProcessor getHtmlProcessor() {
        var proc = questopiaApplication.getHtmlProcessor();
        proc.setController(getSettingsController());
        if (getCurGameDir().isPresent()) {
            proc.setCurGameDir(getCurGameDir().get());
        }
        return proc;
    }

    private LibIProxy getLibProxy() {
        return questopiaApplication.getLibProxy();
    }

    private LibGameState getLibGameState() {
        return getLibProxy().getGameState();
    }

    private AudioPlayer getAudioPlayer() {
        if (getCurGameDir().isPresent()){
            return questopiaApplication.audioPlayer.setCurGameDir(getCurGameDir().get());
        } else {
            return questopiaApplication.audioPlayer;
        }
    }

    public LiveData<String> getAudioErrorObserver() {
        return getAudioPlayer().getIsThrowError();
    }

    public SettingsController getSettingsController() {
        return SettingsController.newInstance(getApplication());
    }

    @SuppressLint("SetJavaScriptEnabled")
    public WebView getDefaultWebClient(WebView view) {
        var webViewClient = new GameWebViewClient();
        var webClientSettings = view.getSettings();
        webClientSettings.setAllowFileAccess(true);
        webClientSettings.setAllowContentAccess(true);
        webClientSettings.setAllowFileAccessFromFileURLs(true);
        webClientSettings.setAllowUniversalAccessFromFileURLs(true);
        webClientSettings.setJavaScriptEnabled(true);
        webClientSettings.setUseWideViewPort(true);
        webClientSettings.setDomStorageEnabled(true);
        webClientSettings.setLoadWithOverviewMode(true);
        view.setOverScrollMode(View.OVER_SCROLL_NEVER);
        view.setWebViewClient(webViewClient);
        return view;
    }

    public LiveData<SettingsController> getControllerObserver() {
        return controllerObserver;
    }

    public boolean isDarkTheme() {
        var themeMode = preferences.getString("themeMode", "1");
        if ("2".equals(themeMode) || "3".equals(themeMode) || "dark".equalsIgnoreCase(themeMode) || "amoled".equalsIgnoreCase(themeMode)) {
            return true;
        } else if ("4".equals(themeMode) || "light".equalsIgnoreCase(themeMode)) {
            return false;
        } else {
            int nightModeFlags = getApplication().getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK;
            return nightModeFlags == Configuration.UI_MODE_NIGHT_YES;
        }
    }

    public boolean isAmoledTheme() {
        var themeMode = preferences.getString("themeMode", "1");
        return "3".equals(themeMode) || "amoled".equalsIgnoreCase(themeMode);
    }

    public int getTextColor() {
        var libState = getLibGameState();
        var config = libState != null ? libState.interfaceConfig : null;
        if (config != null && getSettingsController().isUseGameTextColor && config.fontColor != 0) {
            return convertRGBAtoBGRA(config.fontColor);
        } else if (getSettingsController().hasCustomTextColor) {
            return getSettingsController().textColor;
        } else {
            return isDarkTheme() ? Color.parseColor("#E2E2E6") : Color.parseColor("#1A1C1E");
        }
    }

    public int getBackgroundColor() {
        var libState = getLibGameState();
        var config = libState != null ? libState.interfaceConfig : null;
        if (config != null && getSettingsController().isUseGameBackgroundColor && config.backColor != 0) {
            return convertRGBAtoBGRA(config.backColor);
        } else if (getSettingsController().hasCustomBackColor) {
            return getSettingsController().backColor;
        } else {
            if (isAmoledTheme()) return Color.BLACK;
            return isDarkTheme() ? Color.parseColor("#121212") : Color.parseColor("#FDFCFF");
        }
    }

    public int getLinkColor() {
        var libState = getLibGameState();
        var config = libState != null ? libState.interfaceConfig : null;
        if (config != null && getSettingsController().isUseGameLinkColor && config.linkColor != 0) {
            return convertRGBAtoBGRA(config.linkColor);
        } else if (getSettingsController().hasCustomLinkColor) {
            return getSettingsController().linkColor;
        } else {
            return isDarkTheme() ? Color.parseColor("#9ECAFF") : Color.parseColor("#0061A4");
        }
    }

    public int getFontSize() {
        var config = getLibGameState().interfaceConfig;
        return getSettingsController().isUseGameFont && config.fontSize != 0 ?
                config.fontSize : getSettingsController().fontSize;
    }

    public String getHtml(String str) {
        var config = getLibGameState().interfaceConfig;
        return config.useHtml ?
                getHtmlProcessor().convertLibHtmlToWebHtml(str) :
                getHtmlProcessor().convertLibStrToHtml(str);
    }

    public Uri getImageUriFromPath(String src) {
        var relPath = Uri.parse(src).getPath();
        if (relPath == null) return Uri.EMPTY;
        while (relPath.startsWith("/")) {
            relPath = relPath.substring(1);
        }
        if (getCurGameDir().isPresent()) {
            var imageFile = fromRelPath(getApplication(), relPath, getCurGameDir().get());
            if (imageFile != null && imageFile.exists()) {
                return imageFile.getUri();
            }
            return Uri.EMPTY;
        } else {
            return Uri.EMPTY;
        }
    }

    public LiveData<String> getMainDescObserver() {
        return mainDescLiveData;
    }

    public LiveData<String> getVarsDescObserver() {
        return varsDescLiveData;
    }

    public Optional<DocumentFile> getCurGameDir() {
        if (gameDirUri == null) return Optional.empty();
        return Optional.ofNullable(DocumentFileCompat.fromUri(getApplication(), gameDirUri));
    }

    public Optional<DocumentFile> getSavesDir() {
        if (getCurGameDir().isEmpty()) return Optional.empty();
        var savesDir = findOrCreateFolder(getApplication(), getCurGameDir().get(), "saves");
        return Optional.ofNullable(savesDir);
    }

    @Nullable
    public GameActivity getGameActivity() {
        return activityObserver.getValue();
    }

    public LibIConfig getIConfig() {
        return getLibGameState().interfaceConfig;
    }

    // endregion Getter/Setter

    public void setGameDirUri(Uri gameDirUri) {
        this.gameDirUri = gameDirUri;
    }

    public String removeHtmlTags(String dirtyHTML) {
        return getHtmlProcessor().removeHtmlTags(dirtyHTML);
    }

    private boolean isHasHTMLTags(String input) {
        return getHtmlProcessor().isContainsHtmlTags(input);
    }

    public void updatePageTemplate() {
        var pageHeadTemplate = PAGE_HEAD_TEMPLATE
                .replace("QSPTEXTCOLOR", getHexColor(getTextColor()))
                .replace("QSPBACKCOLOR", getHexColor(getBackgroundColor()))
                .replace("QSPLINKCOLOR", getHexColor(getLinkColor()))
                .replace("QSPFONTSTYLE", getFontStyle(getSettingsController().getTypeface()))
                .replace("QSPFONTSIZE", Integer.toString(getFontSize()));
        pageTemplate = pageHeadTemplate + PAGE_BODY_TEMPLATE;
    }

    private void refreshMainDesc() {
        var rawDesc = getLibGameState().mainDesc;
        var cleanBody = "";
        if (getSettingsController().isImageDisabled) {
            cleanBody = getHtmlProcessor().getCleanHtmlRemMedia(rawDesc);
        } else {
            cleanBody = getHtmlProcessor().getCleanHtmlAndMedia(getApplication(), rawDesc);
        }
        updatePageTemplate();
        var fullHtml = pageTemplate.replace("REPLACETEXT", cleanBody != null ? cleanBody : "");
        Log.i(TAG, "refreshMainDesc: rawLen=" + (rawDesc != null ? rawDesc.length() : 0) + ", cleanBody=" + cleanBody);
        if (!cleanBody.isBlank()) {
            getGameActivity().warnUser(GameActivity.TAB_MAIN_DESC_AND_ACTIONS);
        }
        mainDescLiveData.postValue(fullHtml);
    }

    private void refreshVarsDesc() {
        final var rawVarsDesc = getLibGameState().varsDesc;
        var cleanBody = "";
        if (getSettingsController().isImageDisabled) {
            cleanBody = getHtmlProcessor().getCleanHtmlRemMedia(rawVarsDesc);
        } else {
            cleanBody = getHtmlProcessor().getCleanHtmlAndMedia(getApplication(), rawVarsDesc);
        }
        updatePageTemplate();
        var fullHtml = pageTemplate.replace("REPLACETEXT", cleanBody != null ? cleanBody : "");
        Log.i(TAG, "refreshVarsDesc: rawLen=" + (rawVarsDesc != null ? rawVarsDesc.length() : 0) + ", cleanBody=" + cleanBody);
        if (!cleanBody.isBlank()) {
            getGameActivity().warnUser(GameActivity.TAB_VARS_DESC);
        }
        varsDescLiveData.postValue(fullHtml);
    }

    public void onActionClicked(int index) {
        getLibProxy().onActionClicked(index);
    }

    private void refreshActionsRecycler() {
        var listItems = getLibGameState().actionsList;
        actsListLiveData.postValue(listItems);
    }

    public void onObjectClicked(int index) {
        getLibProxy().onObjectSelected(index);
    }

    private void refreshObjectsRecycler() {
        getGameActivity().warnUser(GameActivity.TAB_OBJECTS);
        objsListLiveData.postValue(getLibGameState().objectsList);
    }

    public void setCallback() {
        counterHandler.postDelayed(counterTask, counterInterval);
    }

    public void removeCallback() {
        counterHandler.removeCallbacks(counterTask);
    }

    @Override
    protected void onCleared() {
        super.onCleared();
        preferences.unregisterOnSharedPreferenceChangeListener(preferenceChangeListener);
    }

    public void startAudio() {
        getAudioPlayer().start();
    }

    public void pauseAudio() {
        getAudioPlayer().pause();
    }

    public void resumeAudio() {
        if (getCurGameDir().isEmpty()) return;
        getAudioPlayer().setCurGameDir(getCurGameDir().get());
        getAudioPlayer().setSoundEnabled(getSettingsController().isSoundEnabled);
        getAudioPlayer().resume();
    }

    public void stopAudio() {
        getAudioPlayer().stop();
    }

    public void startNativeLib() {
        getLibProxy().setGameInterface(this);
        getLibProxy().startLibThread();
    }

    public void stopNativeLib() {
        getLibProxy().stopLibThread();
        getLibProxy().setGameInterface(null);
    }

    public void runGameIntoNativeLib(long gameId,
                                     String gameTitle,
                                     Uri gameDir,
                                     Uri gameFile) {
        getLibProxy().runGame(gameId, gameTitle, gameDir, gameFile);
    }

    public void requestForNativeLib(GameLibRequest req, Uri fileUri) {
        switch (req) {
            case LOAD_FILE -> doWithCounterDisabled(() ->
                    getLibProxy().loadGameState(fileUri));
            case SAVE_FILE -> getLibProxy().saveGameState(fileUri);
        }
    }

    public void requestForNativeLib(GameLibRequest req) {
        switch (req) {
            case USE_EXECUTOR -> getLibProxy().onUseExecutorString();
            case USE_INPUT -> getLibProxy().onInputAreaClicked();
            case RESTART_GAME -> getLibProxy().restartGame();
        }
    }

    public Boolean isGameRunning() {
        if (getLibProxy().getGameState() == null) return false;
        return getLibProxy().getGameState().gameRunning;
    }

    // region GameInterface
    @Override
    public void refresh(final LibRefIRequest request) {
        if (request.isIConfigChanged) {
            getGameActivity().applySettings();
        }
        if (request.isIConfigChanged || request.isMainDescChanged) {
            updatePageTemplate();
            refreshMainDesc();
        }
        if (request.isActionsChanged) {
            refreshActionsRecycler();
        }
        if (request.isObjectsChanged) {
            refreshObjectsRecycler();
        }
        if (request.isIConfigChanged || request.isVarsDescChanged) {
            updatePageTemplate();
            refreshVarsDesc();
        }
    }

    @Override
    public void showErrorDialog(final String message) {
        getGameActivity().showSimpleDialog(message, GameDialogType.ERROR_DIALOG, null);
    }

    public void showErrorDialog(final String message, final ErrorType errorType) {
        getGameActivity().showSimpleDialog(message, GameDialogType.ERROR_DIALOG, errorType);
    }

    @Override
    public void showPicture(final String pathToImg) {
        getGameActivity().showSimpleDialog(pathToImg, GameDialogType.IMAGE_DIALOG, null);
    }

    @Override
    public void showMessage(final String message) {
        assertNonUiThread();

        final var latch = new CountDownLatch(1);
        getGameActivity().showMessageDialog(message, latch);
        try {
            latch.await();
        } catch (InterruptedException ex) {
            showErrorDialog(ex.getMessage(), ErrorType.WAITING_ERROR);
        }
    }

    @Override
    public String showInputDialog(final String prompt) {
        assertNonUiThread();

        final var inputQueue = new ArrayBlockingQueue<String>(1);
        getGameActivity().showInputDialog(prompt, inputQueue);
        try {
            return inputQueue.take();
        } catch (InterruptedException ex) {
            showErrorDialog(ex.getMessage(), ErrorType.WAITING_INPUT_ERROR);
            return "";
        }
    }

    @Override
    public String showExecutorDialog(final String text) {
        assertNonUiThread();

        final var inputQueue = new ArrayBlockingQueue<String>(1);
        getGameActivity().showExecutorDialog(text, inputQueue);
        try {
            return inputQueue.take();
        } catch (InterruptedException ex) {
            showErrorDialog(ex.getMessage(), ErrorType.WAITING_INPUT_ERROR);
            return "";
        }
    }

    @Override
    public int showMenu(List<QSPLib.ListItem> items) {
        assertNonUiThread();

        final var resultQueue = new ArrayBlockingQueue<Integer>(1);
        final var newItems = new ArrayList<String>();
        items.forEach(libMenuItem -> newItems.add(libMenuItem.image()));
        getGameActivity().showMenuDialog(newItems, resultQueue);
        try {
            return resultQueue.take();
        } catch (InterruptedException ex) {
            showErrorDialog(ex.getMessage(), ErrorType.WAITING_ERROR);
            return -1;
        }
    }

    @Override
    public void showLoadGamePopup() {
        getGameActivity().showSimpleDialog("", GameDialogType.LOAD_DIALOG, null);
    }

    @Override
    public void showSaveGamePopup() {
        getGameActivity().showSavePopup();
    }

    @Override
    public void showWindow(LibWindowType type, final boolean show) {
        if (type == LibWindowType.ACTIONS) {
            showActions = show;
            refreshActionsRecycler();
        }
    }

    @Override
    public void setCounterInterval(int millis) {
        counterInterval = millis;
    }

    @Override
    public void doWithCounterDisabled(Runnable runnable) {
        counterHandler.removeCallbacks(counterTask);
        runnable.run();
        counterHandler.postDelayed(counterTask, counterInterval);
    }

    public class GameWebViewClient extends WebViewClient {
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
            final var uri = request.getUrl();
            if (uri.getScheme() == null) return false;
            final var uriDecode = Uri.decode(uri.toString());

            switch (uri.getScheme()) {
                case "exec" -> {
                    var uriStr = uri.toString();
                    Log.d(TAG, "shouldOverrideUrlLoading raw uri: " + uriStr);
                    var tempUriDecode = uriStr.length() > 5 && uriStr.startsWith("exec:") ? uriStr.substring(5) : uriStr;
                    tempUriDecode = Uri.decode(tempUriDecode);
                    if (tempUriDecode.startsWith("base64:") || tempUriDecode.startsWith("BASE64:")) {
                        tempUriDecode = decodeBase64(tempUriDecode.substring(7));
                    } else if (isBase64(tempUriDecode)) {
                        try {
                            tempUriDecode = decodeBase64(tempUriDecode);
                        } catch (Exception e) {
                            Log.w(TAG, "Base64 decode failed for exec: " + tempUriDecode, e);
                        }
                    }
                    tempUriDecode = tempUriDecode
                            .replace("<br>", "\n")
                            .replace("<br/>", "\n")
                            .replace("<br />", "\n")
                            .replace("<BR>", "\n")
                            .replace("<BR/>", "\n")
                            .replace("<BR />", "\n")
                            .replace("&amp;", "&")
                            .replace("&quot;", "\"")
                            .replace("&lt;", "<")
                            .replace("&gt;", ">")
                            .replace("&apos;", "'");
                    if (isHasHTMLTags(tempUriDecode)) {
                        tempUriDecode = removeHtmlTags(tempUriDecode);
                    }
                    tempUriDecode = tempUriDecode.trim();
                    Log.i(TAG, "Executing QSP command: [" + tempUriDecode + "] (len=" + tempUriDecode.length() + ")");
                    getLibProxy().execute(tempUriDecode);
                }
                case "https", "http" -> {
                    var host = uri.getHost();
                    if ("questopia.local".equalsIgnoreCase(host) || "appassets.androidplatform.net".equalsIgnoreCase(host)) {
                        return false;
                    }
                    var viewLink = new Intent(Intent.ACTION_VIEW, Uri.parse(uriDecode));
                    viewLink.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    getApplication().startActivity(viewLink);
                }
                case "file" -> {
                    try {
                        var tempLink = uri.getScheme().replace("file:/", "https:");
                        var viewLazyLink = new Intent(Intent.ACTION_VIEW, Uri.parse(tempLink));
                        viewLazyLink.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        getApplication().startActivity(viewLazyLink);
                    } catch (ActivityNotFoundException e) {
                        showErrorDialog(e.getMessage(), ErrorType.EXCEPTION);
                    }
                }
            }

            return true;
        }

        @Nullable
        @Override
        public WebResourceResponse shouldInterceptRequest(WebView view,
                                                          @NonNull WebResourceRequest request) {
            final var uri = request.getUrl();
            if (uri.getScheme() == null) return null;

            var rawPath = uri.getPath();
            if (rawPath == null || rawPath.isEmpty()) return null;
            while (rawPath.startsWith("/")) {
                rawPath = rawPath.substring(1);
            }
            var path = Uri.decode(rawPath).replace("\\", "/");
            if (path.startsWith("./")) {
                path = path.substring(2);
            }

            if (path.equalsIgnoreCase("favicon.ico")) {
                return new WebResourceResponse("image/x-icon", null, new ByteArrayInputStream(new byte[0]));
            }

            if (path.startsWith("ogv") || path.contains("ogv/") || path.contains("ogv//")) {
                int idx = path.indexOf("ogv");
                String assetPath = path.substring(idx).replaceAll("/+", "/");
                if (assetPath.contains("?")) {
                    assetPath = assetPath.substring(0, assetPath.indexOf("?"));
                }
                if (assetPath.contains("#")) {
                    assetPath = assetPath.substring(0, assetPath.indexOf("#"));
                }
                try {
                    var assetIn = getApplication().getAssets().open(assetPath);
                    var mime = "application/javascript";
                    if (assetPath.endsWith(".wasm")) {
                        mime = "application/wasm";
                    } else if (assetPath.endsWith(".css")) {
                        mime = "text/css";
                    }
                    var resp = new WebResourceResponse(mime, null, assetIn);
                    Map<String, String> headers = new HashMap<>();
                    headers.put("Access-Control-Allow-Origin", "*");
                    headers.put("Access-Control-Expose-Headers", "Content-Range, Content-Length, Accept-Ranges");
                    headers.put("Accept-Ranges", "bytes");
                    resp.setResponseHeaders(headers);
                    Log.d(TAG, "Served ogv asset: " + assetPath + " (" + mime + ")");
                    return resp;
                } catch (IOException e) {
                    Log.e(TAG, "Failed to load ogv asset: " + assetPath, e);
                }
            }

            if (getCurGameDir().isEmpty()) return null;
            final var rootDir = getCurGameDir().get();

            if (!uri.getScheme().startsWith("file") && !uri.getScheme().startsWith("http") && !uri.getScheme().startsWith("content"))
                return null;

            try {
                Log.d(TAG, "shouldInterceptRequest path: " + path);

                var imageFile = MediaUtil.findFileCaseInsensitive(rootDir, path);
                if (imageFile == null || !imageFile.exists()) {
                    imageFile = fromRelPath(getApplication(), path, rootDir);
                }
                if (imageFile == null || !imageFile.exists()) {
                    Log.w(TAG, "shouldInterceptRequest file not found: " + path);
                    throw new FileNotFoundException("Image/Media not found: " + path);
                }
                var mime = MediaUtil.getMimeType(imageFile.getName());
                long totalSize = imageFile.length();
                if (totalSize <= 0) {
                    try (var pfd = getApplication().getContentResolver().openFileDescriptor(imageFile.getUri(), "r")) {
                        if (pfd != null) {
                            totalSize = pfd.getStatSize();
                        }
                    } catch (Exception ignored) {}
                }

                var in = getApplication().getContentResolver().openInputStream(imageFile.getUri());
                if (in == null) return null;
                var response = new WebResourceResponse(mime, null, in);
                response.setStatusCodeAndReasonPhrase(200, "OK");
                Map<String, String> headers = new HashMap<>();
                if (totalSize > 0) {
                    headers.put("Content-Length", String.valueOf(totalSize));
                }
                headers.put("Content-Type", mime);
                headers.put("Access-Control-Allow-Origin", "*");
                headers.put("Access-Control-Expose-Headers", "Content-Range, Content-Length, Accept-Ranges");
                response.setResponseHeaders(headers);
                Log.d(TAG, "shouldInterceptRequest served: " + path + " (" + mime + ", size=" + totalSize + ")");
                return response;
            } catch (Exception ex) {
                if (getSettingsController().isUseImageDebug) {
                    showErrorDialog(uri.getPath(), ErrorType.IMAGE_ERROR);
                }
                return null;
            }
        }
    }
    // endregion GameInterface

    public QSPLib.VarItem[] getAllVariables() {
        if (getLibProxy() == null) return new QSPLib.VarItem[0];
        return getLibProxy().getAllVariables();
    }

    public String[] getAllLocations() {
        if (getLibProxy() == null) return new String[0];
        return getLibProxy().getAllLocations();
    }

    public byte[] getSaveData() {
        if (getLibProxy() == null) return null;
        return getLibProxy().getSaveData();
    }

    public boolean loadSaveData(byte[] data) {
        if (getLibProxy() == null) return false;
        return getLibProxy().loadSaveData(data);
    }

    public void executeCode(String code) {
        if (getLibProxy() != null) {
            getLibProxy().execute(code);
        }
    }

    public void setFrozenVariables(Map<String, String> frozen) {
        if (getLibProxy() != null) {
            getLibProxy().setFrozenVariables(frozen);
        }
    }

    public void refreshGameUi() {
        if (getLibProxy() != null) {
            getLibProxy().refreshGameUi();
        }
    }
}
