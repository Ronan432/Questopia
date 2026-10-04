package org.qp.android.model.lib;

import static org.qp.android.helpers.utils.FileUtil.findOrCreateFile;
import static org.qp.android.helpers.utils.FileUtil.fromFullPath;
import static org.qp.android.helpers.utils.FileUtil.fromRelPath;
import static org.qp.android.helpers.utils.FileUtil.getFileContents;
import static org.qp.android.helpers.utils.FileUtil.isWritableDir;
import static org.qp.android.helpers.utils.FileUtil.isWritableFile;
import static org.qp.android.helpers.utils.FileUtil.writeFileContents;
import static org.qp.android.helpers.utils.PathUtil.getFilename;
import static org.qp.android.helpers.utils.PathUtil.normalizeContentPath;
import static org.qp.android.helpers.utils.StringUtil.getStringOrEmpty;
import static org.qp.android.helpers.utils.StringUtil.isNotEmpty;
import static org.qp.android.helpers.utils.StringUtil.isNotEmptyOrBlank;
import static org.qp.android.helpers.utils.ThreadUtil.isSameThread;
import static org.qp.android.helpers.utils.ThreadUtil.throwIfNotMainThread;

import android.content.Context;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.documentfile.provider.DocumentFile;

import com.anggrayudi.storage.file.DocumentFileCompat;
import com.anggrayudi.storage.file.MimeType;
import com.libqsp.jni.QSPLib;

import org.qp.android.QuestopiaApplication;
import org.qp.android.model.service.AudioPlayer;
import org.qp.android.model.service.HtmlProcessor;
import org.qp.android.ui.game.GameInterface;

import java.io.File;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReentrantLock;

public class LibProxyImpl extends QSPLib implements LibIProxy {
    private final String TAG = this.getClass().getSimpleName();

    private final ReentrantLock libLock = new ReentrantLock();
    private final LibGameState gameState = new LibGameState();
    private final Context context;
    private Thread libThread;
    private volatile Handler libHandler;
    private volatile boolean libThreadInit;
    private volatile CountDownLatch initLatch;
    private volatile long gameStartTime;
    private volatile long lastMsCountCallTime;
    private GameInterface gameInterface;
    private final ConcurrentHashMap<String, String> frozenVariables = new ConcurrentHashMap<>();

    public LibProxyImpl(Context context) {
        this.context = context;
    }

    private QuestopiaApplication getApplication() {
        return (QuestopiaApplication) context;
    }

    @Nullable
    private DocumentFile getCurGameDir() {
        var file = DocumentFileCompat.fromUri(context, gameState.gameDirUri);
        if (!isWritableDir(context, file)) return null;
        return file;
    }

    private HtmlProcessor getHtmlProcessor() {
        return getApplication().getHtmlProcessor();
    }

    public AudioPlayer getAudioPlayer() {
        return getApplication().audioPlayer
                .setCurGameDir(getCurGameDir());
    }

    private void runOnQspThread(final Runnable runnable) {
        throwIfNotMainThread();
        if (libThread == null) {
            Log.w(TAG, "Lib thread has not been started!");
            return;
        }
        if (!libThreadInit && initLatch != null) {
            try {
                initLatch.await(3, TimeUnit.SECONDS);
            } catch (InterruptedException ignored) {}
        }
        if (!libThreadInit) {
            Log.w(TAG, "Lib thread has been started, but not initialized!");
            return;
        }
        var mLibHandler = libHandler;
        if (mLibHandler == null) return;
        mLibHandler.post(() -> {
            libLock.lock();
            try {
                runnable.run();
            } finally {
                libLock.unlock();
            }
        });
    }

    private boolean loadGameWorld() {
        final var gameFileUri = gameState.gameFileUri;
        if (gameFileUri == null || gameFileUri == Uri.EMPTY) {
            Log.e(TAG, "gameFileUri is null or empty!");
            return false;
        }
        final var gameData = getFileContents(context, gameFileUri);
        if (gameData == null) {
            Log.e(TAG, "Failed to read bytes from gameFileUri: " + gameFileUri);
            return false;
        }
        if (!loadGameWorldFromData(gameData, true)) {
            Log.e(TAG, "loadGameWorldFromData failed for URI: " + gameFileUri);
            showLastQspError();
            return false;
        }
        return true;
    }

