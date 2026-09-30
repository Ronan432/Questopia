package com.libqsp.jni;

public abstract class QSPLib {
    public enum Error {
        DIVBYZERO,
        TYPEMISMATCH,
        STACKOVERFLOW,
        TOOMANYITEMS,
        CANTLOADFILE,
        GAMENOTLOADED,
        COLONNOTFOUND,
        CANTINCFILE,
        CANTADDACTION,
        EQNOTFOUND,
        LOCNOTFOUND,
        ENDNOTFOUND,
        LABELNOTFOUND,
        INCORRECTNAME,
        QUOTNOTFOUND,
        BRACKNOTFOUND,
        BRACKSNOTFOUND,
        SYNTAX,
        UNKNOWNACTION,
        ARGSCOUNT,
        CANTADDOBJECT,
        CANTADDMENUITEM,
        TOOMANYVARS,
        INCORRECTREGEXP,
        CODENOTFOUND,
        LOOPWHILENOTFOUND
    }

    public enum Window {
        ACTS,
        OBJS,
        VARS,
        INPUT
    }

    public record ListItem(String image, String name) { }

    public static class ExecutionState {
        public String loc;
        public int actIndex;
        public int lineNum;
    }

    public static class ErrorInfo {
        public int errorNum;
        public String errorDesc;
        public String locName;
        public int actIndex;
        public int topLineNum;
        public int intLineNum;
        public String intLine;
    }

    static {
        boolean loaded = false;
        try {
            System.loadLibrary("qsp");
            loaded = true;
        } catch (Throwable ignored) {}

        if (!loaded) {
            try {
                java.io.File localDll = new java.io.File("libs/native/windows-x64/qsp.dll");
                if (localDll.exists()) {
                    System.load(localDll.getAbsolutePath());
                    loaded = true;
                }
            } catch (Throwable ignored) {}
        }

        if (!loaded) {
            try {
                java.io.InputStream in = QSPLib.class.getResourceAsStream("/win32-x86-64/qsp.dll");
                if (in == null) in = QSPLib.class.getResourceAsStream("/qsp.dll");
                if (in != null) {
                    java.io.File tempDll = java.io.File.createTempFile("qsp_", ".dll");
                    tempDll.deleteOnExit();
                    java.nio.file.Files.copy(in, tempDll.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                    System.load(tempDll.getAbsolutePath());
                    loaded = true;
                }
            } catch (Throwable e) {
                System.err.println("Failed to load QSP native library: " + e.getMessage());
            }
        }
    }

    // Main API
    public native void init();
    public native void terminate();

    public native void enableDebugMode(boolean isDebug);
    public native ExecutionState getCurrentState();
    public native String getVersion();
    public native String getCompiledDateTime();
    public native int getFullRefreshCount();
    public native String getMainDesc();
    public native boolean isMainDescChanged();
    public native String getVarsDesc();
    public native boolean isVarsDescChanged();
    public native void setInputStrText(String value);
    public native ListItem[] getActions();
    public native boolean setSelActIndex(int index, boolean toRefreshUI);
    public native boolean execSelAction(boolean toRefreshUI);
    public native int getSelActIndex();
    public native boolean isActsChanged();
    public native ListItem[] getObjects();
    public native boolean setSelObjIndex(int index, boolean toRefreshUI);
    public native int getSelObjIndex();
    public native boolean isObjsChanged();
    public native void showWindow(int type, boolean toShow);
    public native int getVarValuesCount(String name);
    public native int getVarIndexByString(String name, String str);
    public native long getNumVarValue(String name, int index);
    public native String getStrVarValue(String name, int index);
    public native boolean execString(String code, boolean toRefreshUI);
    public native String calculateStrExpr(String expression, boolean toRefreshUI);
    public native long calculateNumExpr(String expression, boolean toRefreshUI);
    public native boolean execLocationCode(String name, boolean toRefreshUI);
    public native boolean execCounter(boolean toRefreshUI);
    public native boolean execUserInput(boolean toRefreshUI);
    public native ErrorInfo getLastErrorData();
    public native String getErrorDesc(int errorNum);
    public native boolean loadGameWorldFromData(byte[] data, boolean isNewGame);
    public native byte[] saveGameAsData(boolean toRefreshUI);
    public native boolean openSavedGameFromData(byte[] data, boolean toRefreshUI);
    public native boolean restartGame(boolean toRefreshUI);

    // Callbacks
    public void onDebug(String str) {}
    public boolean onIsPlayingFile(String file) { return false; }
    public void onPlayFile(String file, int volume) {}
    public void onCloseFile(String file) {}
    public void onShowImage(String file) {}
    public void onShowWindow(int type, boolean toShow) {}
    public int onShowMenu(ListItem[] items) { return -1; }
    public void onShowMessage(String text) {}
    public void onRefreshInt(boolean isForced) {}
    public void onSetTimer(int msecs) {}
    public void onSetInputStrText(String text) {}
    public void onSystem(String cmd) {}
    public void onOpenGame(String file, boolean isNewGame) {}
    public void onOpenGameStatus(String file) {}
    public void onSaveGameStatus(String file) {}
    public void onSleep(int msecs) {}
    public int onGetMsCount() { return 0; }
    public String onInputBox(String text) { return ""; }
    public String onVersion(String param) { return ""; }
}
