package org.qp.android.dto.stock;

import androidx.annotation.NonNull;

public class RemoteGameData {

    public long id = 0L;
    public int listId = 0;
    public String author = "";
    public String portedBy = "";
    public String version = "";
    public String title = "";
    public String lang = "";
    public String player = "";
    public String icon = "";
    public String image = "";
    public String fileUrl = "";
    public long fileSize = 0L;
    public String fileExt = "";
    public String descUrl = "";
    public String pubDate = "";
    public String modDate = "";

    public RemoteGameData() {}

    @NonNull
    @Override
    public String toString() {
        return "RemoteGameData{" +
                "id='" + id + '\'' +
                ", listId='" + listId + '\'' +
                ", author='" + author + '\'' +
                ", portedBy='" + portedBy + '\'' +
                ", version='" + version + '\'' +
                ", title='" + title + '\'' +
                ", lang='" + lang + '\'' +
                ", player='" + player + '\'' +
                ", fileUrl='" + fileUrl + '\'' +
                ", fileSize='" + fileSize + '\'' +
                ", fileExt='" + fileExt + '\'' +
                ", descUrl='" + descUrl + '\'' +
                ", pubDate='" + pubDate + '\'' +
                ", modDate='" + modDate + '\'' +
                '}';
    }
}