    private void showLastQspError() {
        var errorData = getLastErrorData();
        var locName = getStringOrEmpty(errorData.locName);
        var desc = getStringOrEmpty(getErrorDesc(errorData.errorNum));
        var intLine = getStringOrEmpty(errorData.intLine);
        var sb = new StringBuilder();
        sb.append("Location: ").append(locName.isEmpty() ? "<Main/None>" : locName).append("\n");
        sb.append("Action Index: ").append(errorData.actIndex).append("\n");
        sb.append("Line: ").append(errorData.intLineNum);
        if (errorData.topLineNum > 0 && errorData.topLineNum != errorData.intLineNum) {
            sb.append(" (Top Line: ").append(errorData.topLineNum).append(")");
        }
        sb.append("\n");
        sb.append("Error Code: #").append(errorData.errorNum).append("\n");
        sb.append("Description: ").append(desc.isEmpty() ? "Unknown error" : desc);
        if (!intLine.isEmpty()) {
            sb.append("\nCode: ").append(intLine);
        }
        final var message = sb.toString();
        Log.e(TAG, "QSP Engine Error encountered:\n" + message);
        if (gameInterface == null) return;
        gameInterface.showErrorDialog(message);
    }

    /**
     * Loads the interface configuration - using HTML, font and colors - from the library.
     *
     * @return <code>true</code> if the configuration has changed, otherwise <code>false</code>
     */
    private boolean loadInterfaceConfiguration() {
        final var config = gameState.interfaceConfig;
        var changed = false;

        final var htmlResult = getNumVarValue("USEHTML", 0);
        final var useHtml = htmlResult != 0L;
        if (config.useHtml != useHtml) {
            config.useHtml = useHtml;
            changed = true;
        }

        final var fSizeResult = getNumVarValue("FSIZE", 0);
        if (config.fontSize != fSizeResult) {
            config.fontSize = (int) fSizeResult;
            changed = true;
        }

        final var bColorResult = getNumVarValue("BCOLOR", 0);
        if (config.backColor != bColorResult) {
            config.backColor = (int) bColorResult;
            changed = true;
        }

        final var fColorResult = getNumVarValue("FCOLOR", 0);
        if (config.fontColor != fColorResult) {
            config.fontColor = (int) fColorResult;
            changed = true;
        }

        final var lColorResult = getNumVarValue("LCOLOR", 0);
        if (config.linkColor != lColorResult) {
            config.linkColor = (int) lColorResult;
            changed = true;
        }

        return changed;
    }

    @NonNull
    private List<ListItem> getActionsList() {
        var gameDir = getCurGameDir();
        if (gameDir == null) return Collections.emptyList();
        var actions = new ArrayList<ListItem>();

        for (var element : getActions()) {
            var tempImagePath = element.image() == null ? "" : element.image();
            var tempText = element.name() == null ? "" : element.name();

            if (isNotEmptyOrBlank(tempImagePath)) {
                var tempPath = normalizeContentPath(getFilename(tempImagePath));
                if (tempPath != null) {
                    tempPath = tempPath.replace("\\", "/");
                    var fileFromPath = fromRelPath(context, tempPath, gameDir);
                    if (fileFromPath != null && fileFromPath.exists()) {
                        tempImagePath = String.valueOf(fileFromPath.getUri());
                    }
                }
            }

            actions.add(new ListItem(tempImagePath, tempText));
        }

        return actions;
    }

