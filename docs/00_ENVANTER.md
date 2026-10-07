# FAZ 0 — DETAYLI KEŞİF VE ENVANTER RAPORU (Questopia -> Flutter)

**Tarih**: 2026-03-31  
**Proje**: Questopia-RE (QSP Interactive Fiction Game Engine & Player)  
**Mevcut Yığın**: Android (`:app`), Desktop Compose Multiplatform (`:desktop`), C Native QSP 5.8.0 Engine (`CMake`), Rust Native Companion (`native-rust`)

---

## 0.1 Modül Haritası ve Mimari Yapı

Questopia projesi modüler, yüksek performanslı ve çok platformlu bir yapıya sahiptir.

### Modül Envanteri ve Sorumluluk Tablosu
1. **`:app` (Android Uygulama Modülü)**:
   * **Konum**: `app/src/main/`
   * **Teknoloji**: Kotlin & Java 21, Android SDK 35 (minSdk 26, targetSdk 34), Jetpack Compose (Material 3 Expressive), NDK / CMake (C QSP 5.8.0 core).
   * **Bileşenler**:
     * `ui/game`: `GameActivity.kt`, `GameViewModel.java`, `GameDialogs.kt`, `InGameOptionsMenuSheet.kt`, `SaveSlotsSheet.kt`, `CheatModesSheet.kt`, `GameWebViewComponents.kt`, `GameMediaHelpers.kt`.
     * `ui/stock`: `StockActivity.kt`, `StockViewModel.java`, `StockScreens.kt`, `StockNavigation.kt`, `GameComponents.kt`.
     * `ui/settings`: `SettingsActivity.kt`, `SettingsMainScreen.kt`, `SettingsController.java`, `SettingsComponents.kt`.
     * `model/lib`: `LibProxyImpl.java` (QSP JNI soyutlaması), `LibGameState.java`.
     * `model/service`: `HtmlProcessor.java`, `AudioPlayer.java`, `ImageProvider.java`.
     * `helpers/native_core`: `RustEngineCore.kt` (JNI Rust köprüsü).
     * `helpers/utils`: `MediaUtil.java`, `FileUtil.java`, `DirUtil.java`, `JsonUtil.kt`, `XmlUtil.kt`, `LocaleHelper.kt`.
   * **Kodu İnceleme Derinliği**: ~42 Kotlin/Java dosyası, ~12,800 satır.

2. **`:desktop` (Masaüstü Compose Multiplatform Modülü)**:
   * **Konum**: `desktop/src/main/`
   * **Teknoloji**: Kotlin 2.0.21, Compose Multiplatform 1.7.0, Windows x64 DLL (`qsp.dll`, `questopia_rust.dll`).
   * **Bileşenler**: `org.qp.desktop.Main.kt`, `AppLogo.kt`.

3. **`:app/src/main/cpp` (C QSP 5.8.0 Native Engine)**:
   * **Konum**: `app/src/main/cpp/qsp/`
   * **Teknoloji**: C11, Oniguruma Regex Kütüphanesi, CMake.
   * **Bileşenler**:
     * `qsp/bindings/java`: `java_callbacks.c`, `java_control.c`, `com_libqsp_jni_QSPLib.h` (Java Native Interface sarmalayıcısı).
     * `qsp/*.c`: `statements.c`, `variables.c`, `mathops.c`, `locations.c`, `actions.c`, `objects.c`, `game.c`, `codetools.c`.
   * **Dosya / Satır**: 38 C kaynak/başlık dosyası, ~16,200 satır C.

4. **`native-rust` (Rust Companion Native Library)**:
   * **Teknoloji**: Rust 2021 Edition, `jni`, `zip`, `flate2`, `serde`, `encoding_rs`, `quick-xml`.
   * **Bileşenler**:
     * `parseHtml`: SIMD hızlandırmalı HTML temizleyici.
     * `parseRepositoryXml`: `quick-xml` tabanlı hızlı XML ayrıştırıcı.
     * `convertEncoding`: Windows-1251, KOI8-R, UTF-8 ve CP866 metin kodlama dönüştürücü.
     * `extractArchive`: Zip Slip saldırılarına karşı korumalı yüksek hızlı arşiv çıkarıcı.

---

## 0.2 Bağımlılık Envanteri ve Flutter Eşleme Kararları

