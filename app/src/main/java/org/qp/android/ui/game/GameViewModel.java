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

import android.annotation.SuppressLint;
import android.app.Application;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.graphics.Color;
import android.net.Uri;
import android.os.Handler;
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

import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.CountDownLatch;

public class GameViewModel extends AndroidViewModel implements GameInterface {

    private static final String PAGE_HEAD_TEMPLATE = """
            <!DOCTYPE html>
            <head>
            <meta name="viewport" content="width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1">
            <style type="text/css">
              body {
                margin: 0;
                padding: 12px;
                color: QSPTEXTCOLOR;
                background-color: QSPBACKCOLOR;
                font-size: QSPFONTSIZE;
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
              video {
                display: block;
                max-width: 100%;
                margin: 8px auto;
                border-radius: 8px;
              }
              a { color: QSPLINKCOLOR; text-decoration: underline; }
              a:link { color: QSPLINKCOLOR; }
            </style>
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
        var themeMode = preferences.getString("themeMode", "system");
        if ("dark".equals(themeMode) || "amoled".equals(themeMode)) {
            return true;
        } else if ("light".equals(themeMode)) {
            return false;
        } else {
            int nightModeFlags = getApplication().getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK;
            return nightModeFlags == Configuration.UI_MODE_NIGHT_YES;
        }
    }

    public boolean isAmoledTheme() {
        var themeMode = preferences.getString("themeMode", "system");
        return "amoled".equals(themeMode);
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
        if (getCurGameDir().isPresent()) {
            var imageFile = fromRelPath(getApplication(), relPath, getCurGameDir().get());
            return imageFile.getUri();
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

    @NonNull
    private GameActivity getGameActivity() {
        var activity = activityObserver.getValue();
        if (activity != null) {
            return activity;
        } else {
            throw new NullPointerException("Activity is null");
        }
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
        var libMainDesc = getHtml(getLibGameState().mainDesc);
        var dirtyHTML = pageTemplate.replace("REPLACETEXT", libMainDesc);
        var cleanHTML = "";
        if (getSettingsController().isImageDisabled) {
            cleanHTML = getHtmlProcessor().getCleanHtmlRemMedia(dirtyHTML);
        } else {
            cleanHTML = getHtmlProcessor().getCleanHtmlAndMedia(getApplication(), dirtyHTML);
        }
        if (!cleanHTML.isBlank()) {
            getGameActivity().warnUser(GameActivity.TAB_MAIN_DESC_AND_ACTIONS);
        }
        mainDescLiveData.postValue(cleanHTML);
    }

    private void refreshVarsDesc() {
        final var libVarsDesc = getHtml(getLibGameState().varsDesc);
        final var dirtyHTML = pageTemplate.replace("REPLACETEXT", libVarsDesc);
        var cleanHTML = "";
        if (getSettingsController().isImageDisabled) {
            cleanHTML = getHtmlProcessor().getCleanHtmlRemMedia(dirtyHTML);
        } else {
            cleanHTML = getHtmlProcessor().getCleanHtmlAndMedia(getApplication(), dirtyHTML);
        }
        if (!cleanHTML.isBlank()) {
            getGameActivity().warnUser(GameActivity.TAB_VARS_DESC);
        }
        varsDescLiveData.postValue(cleanHTML);
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
                    var tempUriDecode = uriDecode.substring(5);
                    if (isBase64(tempUriDecode)) {
                        tempUriDecode = decodeBase64(uriDecode.substring(5));
                    } else {
                        tempUriDecode = uriDecode.substring(5);
                    }
                    if (isHasHTMLTags(tempUriDecode)) {
                        getLibProxy().execute(removeHtmlTags(tempUriDecode));
                    } else {
                        getLibProxy().execute(tempUriDecode);
                    }
                }
                case "https", "http" -> {
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
            if (getCurGameDir().isEmpty()) return null;
            final var uri = request.getUrl();
            if (uri.getScheme() == null) return null;
            final var rootDir = getCurGameDir().get();

            if (!uri.getScheme().startsWith("file") && !uri.getScheme().startsWith("http") && !uri.getScheme().startsWith("content"))
                return null;

            try {
                var path = uri.getPath();
                if (path == null || path.isEmpty()) return null;
                while (path.startsWith("/")) {
                    path = path.substring(1);
                }
                var imageFile = fromRelPath(getApplication(), path, rootDir);
                if (imageFile == null || !imageFile.exists()) {
                    var pathElements = path.split("/");
                    var files = rootDir.listFiles();
                    DocumentFile currentTarget = null;
                    for (var part : pathElements) {
                        if (part.isEmpty()) continue;
                        currentTarget = null;
                        for (var file : files) {
                            var name = file.getName();
                            if (name != null && name.equalsIgnoreCase(part)) {
                                currentTarget = file;
                                if (file.isDirectory()) {
                                    files = file.listFiles();
                                }
                                break;
                            }
                        }
                        if (currentTarget == null) break;
                    }
                    if (currentTarget != null && currentTarget.isFile()) {
                        imageFile = currentTarget;
                    }
                }
                if (imageFile == null || !imageFile.exists()) {
                    throw new FileNotFoundException("Image not found: " + path);
                }
                var extension = MimeTypeMap.getSingleton().getMimeTypeFromExtension(getExtension(imageFile));
                if (extension == null) {
                    extension = "image/*";
                }
                var in = getApplication().getContentResolver().openInputStream(imageFile.getUri());
                return new WebResourceResponse(extension, null, in);
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