    @NonNull
    private List<ListItem> getObjectsList() {
        var gameDir = getCurGameDir();
        if (gameDir == null) return Collections.emptyList();
        var objects = new ArrayList<ListItem>();

        for (var element : getObjects()) {
            var tempImagePath = element.image() == null ? "" : element.image();
            var tempText = element.name() == null ? "" : element.name();

            if (isNotEmptyOrBlank(tempImagePath)) {
                var tempPath = normalizeContentPath(getFilename(tempImagePath));
                if (tempPath != null) {
                    tempPath = tempPath.replace("\\", "/");
                    var fileFromPath = fromRelPath(context, tempPath, gameDir);
                    if (fileFromPath != null && fileFromPath.exists()) {
                        tempImagePath = String.valueOf(fileFromPath.getUri());
                    }
                }
            } else if (tempText.contains("<img")) {
                var tempPath = getHtmlProcessor().getSrcDir(tempText);
                if (isNotEmptyOrBlank(tempPath)) {
                    tempPath = tempPath.replace("\\", "/");
                    var fileFromPath = fromRelPath(context, tempPath, gameDir);
                    if (fileFromPath != null && fileFromPath.exists()) {
                        tempImagePath = String.valueOf(fileFromPath.getUri());
                    }
                }
            }

            objects.add(new ListItem(tempImagePath, tempText));
        }

        return objects;
    }

    // region LibQpProxy

    public void startLibThread() {
        if (libThread != null && libThread.isAlive()) return;
        initLatch = new CountDownLatch(1);
        libThread = new Thread(() -> {
            while (!Thread.currentThread().isInterrupted()) {
                try {
                    init();
                    if (Looper.myLooper() == null) {
                        Looper.prepare();
                    }
                    libHandler = new Handler(Looper.myLooper());
                    libThreadInit = true;
                    if (initLatch != null) {
                        initLatch.countDown();
                    }
                    Looper.loop();
                    terminate();
                } catch (Throwable t) {
                    Log.e(TAG, "lib thread has stopped exceptionally", t);
                    Thread.currentThread().interrupt();
                    if (initLatch != null) {
                        initLatch.countDown();
                    }
                }
            }
        }, "libQSP");
        libThread.start();
        try {
            initLatch.await(3, TimeUnit.SECONDS);
        } catch (InterruptedException ignored) {}
    }

    public void stopLibThread() {
        throwIfNotMainThread();
        if (libThread == null) return;
        if (libThreadInit) {
            var handler = libHandler;
            if (handler != null) {
                handler.getLooper().quitSafely();
            }
            libThreadInit = false;
        } else {
            Log.w(TAG, "libqsp thread has been started, but not initialized");
        }
        libThread.interrupt();
        libThread = null;
        libHandler = null;
    }

    public void enableDebugMode(boolean isDebug) {
        runOnQspThread(() -> enableDebugMode(isDebug));
    }

    @Override
    public void runGame(final long id,
                        final String title,
                        final Uri dir,
                        final Uri file) {
        runOnQspThread(() -> doRunGame(id, title, dir, file));
    }

    private void doRunGame(final long id,
                           final String title,
                           final Uri dir,
                           final Uri file) {
        gameInterface.doWithCounterDisabled(() -> {
            gameState.reset();
            gameState.gameRunning = true;
            gameState.gameId = id;
            gameState.gameTitle = title;
            gameState.gameDirUri = dir;
            gameState.gameFileUri = file;
            getAudioPlayer().closeAllFiles();
            if (!loadGameWorld()) return;
            gameStartTime = SystemClock.elapsedRealtime();
            lastMsCountCallTime = 0;
            if (!restartGame(true)) {
                showLastQspError();
            }
        });
    }

    @Override
    public void restartGame() {
        runOnQspThread(() ->
                doRunGame(gameState.gameId, gameState.gameTitle,
                        gameState.gameDirUri, gameState.gameFileUri));
    }

    @Override
    public void loadGameState(final Uri uri) {
        if (!isSameThread(libHandler.getLooper().getThread())) {
            runOnQspThread(() -> loadGameState(uri));
            return;
        }
        final var gameData = getFileContents(context, uri);
        if (gameData == null) {
            Log.e(TAG, "Failed to load save game: getFileContents returned null for URI: " + uri);
            return;
        }
        Log.d(TAG, "Attempting to open saved game from URI: " + uri + " (data length: " + gameData.length + " bytes)");
        if (!openSavedGameFromData(gameData, true)) {
            Log.e(TAG, "Failed to open saved game from URI: " + uri + " (openSavedGameFromData returned false)");
            showLastQspError();
        } else {
            Log.i(TAG, "Successfully loaded save game from URI: " + uri);
        }
    }