| Mevcut Kütüphane (`libs.versions.toml`) | Sürüm | Sorumluluk | Flutter Karşılığı | Seçim Nedeni / Durum |
| :--- | :--- | :--- | :--- | :--- |
| `androidx.compose.material3` | BOM 2024.10.01 | M3 Expressive Arayüz | `flutter/material.dart` | Yerleşik Material 3 Desteği |
| `io.coil-kt:coil-compose` | 2.7.0 | Resim önbellekleme | `cached_network_image` | Bellek ve disk önbellek yönetimi |
| `com.anggrayudi:storage` | 1.5.6 | SAF / DocumentFile erişimi | `file_picker` / `saf` | SAF ve yerel dosya sistemine erişim |
| `io.ktor:ktor-client-core / okhttp` | 2.3.12 | Uzak depo senkronizasyonu | `dio` | Interceptor, retry ve timeout desteği |
| `com.russhwolf:multiplatform-settings` | 1.2.0 | Key-value ayarlar | `shared_preferences` | Reaktif tercih depolama |
| `org.jsoup:jsoup` | 1.18.3 | HTML DOM işleme | `html` / `universal_html` | DOM ayrıştırma ve etiket manipülasyonu |
| `org.jetbrains.kotlinx:kotlinx-serialization-json` | 1.7.3 | JSON serileştirme | `json_serializable` + `freezed` | Tip güvenli JSON ayrıştırma |
| `C-based QSP 5.8.0 Engine (NDK)` | 5.8.0 | Oyun motoru çekirdeği | `dart:ffi` | C FFI ile sıfır gecikmeli native motor çağrısı |
| `Rust Engine Companion` | - | Arşiv çıkarma, ses, HTML | `dart:ffi` / `flutter_rust_bridge` | Rust kütüphanesine doğrudan FFI erişimi |

---

## 0.3 Arayüz, Ekran ve Navigasyon Haritası

### 1. `StockActivity` / `StockScreens.kt` (Kütüphane & Oyun Deposu)
* **ViewModel**: `StockViewModel.java` (~975 satır).
* **Alt Ekranlar / Sekmeler**:
  * **Yerel Oyunlar (Local Library)**: Kullanıcının cihazındaki veya SAF klasöründeki oyun kartları grid/list görünümü. Favorilere ekleme, silme, oyun klasör boyutu hesaplama.
  * **Uzak Depo (Remote Catalog)**: Web sunucusundan Ktor ile çekilen oyun listesi, arama çubuğu (`ExpressiveSearchBar`), indirme durumu, otomatik ZIP açma (`ArchiveUnpack.kt`).
  * **Oyun Detay Modalı**: Oyun görseli, açıklama, yazar, sürüm, oynama butonu.

### 2. `GameActivity` / `GameMainCompose` (Oyun İçi Ekranı)
* **ViewModel**: `GameViewModel.java` (~885 satır).
* **Bileşenler**:
  * **`GameHtmlWebView`**: HTML5 & OGV.js WASM video oynatıcı entegrasyonu. WebView yakınlaştırma durumunu korur (`webView.tag = htmlContent`).
  * **`GameDialogsHost`**: QSP motorundan gelen 8 standart dialog:
    1. *User Input* (`onInputBox`): Kullanıcı metin girdisi.
    2. *Executor* (`execString`): Doğrudan QSP kodu çalıştırma.
    3. *Message* (`onShowMessage`): Motor mesaj penceresi.
    4. *Selection Menu* (`onShowMenu`): Seçenekler menüsü.
    5. *Enhanced Error Diagnostics*: Kod satır numarası ve lokasyon hata ayrıntıları.
    6. *Fullscreen Image Preview*: Tam ekran resim görüntüleyici.
    7. *Close Confirmation*: Oyundan çıkış onay dialogu.
    8. *External File Load*: Harici dosya yükleme.
  * **`InGameOptionsMenuSheet`**: 3 noktalı seçenekler çekmecesi (Yeniden başlat, Kaydet/Yükle, Hile Modu, Ayarlar).
  * **`SaveSlotsSheet`**: 10 sayfada 60 manuel kayıt slotu + Otomatik Kayıt (Auto-Save) kartı + Harici kayıt dosyası içe/dışa aktarma.
  * **`CheatModesSheet` (QSPSaveEditor & Hile Menüsü)**:
    1. *VariablesTab*: Tüm QSP değişkenlerini filtreleme (Sayı, Metin, Dizi), canlı değer değiştirme.
    2. *LocksTab*: Değişken dondurma (Freeze Monitor) - değişken değerlerini sabitleme.
    3. *TeleportTab*: Lokasyon seçici ile anında lokasyon değiştirme (`execLocationCode`).
    4. *InventoryTab*: Envanterdeki eşyaları silme/düzenleme (`getObjects`).
    5. *ConsoleTab*: Doğrudan QSP kod çalıştırma konsolu.
    6. *DiffTab*: Anlık görüntü karşılaştırma (Snapshot Diff).
    * **Rollback Güvenliği**: Çekmece açıldığında `initialSnapshot` alınır, iptal edildiğinde kayıt otomatik geri yüklenir.

### 3. `SettingsActivity` / `SettingsMainScreen.kt` (Ayarlar)
* **Controller**: `SettingsController.java` (~143 satır).
* **Ayar Grupları**:
  * Görünüm: Tema (Sistem, Açık, Koyu, AMOLED), Dinamik Renkler (Material You), Font Boyutu, Font Ailesi.
  * Oyun Motoru: Ses yüksekliği, Dili değiştirme, WebView yakınlaştırma kontrolü, Tam ekran resimler.
  * Dizinler: Oyun depolama dizini seçimi.

