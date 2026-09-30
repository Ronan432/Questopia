package org.qp.android.dto.stock;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class RemoteDataList {

    public String version = "";
    public String id = "";
    public String title = "";
    public String text = "";

    public List<RemoteGameData> game = new ArrayList<>();

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        var that = (RemoteDataList) o;
        return Objects.equals(game, that.game);
    }

    @Override
    public int hashCode() {
        return Objects.hash(game);
    }
}