    @Override
    public void saveGameState(final Uri uri) {
        if (!isSameThread(libHandler.getLooper().getThread())) {
            runOnQspThread(() -> saveGameState(uri));
            return;
        }
        final var gameData = saveGameAsData(false);
        if (gameData == null) return;
        writeFileContents(context, uri, gameData);
    }

    @Override
    public void onActionClicked(final int index) {
        runOnQspThread(() -> {
            var actions = getActions();
            if (actions == null || index < 0 || index >= actions.length) {
                Log.w(TAG, "Invalid action index clicked: " + index + " (available: " + (actions != null ? actions.length : 0) + ")");
                return;
            }
            if (!setSelActIndex(index, false)) {
                Log.e(TAG, "setSelActIndex failed for index: " + index);
                showLastQspError();
                return;
            }
            if (!execSelAction(true)) {
                Log.e(TAG, "execSelAction failed for index: " + index);
                showLastQspError();
            }
        });
    }

    @Override
    public void onObjectSelected(final int index) {
        runOnQspThread(() -> {
            var objects = getObjects();
            if (objects == null || index < 0 || index >= objects.length) {
                Log.w(TAG, "Invalid object index clicked: " + index + " (available: " + (objects != null ? objects.length : 0) + ")");
                return;
            }
            if (!setSelObjIndex(index, true)) {
                Log.e(TAG, "setSelObjIndex failed for index: " + index);
                showLastQspError();
            }
        });
    }

    @Override
    public void onInputAreaClicked() {
        final var inter = gameInterface;
        if (inter == null) return;
        runOnQspThread(() -> {
            var input = inter.showInputDialog("userInputTitle");
            setInputStrText(input);
            if (!execUserInput(true)) {
                showLastQspError();
            }
        });
    }

    @Override
    public void onUseExecutorString() {
        final var inter = gameInterface;
        if (inter == null) return;
        runOnQspThread(() -> {
            var input = inter.showExecutorDialog("execStringTitle");
            if (!execString(input, true)) {
                showLastQspError();
            }
        });
    }

    @Override
    public void execute(final String code) {
        runOnQspThread(() -> {
            Log.d(TAG, "execString called with: [" + code + "] (len=" + (code != null ? code.length() : 0) + ")");
            if (!execString(code, true)) {
                Log.e(TAG, "execString failed for code: [" + code + "]");
                showLastQspError();
            }
        });
    }

    @Override
    public void executeCounter() {
        if (libLock.isLocked()) return;
        runOnQspThread(() -> {
            if (!frozenVariables.isEmpty()) {
                for (var entry : frozenVariables.entrySet()) {
                    Log.d(TAG, "Enforcing frozen variable: " + entry.getKey() + " = " + entry.getValue());
                    if (!execString(entry.getKey() + " = " + entry.getValue(), false)) {
                        Log.e(TAG, "Failed to enforce frozen variable: " + entry.getKey() + " = " + entry.getValue());
                    }
                }
            }
            if (!execCounter(true)) {
                showLastQspError();
            }
        });
    }

    @Override
    public LibGameState getGameState() {
        return gameState;
    }

    @Override
    public void setGameInterface(GameInterface view) {
        gameInterface = view;
    }

    // endregion LibQpProxy

    // region LibQpCallbacks