---

## 0.4 QSP Motoru ve Yerel Çağrı (Native Interop) Detayları

### 1. C QSP Core (`com.libqsp.jni.QSPLib`)
Dart FFI tarafında sarmalanacak temel native fonksiyonlar:
```c
// Temel Motor Döngüsü
void QSPInit();
void QSPDeInit();
qsp_bool QSPLoadGameWorldFromData(void *data, int dataSize, qsp_bool isNewGame);
qsp_bool QSPExecString(unsigned short *str, qsp_bool isRefresh);
qsp_bool QSPExecLocationCode(unsigned short *name, qsp_bool isRefresh);

// Değişken ve Durum Erişimi
int QSPGetVarNumValue(unsigned short *name, int index, int *numVal);
unsigned short *QSPGetVarStrValue(unsigned short *name, int index);
void QSPSetVarValue(unsigned short *name, int index, QSPVariant *val);

// Callbacks (Dart NativeCallable / FFI Port)
typedef void (*QSP_CALLBACK_SHOWMSG)(unsigned short *msg);
typedef void (*QSP_CALLBACK_SHOWIMAGE)(unsigned short *file);
typedef void (*QSP_CALLBACK_PLAYFILE)(unsigned short *file, int volume);
```

### 2. Multi-Line `exec:` İşleme Mantığı (`HtmlProcessor.java`)
QSP oyunları HTML bağlantılarında çok satırlı kodlar içerir:
1. `HtmlProcessor.java` `EXEC_PATTERN` regex'i ile `exec:` bağlantılarını yakalar.
2. Çok satırlı kod içerikleri Base64 formatına dönüştürülür (`href="exec:base64:..."`).
3. WebView tıklamayı yakaladığında Base64 çözülür, `<br>` ve `<p>` etiketleri `\n` ile değiştirilir ve `QSPLib.execString(...)` fonksiyonuna iletilir.

### 3. OGV.js WASM Video Oynatıcı Entegrasyonu
* OGV/OGG formatındaki videolar Android WebView tarafından varsayılan olarak desteklenmez.
* `HtmlProcessor.java` `.ogv` uzantılı görselleri `<video>` etiketlerine dönüştürür.
* HTML başlığına `ogv/ogv.js` kütüphanesi enjekte edilir.
* `GameViewModel.java` `https://questopia.local/` tabanlı medya isteklerini durdurarak yerel oyuna ait OGV dosyalarını akış olarak WebView'e iletir.

---

## 0.5 Veri Katmanı ve Depolama Stratejisi

* **Uzak Depo**: Ktor Client (`RemoteGameRepository.kt`) aracılığıyla JSON formatındaki oyun listesi çekilir.
* **Arşiv Çıkarıcı**: `ArchiveUnpack.kt` / `RustEngineCore` ile Zip Slip zafiyeti önlenerek ZIP arşivleri `games-dir` dizinine çıkarılır.
* **Tercihler**: `SharedPreferences` / Flutter `shared_preferences` ile tema, font ve ses ayarları saklanır.

---

## 0.6 Risk Analizi ve Kritik Uyarılar

1. **C QSP Unicode UTF-16 Dönüşümü (Yüksek Risk - M)**:
   * QSP C motoru dize işlemleri için `unsigned short*` (UTF-16) kullanır. Dart FFI `Pointer<Utf16>` dönüşümleri eksiksiz yapılmalıdır.
2. **OGV.js WASM ve Local Server Proxying (Orta Risk - M)**:
   * CORS ve WebView yerel dosya erişim kısıtlamaları için Flutter tarafında `shelf` yerel sunucusu veya `InAppWebView` custom scheme handler kullanılmalıdır.
3. **Masaüstü (Windows x64) Desteği (Orta Risk - M)**:
   * DLL yükleme yolları ve `dart:ffi` bellek yönetimi.

---

## 0.7 Mimar Soruları ve Karar Onayları

Lütfen aşağıdaki 6 mimari soruyu yanıtlayarak onayınızı iletiniz:

1. **Durum Yönetimi Tercihi**: `Riverpod` (Önerilen) mi yoksa `Bloc` / `Cubit` mi?
2. **Yerel Veritabanı / Önbellek Tercihi**: `Drift` (Önerilen) mi yoksa `Isar` / `sqflite` mi?
3. **Navigasyon Tercihi**: `go_router` (Önerilen) mi yoksa `auto_route` mu?
4. **DI (Bağımlılık Enjeksiyonu) Tercihi**: `Riverpod` dâhili sağlayıcıları mı yoksa `get_it` + `injectable` mı?
5. **Hedef Platform Listesi & Min OS**: Android (Min SDK 26), iOS (Min iOS 14) ve Windows x64 hedeflerinin tamamı dahil mi?
6. **Mevcut Kullanıcı Verisinin Taşınması (Faz 8)**: Eski Android SharedPreferences / Oyun kayıtlarının otomatik aktarımı gerekli mi?
