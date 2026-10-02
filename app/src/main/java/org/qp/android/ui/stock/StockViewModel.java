package org.qp.android.ui.stock;

import static org.qp.android.QuestopiaApplication.UNPACK_GAME_CHANNEL_ID;
import static org.qp.android.QuestopiaApplication.UNPACK_GAME_NOTIFICATION_ID;
import static org.qp.android.helpers.utils.DirUtil.MOD_DIR_NAME;
import static org.qp.android.helpers.utils.DirUtil.calculateDirSize;
import static org.qp.android.helpers.utils.DirUtil.getNamesDir;
import static org.qp.android.helpers.utils.DirUtil.isDirContainsGameFile;
import static org.qp.android.helpers.utils.DirUtil.isModDirExist;
import static org.qp.android.helpers.utils.FileUtil.copyFileToDir;
import static org.qp.android.helpers.utils.FileUtil.findOrCreateFile;
import static org.qp.android.helpers.utils.FileUtil.findOrCreateFolder;
import static org.qp.android.helpers.utils.FileUtil.forceDelFile;
import static org.qp.android.helpers.utils.FileUtil.formatFileSize;
import static org.qp.android.helpers.utils.FileUtil.fromRelPath;
import static org.qp.android.helpers.utils.FileUtil.isWritableDir;
import static org.qp.android.helpers.utils.FileUtil.isWritableFile;
import static org.qp.android.helpers.utils.JsonUtil.jsonToObject;
import static org.qp.android.helpers.utils.JsonUtil.objectToJson;
import static org.qp.android.helpers.utils.PathUtil.removeExtension;
import static org.qp.android.helpers.utils.StringUtil.isNotEmptyOrBlank;
import static org.qp.android.helpers.utils.ThreadUtil.runOnUiThread;
import static org.qp.android.helpers.utils.XmlUtil.xmlToObject;

import android.annotation.SuppressLint;
import android.app.Application;
import android.app.DownloadManager;
import android.app.NotificationManager;
import android.content.Intent;
import android.net.Uri;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.IdRes;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.documentfile.provider.DocumentFile;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.MutableLiveData;

import com.anggrayudi.storage.callback.FileCallback;
import com.anggrayudi.storage.file.DocumentFileCompat;
import com.anggrayudi.storage.file.MimeType;