    @Override
    public void onRefreshInt(boolean isForced) {
        var request = new LibRefIRequest();
        var configChanged = loadInterfaceConfiguration();

        if (configChanged) {
            request.isIConfigChanged = true;
        }
        if (isMainDescChanged()) {
            if (isNotEmptyOrBlank(gameState.mainDesc)) {
                if (!gameState.mainDesc.equals(getMainDesc())) {
                    gameState.mainDesc = getMainDesc();
                    request.isMainDescChanged = true;
                }
            } else {
                gameState.mainDesc = getMainDesc();
                request.isMainDescChanged = true;
            }
        }
        if (isActsChanged()) {
            if (gameState.actionsList.isEmpty()) {
                gameState.actionsList = getActionsList();
                request.isActionsChanged = true;
            } else {
                if (gameState.actionsList != getActionsList()) {
                    gameState.actionsList = getActionsList();
                    request.isActionsChanged = true;
                }
            }
        }
        if (isObjsChanged()) {
            if (gameState.objectsList.isEmpty()) {
                gameState.objectsList = getObjectsList();
                request.isObjectsChanged = true;
            } else {
                if (gameState.objectsList != getObjectsList()) {
                    gameState.objectsList = getObjectsList();
                    request.isObjectsChanged = true;
                }
            }
        }
        if (isVarsDescChanged()) {
            if (isNotEmptyOrBlank(gameState.varsDesc)) {
                if (!gameState.varsDesc.equals(getVarsDesc())) {
                    gameState.varsDesc = getVarsDesc();
                    request.isVarsDescChanged = true;
                }
            } else {
                gameState.varsDesc = getVarsDesc();
                request.isVarsDescChanged = true;
            }
        }

        var inter = gameInterface;
        if (inter != null) {
            inter.refresh(request);
        }
    }

    @Override
    public void onShowImage(String file) {
        Log.d(TAG, "onShowImage received file: " + file);
        var gameDir = getCurGameDir();
        if (gameDir == null || !gameDir.exists()) return;

        var inter = gameInterface;
        if (inter == null) return;

        if (isNotEmptyOrBlank(file)) {
            var picFile = fromRelPath(context, file, gameDir);
            if (picFile == null || !picFile.exists()) {
                var cleanFile = file.replace("\\", "/");
                while (cleanFile.startsWith("/")) {
                    cleanFile = cleanFile.substring(1);
                }
                var pathElements = cleanFile.split("/");
                var files = gameDir.listFiles();
                DocumentFile currentTarget = null;
                for (var part : pathElements) {
                    if (part.isEmpty()) continue;
                    currentTarget = null;
                    for (var f : files) {
                        var name = f.getName();
                        if (name != null && name.equalsIgnoreCase(part)) {
                            currentTarget = f;
                            if (f.isDirectory()) {
                                files = f.listFiles();
                            }
                            break;
                        }
                    }
                    if (currentTarget == null) break;
                }
                if (currentTarget != null && currentTarget.isFile()) {
                    picFile = currentTarget;
                }
            }
            if (picFile != null && picFile.exists()) {
                Log.i(TAG, "onShowImage: showing " + picFile.getUri());
                inter.showPicture(String.valueOf(picFile.getUri()));
            } else {
                Log.w(TAG, "onShowImage: file not found on disk: " + file);
            }
        }
    }

    @Override
    public void onSetTimer(int msecs) {
        var inter = gameInterface;
        if (inter == null) return;

        inter.setCounterInterval(msecs);
    }

    @Override
    public void onShowMessage(String text) {
        var inter = gameInterface;
        if (inter == null) return;

        inter.showMessage(text);
    }

    @Override
    public void onPlayFile(String file, int volume) {
        if (!isNotEmptyOrBlank(file)) return;

        getAudioPlayer().playFile(file, volume);
    }

    @Override
    public boolean onIsPlayingFile(String file) {
        return isNotEmptyOrBlank(file) && getAudioPlayer().isPlayingFile(file);
    }

    @Override
    public void onCloseFile(String path) {
        if (isNotEmpty(path)) {
            getAudioPlayer().closeFile(path);
        } else {
            getAudioPlayer().closeAllFiles();
        }
    }

    @Override
    public void onOpenGame(String file, boolean isNewGame) {
        var inter = gameInterface;
        if (inter == null) return;

        if (file == null) {
            inter.showLoadGamePopup();
        } else {
            try {
                var saveFile = fromFullPath(context, file);
                if (saveFile == null) {
                    Log.e(TAG, "Save file not found");
                    return;
                }
                var saveFileUri = saveFile.getUri();
                inter.doWithCounterDisabled(() -> loadGameState(saveFileUri));
            } catch (Exception e) {
                Log.e(TAG, "Error: ", e);
            }
        }
    }