import org.qp.android.R;
import org.qp.android.dto.stock.GameData;
import org.qp.android.dto.stock.RemoteDataList;
import org.qp.android.dto.stock.RemoteGameData;
import org.qp.android.helpers.ErrorType;
import org.qp.android.model.archive.ArchiveUnpack;
import org.qp.android.model.notify.NotifyBuilder;
import org.qp.android.model.repository.LocalGame;
import org.qp.android.model.repository.RemoteGameRepository;
import org.qp.android.ui.game.GameActivity;
import org.qp.android.ui.settings.SettingsController;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class StockViewModel extends AndroidViewModel {

    public static final long DISABLE_CALC_SIZE = -1;
    public static final String EXT_GAME_LIST_NAME = "extGameDirs";
    private static final String INNER_GAME_DIR_NAME = "games-dir";
    public final MutableLiveData<Integer> currPageNumber = new MutableLiveData<>();
    public final MutableLiveData<List<GameData>> remoteDataList = new MutableLiveData<>();
    public final MutableLiveData<List<GameData>> localDataList = new MutableLiveData<>();
    public final File listDirsFile;
    private final ExecutorService executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
    private final ExecutorService singleExecutor = Executors.newSingleThreadExecutor();
    private final HashMap<Long, GameData> gamesMap = new HashMap<>();
    private final LocalGame localGame = new LocalGame(getApplication());
    private final DownloadManager downloadManager = getApplication().getSystemService(DownloadManager.class);
    private final File rootInDir;
    private final FileCallback callback = new FileCallback() {
        @Override
        public void onConflict(@NonNull DocumentFile destinationFile,
                               @NonNull FileConflictAction action) {
            action.confirmResolution(ConflictResolution.REPLACE);
        }
    };
    public List<DocumentFile> extGamesListDir = new ArrayList<>();
    public GameData currGameData;
    private long downloadId = 0L;

    public StockViewModel(@NonNull Application application) {
        super(application);

        currPageNumber.setValue(0);
        var cache = getApplication().getExternalCacheDir();
        listDirsFile = findOrCreateFile(getApplication(), cache, EXT_GAME_LIST_NAME, MimeType.TEXT);

        var rootInDir = getApplication().getExternalFilesDir(null);
        this.rootInDir = findOrCreateFolder(getApplication(), rootInDir, INNER_GAME_DIR_NAME);
        Log.i("QUESTLOGTEST", "StockViewModel initialized. rootInDir: " + this.rootInDir.getAbsolutePath());
        loadExternalDirsFromCache();
        syncRemoteFromCache();
    }

    // region Getter/Setter

    public void setDataList(List<GameData> insertList) {
        if (localDataList.hasActiveObservers()) {
            localDataList.setValue(insertList);
        }
        if (remoteDataList.hasActiveObservers()) {
            remoteDataList.setValue(insertList);
        }
    }

    @NonNull
    private SettingsController getController() {
        return SettingsController.newInstance(getApplication());
    }

    public Optional<GameData> getCurrGameData() {
        return Optional.ofNullable(currGameData);
    }

    public HashMap<Long, GameData> getGamesMap() {
        return gamesMap;
    }

    public String getGameTitle() {
        var data = currGameData;
        if (data == null) return "";

        var title = data.title;
        if (!isNotEmptyOrBlank(title)) return "";

        return title;
    }

    public String getGameAuthor() {
        var data = currGameData;
        if (data == null) return "";

        var author = data.author;
        if (!isNotEmptyOrBlank(author)) return "";

        var authorString = ActivityCompat.getString(getApplication(), R.string.author);
        return authorString.replace("-AUTHOR-", author);
    }

    public Uri getGameIcon() {
        var data = currGameData;
        if (data == null) return Uri.EMPTY;

        var icon = data.iconUrl;
        if (!isNotEmptyOrBlank(String.valueOf(icon))) return Uri.EMPTY;

        return icon;
    }

    public String getGamePortBy() {
        var data = currGameData;
        if (data == null) return "";

        var portedBy = data.portedBy;
        if (!isNotEmptyOrBlank(portedBy)) return "";

        var portedByString = ActivityCompat.getString(getApplication(), R.string.ported_by);
        return portedByString.replace("-PORTED_BY-", portedBy);
    }

    public String getGameVersion() {
        var data = currGameData;
        if (data == null) return "";

        var version = data.version;
        if (!isNotEmptyOrBlank(version)) return "";

        var versionString = ActivityCompat.getString(getApplication(), R.string.version);
        return versionString.replace("-VERSION-", version);
    }

    public String getGameType() {
        var data = currGameData;
        if (data == null) return "";

        var fileExt = data.fileExt;
        if (!isNotEmptyOrBlank(fileExt)) return "";

        var fileTypeSting = ActivityCompat.getString(getApplication(), R.string.fileType);
        if (fileExt.equals("aqsp")) {
            var experimentalString = ActivityCompat.getString(getApplication(), R.string.experimental);
            return fileTypeSting.replace("-TYPE-", fileExt) + " " + experimentalString;
        } else {
            return fileTypeSting.replace("-TYPE-", fileExt);
        }
    }

    public long getGameSize() {
        var data = currGameData;
        if (data == null) return 0L;
        return data.fileSize;
    }

    public String getFormattedGameSize() {
        var data = currGameData;
        if (data == null) return "";

        var fileSize = data.fileSize;
        if (fileSize == DISABLE_CALC_SIZE) return "";

        var currBinPref = getController().binaryPrefixes;
        var sizeWithPref = formatFileSize(fileSize, currBinPref);

        var fileSizeString = ActivityCompat.getString(getApplication(), R.string.fileSize);
        return fileSizeString.replace("-SIZE-", sizeWithPref);
    }

    public boolean isPubModDataExist() {
        return isNotEmptyOrBlank(getGamePubData()) || isNotEmptyOrBlank(getGameModData());
    }

    public String getGamePubData() {
        var data = currGameData;
        if (data == null) return "";

        var pubDate = data.pubDate;
        if (!isNotEmptyOrBlank(pubDate)) return "";

        var formattedDate = formatRelativeDate(pubDate);
        var pubDataString = ActivityCompat.getString(getApplication(), R.string.pub_data);
        return pubDataString.replace("-PUB_DATA-", formattedDate);
    }

    public String getGameModData() {
        var data = currGameData;
        if (data == null) return "";

        var modDate = data.modDate;
        if (!isNotEmptyOrBlank(modDate)) return "";

        var formattedDate = formatRelativeDate(modDate);
        var modDataString = ActivityCompat.getString(getApplication(), R.string.mod_data);
        return modDataString.replace("-MOD_DATA-", formattedDate);
    }

    public static String formatRelativeDate(String dateStr) {
        if (dateStr == null || dateStr.trim().isEmpty()) return "";
        try {
            var format = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.ROOT);
            var date = format.parse(dateStr.trim());
            if (date != null) {
                return android.text.format.DateUtils.getRelativeTimeSpanString(
                        date.getTime(),
                        System.currentTimeMillis(),
                        android.text.format.DateUtils.MINUTE_IN_MILLIS,
                        android.text.format.DateUtils.FORMAT_ABBREV_RELATIVE
                ).toString();
            }
        } catch (Exception ignored) {
            try {
                var format2 = new java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.ROOT);
                var date2 = format2.parse(dateStr.trim());
                if (date2 != null) {
                    return android.text.format.DateUtils.getRelativeTimeSpanString(
                            date2.getTime(),
                            System.currentTimeMillis(),
                            android.text.format.DateUtils.DAY_IN_MILLIS,
                            android.text.format.DateUtils.FORMAT_ABBREV_RELATIVE
                    ).toString();
                }
            } catch (Exception e) {
                return dateStr;
            }
        }
        return dateStr;
    }

    public int getCountGameFiles() {
        var gameData = currGameData;
        if (gameData == null) return 0;
        return gameData.gameFilesUri.size();
    }

    @NonNull
    public Uri getGameFile(int index) {
        var gameData = currGameData;
        if (gameData == null) return Uri.EMPTY;
        return gameData.gameFilesUri.get(index);
    }

    public boolean isGamePossiblyDownload() {
        return !isGameInstalled() && isHasRemoteUrl();
    }

    public boolean isGameInstalled() {
        var gameData = currGameData;
        if (gameData == null) return false;
        var filesUri = gameData.gameFilesUri;
        if (filesUri == null || filesUri.isEmpty()) {
            var rootDirUri = gameData.gameDirUri;
            if (rootDirUri == Uri.EMPTY) return false;
            if (isNotEmptyOrBlank(String.valueOf(rootDirUri))) {
                return isDirContainsGameFile(getApplication(), rootDirUri); // it's too heavy!
            }
        } else {
            return true;
        }
        return false;
    }

    public boolean isGameInstalled(GameData entry) {
        if (entry == null) return false;
        var filesUri = entry.gameFilesUri;
        if (filesUri == null || filesUri.isEmpty()) {
            var rootDirUri = entry.gameDirUri;
            if (rootDirUri == Uri.EMPTY) return false;
            if (!isNotEmptyOrBlank(String.valueOf(rootDirUri))) return false;
            return isDirContainsGameFile(getApplication(), rootDirUri);
        } else {
            return true;
        }
    }

    public boolean isHasRemoteUrl() {
        var gameData = currGameData;
        if (gameData == null) return false;
        return isNotEmptyOrBlank(currGameData.fileUrl);
    }

    public boolean isModsDirExist() {
        var gameData = currGameData;
        if (gameData == null) return false;
        return isModDirExist(getApplication(), currGameData.gameDirUri);
    }

    // endregion Getter/Setter

    public void saveGameData(GameData gameData) {
        if (gameData == null || gameData.gameDirUri == null) return;
        CompletableFuture.runAsync(() -> {
            var gameDir = DocumentFileCompat.fromUri(getApplication(), gameData.gameDirUri);
            if (gameDir != null) {
                localGame.createDataIntoFolder(gameData, gameDir);
            }
        }, executor).thenRun(() -> refreshGamesDirs(null));
    }

    public Optional<Intent> createPlayGameIntent() {
        if (getCurrGameData().isPresent()) {
            var data = getCurrGameData().get();
            var gameDir = DocumentFileCompat.fromUri(getApplication(), currGameData.gameDirUri);
            if (!isWritableDir(getApplication(), gameDir)) return Optional.empty();
            var intent = new Intent(getApplication(), GameActivity.class);

            intent.putExtra("gameId", data.id);
            intent.putExtra("gameTitle", data.title);
            intent.putExtra("gameDirUri", String.valueOf(gameDir.getUri()));
            if (data.gameFilesUri != null && !data.gameFilesUri.isEmpty()) {
                intent.putExtra("gameFileUri", String.valueOf(data.gameFilesUri.get(0)));
            }

            return Optional.of(intent);
        } else {
            return Optional.empty();
        }
    }

    // region Refresh
    public void loadExternalDirsFromCache() {
        CompletableFuture.supplyAsync(() -> {
            try {
                var map = (HashMap<String, String>) jsonToObject(listDirsFile, HashMap.class);
                return map != null ? map : new HashMap<String, String>();
            } catch (Exception e) {
                Log.w("QUESTLOGTEST", "Failed to read listDirsFile cache: " + e.getMessage());
                return new HashMap<String, String>();
            }
        }, singleExecutor).thenAcceptAsync(map -> {
            if (map != null && !map.isEmpty()) {
                for (var entry : map.entrySet()) {
                    var uriStr = entry.getValue();
                    if (isNotEmptyOrBlank(uriStr)) {
                        var uri = Uri.parse(uriStr);
                        var docFile = DocumentFileCompat.fromUri(getApplication(), uri);
                        if (docFile != null && docFile.exists()) {
                            if (!extGamesListDir.contains(docFile)) {
                                extGamesListDir.add(docFile);
                                Log.d("QUESTLOGTEST", "Loaded external game dir from cache: " + docFile.getName() + " -> " + uri);
                            }
                        } else {
                            Log.w("QUESTLOGTEST", "Cached external game dir not found or inaccessible: " + uriStr);
                        }
                    }
                }
            }
            refreshGameData();
        }, executor);
    }

    public void addGameDataDirectly(GameData data) {
        if (data == null) return;
        Log.i("QUESTLOGTEST", "addGameDataDirectly adding game: " + data.title + " (ID: " + data.id + ")");
        gamesMap.put(data.id, data);
        var list = new ArrayList<>(gamesMap.values());
        localDataList.postValue(list);
    }

    public void refreshGamesDirs(DocumentFile gameExDir) {
        Log.d("QUESTLOGTEST", "refreshGamesDirs called with: " + (gameExDir != null ? gameExDir.getName() : "null"));
        if (gameExDir != null) {
            if (isWritableDir(getApplication(), gameExDir) || gameExDir.exists()) {
                if (!extGamesListDir.contains(gameExDir)) {
                    extGamesListDir.add(gameExDir);
                }
                refreshGameData();
            } else {
                Log.w("QUESTLOGTEST", "gameExDir does not exist or not writable: " + gameExDir.getUri());
                var dirName = gameExDir.getName();
                if (isNotEmptyOrBlank(dirName)) {
                    removeDirFromListDirsFile(listDirsFile, dirName);
                }
            }
        } else {
            loadExternalDirsFromCache();
        }
    }

    private CompletableFuture<List<GameData>> fetchInternalData() {
        return CompletableFuture
                .supplyAsync(() -> {
                    try {
                        return localGame.lightExtractDataFromDir(rootInDir);
                    } catch (IOException e) {
                        Log.e("QUESTLOGTEST", "Error in fetchInternalData: " + e.getMessage(), e);
                        throw new CompletionException(e);
                    }
                }, executor);
    }

    private CompletableFuture<List<GameData>> fetchExternalData() {
        return CompletableFuture
                .supplyAsync(() -> {
                    try {
                        Log.d("QUESTLOGTEST", "fetchExternalData scanning " + extGamesListDir.size() + " external directories");
                        return localGame.lightExtractDataFromList(extGamesListDir);
                    } catch (IOException e) {
                        Log.e("QUESTLOGTEST", "Error in fetchExternalData: " + e.getMessage(), e);
                        throw new CompletionException(e);
                    }
                }, executor);
    }

    private CompletableFuture<List<RemoteGameData>> fetchRemoteData() {
        return CompletableFuture
                .supplyAsync(() -> {
                    File[] potentialCaches = new File[] {
                        new File(getApplication().getFilesDir(), "remote_stock.xml"),
                        new File(getApplication().getExternalCacheDir(), "stock.xml")
                    };
                    for (var file : potentialCaches) {
                        if (file != null && file.exists() && file.length() > 0) {
                            try {
                                var dataList = xmlToObject(file, RemoteDataList.class);
                                if (dataList != null && dataList.game != null && !dataList.game.isEmpty()) {
                                    Log.d("QUESTLOGTEST", "Parsed " + dataList.game.size() + " games from cached XML file: " + file.getAbsolutePath());
                                    return dataList.game;
                                }
                            } catch (Exception e) {
                                Log.w("QUESTLOGTEST", "Could not parse cache file " + file.getName() + ": " + e.getMessage());
                            }
                        }
                    }
                    return Collections.emptyList();
                }, executor);
    }

    public void refreshGameData() {
        var pageNumber = currPageNumber.getValue();
        if (pageNumber == null) {
            pageNumber = 0;
            currPageNumber.postValue(0);
        }
        Log.d("QUESTLOGTEST", "refreshGameData started for page: " + pageNumber + ", extGamesCount=" + extGamesListDir.size());

        if (pageNumber == 0) {
            syncFromDisk();
        } else if (pageNumber == 1) {
            syncRemote();
        }
    }

    private void syncFromDisk() {
        Log.d("QUESTLOGTEST", "syncFromDisk: reading internal and external game dirs...");
        fetchInternalData()
                .thenCombineAsync(fetchExternalData(), (intDataList, extDataList) -> {
                    Log.d("QUESTLOGTEST", "Fetched internal games: " + intDataList.size() + ", external games: " + extDataList.size());
                    var combined = new ArrayList<GameData>(intDataList);
                    combined.addAll(extDataList);
                    return combined;
                }, executor)
                .thenAcceptAsync(externalGameData -> {
                    gamesMap.clear();
                    externalGameData.forEach(localGameData -> {
                        if (localGameData.id == 0L) {
                            localGameData.id = (long) (localGameData.gameDirUri != null && localGameData.gameDirUri != Uri.EMPTY ? localGameData.gameDirUri.hashCode() : (localGameData.title != null ? localGameData.title.hashCode() : System.currentTimeMillis()));
                        }
                        if (localGameData.gameDirUri != null && localGameData.gameDirUri != Uri.EMPTY) {
                            try {
                                var docDir = DocumentFileCompat.fromUri(getApplication(), localGameData.gameDirUri);
                                if (docDir != null && docDir.exists()) {
                                    long actualSize = calculateDirSize(docDir);
                                    if (actualSize > 0) {
                                        localGameData.fileSize = actualSize;
                                    }
                                } else if ("file".equalsIgnoreCase(localGameData.gameDirUri.getScheme())) {
                                    var fileDir = new File(localGameData.gameDirUri.getPath());
                                    if (fileDir.exists()) {
                                        long actualSize = calculateDirSize(fileDir);
                                        if (actualSize > 0) {
                                            localGameData.fileSize = actualSize;
                                        }
                                    }
                                }
                            } catch (Exception e) {
                                Log.w("QUESTLOGTEST", "Error calculating actual folder size: " + e.getMessage());
                            }
                        }
                        Log.d("QUESTLOGTEST", "Found game: '" + localGameData.title + "' (ID: " + localGameData.id + ", Size: " + localGameData.fileSize + ")");
                        gamesMap.put(localGameData.id, localGameData);
                    });
                }, executor)
                .thenApplyAsync(x -> {
                    var syncDataList = Collections.synchronizedCollection(gamesMap.values());
                    if (syncDataList.size() < 2) return new ArrayList<>(syncDataList);
                    synchronized (syncDataList) {
                        return syncDataList.stream()
                                .filter(game -> isNotEmptyOrBlank(game.title))
                                .sorted(Comparator.comparing(game -> game.title.toLowerCase()))
                                .sorted(Comparator.comparing(game -> game.listId))
                                .toList();
                    }
                }, executor)
                .thenAccept(list -> {
                    Log.i("QUESTLOGTEST", "syncFromDisk finished! Posting " + list.size() + " games to localDataList");
                    localDataList.postValue(List.copyOf(list));
                })
                .exceptionally(throwable -> {
                    Log.e("QUESTLOGTEST", "syncFromDisk error: " + throwable.getMessage(), throwable);
                    return null;
                });
    }

    public void fetchRemoteRepository() {
        Log.i("QUESTLOGTEST", "fetchRemoteRepository: Fetching remote repository games list via Ktor HttpClient...");
        new RemoteGameRepository().fetchRemoteGamesXmlAsync()
                .thenAcceptAsync(xmlStr -> {
                    try {
                        Log.d("QUESTLOGTEST", "Received remote repository XML payload, size: " + xmlStr.length() + " chars");
                        try {
                            var permCache = new File(getApplication().getFilesDir(), "remote_stock.xml");
                            try (var fos = new FileOutputStream(permCache)) {
                                fos.write(xmlStr.getBytes(StandardCharsets.UTF_8));
                            }
                            var cacheFile = new File(getApplication().getExternalCacheDir(), "stock.xml");
                            try (var fos = new FileOutputStream(cacheFile)) {
                                fos.write(xmlStr.getBytes(StandardCharsets.UTF_8));
                            }
                        } catch (Exception e) {
                            Log.w("QUESTLOGTEST", "Failed saving XML cache to disk: " + e.getMessage());
                        }
                        var dataList = xmlToObject(xmlStr, RemoteDataList.class);
                        if (dataList != null && dataList.game != null) {
                            var games = new ArrayList<GameData>();
                            long fallbackId = 1L;
                            for (var rem : dataList.game) {
                                if (isNotEmptyOrBlank(rem.title)) {
                                    var g = new GameData(rem);
                                    if (g.id == 0L) {
                                        g.id = fallbackId++;
                                    }
                                    games.add(g);
                                }
                            }
                            Log.i("QUESTLOGTEST", "Successfully parsed " + games.size() + " games from repository!");
                            remoteDataList.postValue(games);
                        }
                    } catch (Exception e) {
                        Log.e("QUESTLOGTEST", "Error parsing remote XML payload: " + e.getMessage(), e);
                        syncRemoteFromCache();
                    }
                }, executor)
                .exceptionally(t -> {
                    Log.e("QUESTLOGTEST", "Network failure fetching remote repository: " + t.getMessage());
                    syncRemoteFromCache();
                    return null;
                });
    }

    private void syncRemoteFromCache() {
        fetchRemoteData().thenAccept(remDataList -> {
            if (remDataList != null && !remDataList.isEmpty()) {
                var games = new ArrayList<GameData>();
                long fallbackId = 1L;
                for (var rem : remDataList) {
                    if (isNotEmptyOrBlank(rem.title)) {
                        var g = new GameData(rem);
                        if (g.id == 0L) {
                            g.id = fallbackId++;
                        }
                        games.add(g);
                    }
                }
                Log.d("QUESTLOGTEST", "Loaded " + games.size() + " remote games from cache fallback");
                remoteDataList.postValue(games);
            }
        });
    }

    private void syncRemote() {
        if (remoteDataList.getValue() != null && !remoteDataList.getValue().isEmpty()) {
            Log.d("QUESTLOGTEST", "syncRemote: remoteDataList already cached in memory (" + remoteDataList.getValue().size() + " games). Skipping network refetch!");
            return;
        }
        fetchRemoteRepository();
    }

    // endregion Refresh

    // region Game list dir
    public CompletableFuture<Void> saveDirToFile(DocumentFile rootGameDir) {
        return CompletableFuture
                .supplyAsync(() -> {
                    try {
                        if (!listDirsFile.exists() || listDirsFile.length() == 0) {
                            return new HashMap<String, String>();
                        }
                        var result = (HashMap<String, String>) jsonToObject(listDirsFile, HashMap.class);
                        return result != null ? result : new HashMap<String, String>();
                    } catch (Exception e) {
                        return new HashMap<String, String>();
                    }
                }, singleExecutor)
                .thenApplyAsync(map -> {
                    var dirName = rootGameDir.getName();
                    if (isNotEmptyOrBlank(dirName)
                            && isWritableDir(getApplication(), rootGameDir)) {
                        var packedUri = rootGameDir.getUri().toString();
                        map.put(dirName, packedUri);
                        return map;
                    } else {
                        return null;
                    }
                }, singleExecutor)
                .thenAcceptAsync(map -> {
                    if (map == null) return;
                    try {
                        objectToJson(listDirsFile, map);
                    } catch (Exception e) {
                        throw new CompletionException(e);
                    }
                }, singleExecutor)
                .exceptionally(throwable -> {
                    Log.e("QUESTLOGTEST", "Failed to save dir to list: " + throwable.getMessage(), throwable);
                    return null;
                });
    }

    private void dropPersistable(Uri folderUri) {
        try {
            var contentResolver = getApplication().getContentResolver();
            contentResolver.releasePersistableUriPermission(
                    folderUri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                            | Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            );
        } catch (SecurityException ignored) {
        }
    }

    public void deleteGame(GameData data) {
        if (data == null || data.gameDirUri == null) return;
        var gameDir = DocumentFileCompat.fromUri(getApplication(), data.gameDirUri);
        if (gameDir == null) return;
        var nameGameDir = gameDir.getName();
        if (!isNotEmptyOrBlank(nameGameDir)) return;

        boolean isInternalDir = data.gameDirUri.toString().contains(rootInDir.getName());
        Log.i("QUESTLOGTEST", "deleteGame for: " + nameGameDir + " (isInternal=" + isInternalDir + ")");

        removeDirFromListDirsFile(listDirsFile, nameGameDir)
                .thenRunAsync(() -> {
                    if (isInternalDir) {
                        Log.d("QUESTLOGTEST", "Deleting internal game folder: " + nameGameDir);
                        forceDelFile(getApplication(), gameDir);
                    } else {
                        Log.i("QUESTLOGTEST", "External folder '" + nameGameDir + "' removed from library list (files left intact on storage)");
                    }
                }, executor)
                .thenRunAsync(() -> dropPersistable(data.gameDirUri), executor)
                .thenRun(this::refreshGameData)
                .exceptionally(ex -> {
                    Log.e("QUESTLOGTEST", "Error deleting game: ", ex);
                    return null;
                });
    }

    private CompletableFuture<Void> removeDirFromListDirsFile(File listDirsFile, String folderName) {
        return CompletableFuture
                .supplyAsync(() -> {
                    try {
                        var map = (HashMap<String, String>) jsonToObject(listDirsFile, HashMap.class);
                        return map != null ? map : new HashMap<String, String>();
                    } catch (Exception e) {
                        throw new CompletionException(e);
                    }
                }, executor)
                .thenAcceptAsync(mapFiles -> {
                    if (!mapFiles.isEmpty()) {
                        mapFiles
                                .entrySet()
                                .removeIf(stringStringEntry -> stringStringEntry.getKey().equalsIgnoreCase(folderName));
                        try {
                            objectToJson(listDirsFile, mapFiles);
                        } catch (Exception e) {
                            throw new CompletionException(e);
                        }
                    }
                }, executor)
                .thenRunAsync(() -> {
                    var newList = extGamesListDir;
                    if (newList == null || newList.isEmpty()) return;

                    newList.removeIf(file -> {
                        var dirName = file.getName();
                        if (!isNotEmptyOrBlank(dirName)) return false;
                        return dirName.equalsIgnoreCase(folderName);
                    });

                    extGamesListDir = newList;

                    runOnUiThread(this::refreshGameData);
                })
                .exceptionally(throwable -> {
                    Log.e("QUESTLOGTEST", "removeDirFromListDirsFile error: ", throwable);
                    return null;
                });
    }

    // endregion Game list dir

    public void startFileDownload(GameData gameData) {
        CompletableFuture
                .supplyAsync(() -> {
                    try {
                        var convUrl = new URL(gameData.fileUrl);

                        var cookie = android.webkit.CookieManager.getInstance().getCookie(gameData.fileUrl);
                        var con = (HttpURLConnection) convUrl.openConnection();
                        con.setRequestProperty("Cookie", cookie);
                        con.setRequestMethod("HEAD");
                        con.setInstanceFollowRedirects(false);
                        con.connect();

                        var content = con.getHeaderField("Content-Disposition");
                        var contentSplit = content.split("filename=");
                        return contentSplit[1].replace("filename=", "").replace("\"", "").trim();
                    } catch (IOException exception) {
                        Log.e("QUESTLOGTEST", "startFileDownload HEAD request failed: ", exception);
                        return "";
                    }
                })
                .thenAccept(s -> {
                    if (s.isEmpty() || s.isBlank()) return;

                    Environment
                            .getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                            .mkdirs();

                    var downloadUri = Uri.parse(gameData.fileUrl);
                    var request = new DownloadManager.Request(downloadUri)
                            .setVisibleInDownloadsUi(true)
                            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                            .setDestinationInExternalFilesDir(getApplication(), Environment.DIRECTORY_DOWNLOADS, s);
                    downloadId = downloadManager.enqueue(request);
                })
                .exceptionally(throwable -> {
                    Log.e("QUESTLOGTEST", "startFileDownload error: ", throwable);
                    return null;
                });
    }

    public void postProcessingDownload() {
        if (downloadId == 0) return;
        var query = new DownloadManager.Query()
                .setFilterById(downloadId);
        try (var c = downloadManager.query(query)) {
            if (c.moveToFirst()) {
                var colStatusIndex = c.getColumnIndex(DownloadManager.COLUMN_STATUS);
                if (DownloadManager.STATUS_SUCCESSFUL == c.getInt(colStatusIndex)) {
                    var colUriIndex = c.getColumnIndex(DownloadManager.COLUMN_LOCAL_URI);
                    if (colUriIndex == -1) return;
                    var path = c.getString(colUriIndex).replace("file:///", "");
                    var file = DocumentFileCompat.fromUri(getApplication(), Uri.parse(c.getString(colUriIndex)));
                    if (file == null || !isWritableFile(getApplication(), file)) return;

                    var archive = new File(path);
                    var archiveUnpack = new ArchiveUnpack(
                            getApplication(),
                            archive,
                            rootInDir
                    );

                    CompletableFuture
                            .runAsync(archiveUnpack::extractArchiveEntries, executor)
                            .thenRun(() -> {
                                archive.delete();

                                var gameFolder = archiveUnpack.unpackFolder;
                                localGame.searchAndWriteData(gameFolder, currGameData);
                            })
                            .thenRun(() -> {
                                var notificationBuild = new NotifyBuilder(getApplication(), UNPACK_GAME_CHANNEL_ID);
                                var unpackBody = ActivityCompat.getString(getApplication(), R.string.bodyUnpackDoneNotify);
                                var notification = notificationBuild.buildStandardNotification(
                                        ActivityCompat.getString(getApplication(), R.string.titleUnpackDoneNotify),
                                        unpackBody.replace("-GAMENAME-", currGameData.title)
                                );
                                var notificationManager = getApplication().getSystemService(NotificationManager.class);
                                notificationManager.notify(UNPACK_GAME_NOTIFICATION_ID, notification);
                            })
                            .exceptionally(throwable -> {
                                Log.e("QUESTLOGTEST", "postProcessingDownload extract error: ", throwable);
                                return null;
                            });
                }
            }
        }
    }

}