    @Override
    public void onSaveGameStatus(String file) {
        var gameDir = getCurGameDir();
        if (!isWritableDir(context, gameDir)) return;

        if (file == null) {
            var inter = gameInterface;
            if (inter == null) return;
            inter.showSaveGamePopup();
        } else {
            var saveFile = findOrCreateFile(
                    context,
                    gameDir,
                    new File(file).getName(),
                    MimeType.TEXT
            );
            if (isWritableFile(context, saveFile)) {
                saveGameState(saveFile.getUri());
            } else {
                Log.e(TAG, "Error access dir");
            }
        }
    }

    @Override
    public String onInputBox(String text) {
        return gameInterface != null ? gameInterface.showInputDialog(text) : "";
    }

    @Override
    public int onGetMsCount() {
        var now = SystemClock.elapsedRealtime();
        if (lastMsCountCallTime == 0) {
            lastMsCountCallTime = gameStartTime;
        }
        var dt = (int) (now - lastMsCountCallTime);
        lastMsCountCallTime = now;
        return dt;
    }

    @Override
    public int onShowMenu(ListItem[] items) {
        var inter = gameInterface;
        if (inter == null) return super.onShowMenu(items);
        var result = inter.showMenu(List.of(items));
        return result != -1 ? result : super.onShowMenu(items);
    }

    @Override
    public void onSleep(int msecs) {
        try {
            Thread.sleep(msecs);
        } catch (InterruptedException ex) {
            Log.e(TAG, "Wait failed", ex);
        }
    }

    @Override
    public void onShowWindow(int type, boolean toShow) {
        var inter = gameInterface;
        if (inter == null) return;
        var windowType = LibWindowType.values()[type];
        inter.showWindow(windowType, toShow);
    }

    @Override
    public void onOpenGameStatus(String file) {
        var gameDir = getCurGameDir();
        if (!isWritableDir(context, gameDir)) return;

        var newGameDir = fromRelPath(context, file, gameDir);
        if (!isWritableFile(context, newGameDir)) {
            Log.e(TAG, "Game directory not found: " + file);
            return;
        }

        gameState.gameDirUri = newGameDir.getUri();
    }

    @Override
    public VarItem[] getAllVariables() {
        libLock.lock();
        try {
            return super.getAllVariables();
        } finally {
            libLock.unlock();
        }
    }

    @Override
    public String[] getAllLocations() {
        libLock.lock();
        try {
            return super.getAllLocations();
        } finally {
            libLock.unlock();
        }
    }

    @Override
    public byte[] getSaveData() {
        libLock.lock();
        try {
            return saveGameAsData(false);
        } finally {
            libLock.unlock();
        }
    }

    @Override
    public boolean loadSaveData(byte[] data) {
        if (data == null) {
            Log.e(TAG, "Failed to load save data: byte array is null");
            return false;
        }
        libLock.lock();
        try {
            Log.d(TAG, "Attempting to open saved game from byte array (length: " + data.length + " bytes)");
            boolean success = openSavedGameFromData(data, true);
            if (!success) {
                Log.e(TAG, "Failed to open saved game from byte array (openSavedGameFromData returned false)");
                showLastQspError();
            } else {
                Log.i(TAG, "Successfully loaded save game from byte array");
            }
            return success;
        } finally {
            libLock.unlock();
        }
    }

    @Override
    public void setFrozenVariables(Map<String, String> frozen) {
        frozenVariables.clear();
        if (frozen != null && !frozen.isEmpty()) {
            frozenVariables.putAll(frozen);
            Log.d(TAG, "Updated frozen variables map: " + frozenVariables);
        } else {
            Log.d(TAG, "Cleared frozen variables map");
        }
    }

    @Override
    public void refreshGameUi() {
        runOnQspThread(() -> onRefreshInt(true));
    }

    // endregion LibQpCallbacks
}
