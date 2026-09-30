# Questopia Dosya Haritası (Filemap)

Bu belge, Questopia projesindeki tüm modülleri, kaynak kodlarını, yerel C/Rust/JNI katmanlarını ve kaynak dizinlerini ayrıntılı olarak haritalandırır.

---

## 1. Dizin Hiyerarşisi ve Modül Yapısı

```
Questopia/
├── .github/                      # GitHub Actions iş akışları (test, build)
├── gradle/
│   ├── wrapper/                  # Gradle Wrapper dosyaları
│   └── libs.versions.toml        # Sürüm kataloğu (AGP, AndroidX, Compose, Coil, Ktor)
├── app/                          # Android Uygulama Modülü
│   ├── build.gradle              # Uygulama derleme yapılandırması (Java 21, CMake, NDK)
│   ├── proguard-rules.pro        # ProGuard / R8 optimizasyon ve saklama kuralları
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml # İzinler, aktiviteler, sağlayıcılar
│       │   ├── cpp/              # C tabanlı QSP oyun motoru ve JNI köprüsü
│       │   ├── java/             # Android Kotlin / Java uygulama kaynak kodları
│       │   └── res/              # XML kaynakları, çeviriler, temalar
│       └── test/                 # Birim testleri
├── desktop/                      # Windows Desktop (x64) Modülü
│   ├── build.gradle.kts          # Compose Desktop derleme yapılandırması
│   └── src/main/
│       ├── java/                 # JNI yerel köprü sınıfı (`QSPLib.java`)
│       ├── kotlin/               # Desktop Compose UI, Engine ve Temalar
│       └── resources/            # Gömülü qsp.dll ve uygulama simgeleri
├── native-rust/                  # Yüksek Başarımlı Rust Native Çekirdeği
│   ├── Cargo.toml                # Rust bağımlılıkları (jni, zip, flate2, serde)
│   └── src/
│       ├── lib.rs                # Android & Desktop JNI dışa aktarımları
│       ├── archive.rs            # Bellek haritalı & akışkan ZIP/QSP açıcı
│       ├── html_parser.rs        # Yüksek hızlı HTML/BBCode & span ayrıştırıcı
│       └── audio_mixer.rs        # 32-bit Float donanımsal ses karıştırıcı
├── build.gradle                  # Kök Gradle yapılandırması
├── settings.gradle               # Modül ve repo ayarları (:app, :desktop)
├── gradle.properties             # JVM parametreleri ve AndroidX özellikleri
├── GEMINI.md                     # Kapsamlı teknik mimari ve geliştirme rehberi
├── filemap.md                    # Proje dosya haritası (bu dosya)
└── README.md                     # Proje tanıtım belgesi
```

---

## 2. Android Kaynak Kodları Haritası (`app/src/main/java`)

### A. Uygulama & JNI Giriş Noktası
| Dosya Yolu | Sorumluluk / İşlev |
| :--- | :--- |
| `org/qp/android/QuestopiaApplication.java` | Uygulama sınıfı (`Application`), bildirim kanallarını oluşturur, Coil `ImageLoaderFactory` ve Singleton servisleri (`ImageProvider`, `HtmlProcessor`, `AudioPlayer`, `LibProxyImpl`) barındırır. |
| `com/libqsp/jni/QSPLib.java` | QSP C kütüphanesi için yerel JNI arayüz sınıfı (`native` metotlar: başlatma, kaydetme, yükleme, komut çalıştırma). |
| `helpers/native_core/RustEngineCore.kt` | Yüksek hızlı Rust native çekirdeğini yükleyen ve hata durumunda Java/Kotlin'e otomatik devreden güvenli köprü sınıfı. |

---

### B. Veri Modelleri & DTO (`org/qp/android/dto`)
| Dosya Yolu | Sorumluluk / İşlev |
| :--- | :--- |
| `dto/stock/GameData.java` | Yerel QSP oyununa ait meta verileri tutan veri sınıfı (başlık, yazar, sürüm, dosya yolu, boyut, simge). |
| `dto/stock/RemoteGameData.java` | Uzak depodan (QSP repository) çekilen oyun meta veri modeli. |
| `dto/stock/RemoteDataList.java` | Uzak oyun listesi veri modeli. |

---

### C. İş Mantığı, Servisler ve Motor Katmanı (`org/qp/android/model`)
| Dosya Yolu | Sorumluluk / İşlev |
| :--- | :--- |
| `model/lib/LibGameState.java` | QSP motor durumunu temsil eden model (konum, metin, eylemler, değişkenler). |
| `model/lib/LibIConfig.java` | QSP motor yapılandırma arayüzü. |
| `model/lib/LibIProxy.java` | QSP motoru ile Android katmanı arasındaki arayüz sözleşmesi. |
| `model/lib/LibProxyImpl.java` | `LibIProxy` uygulayıcısı; `QSPLib` JNI çağrılarını yönetir, callback'leri işler, arka plan iş parçacığıyla senkronize eder. |
| `model/lib/LibRefIRequest.java` | Motor isteklerini yönlendiren referans arayüzü. |
| `model/lib/LibWindowType.java` | QSP pencere tipleri enum'u (Ana pencere, Eylemler, Nesneler, Değişkenler). |
| `model/service/AudioPlayer.java` | QSP ses ve müzik komutlarını (Play/Stop/Pause/Volume) `MediaPlayer`/`SoundPool` ile yürüten servis. |
| `model/service/HtmlProcessor.java` | QSP metinlerindeki HTML/CSS etiketlerini ve resim yollarını ayrıştıran (`Jsoup`) ve biçimlendiren servis. |
| `model/service/ImageProvider.java` | QSP oyun içi grafiklerini ve görsellerini yükleyen/önbelleğe alan sağlayıcı. |
| `model/repository/LocalGame.java` | Cihazdaki yerel oyun dizinlerini tarayan, `.gameInfo` doğrulayan ve yöneten depo sınıfı. |
| `model/repository/RemoteGameRepository.kt` | Ktor Client ile uzak sunucudan oyun listesini çeken depo sınıfı. |
| `model/archive/ArchiveUnpack.kt` | Saf Kotlin/Java `java.util.zip.ZipFile` ile Zip Slip korumalı ve çoklu kodlama destekli arşiv açıcı servis. |
| `model/notify/NotifyBuilder.java` | Bildirim çubuğu bildirimleri oluşturan yardımcı sınıf. |

---

### D. Kullanıcı Arayüzü: Oyun Yönetim Ekranı (`org/qp/android/ui/stock`)
| Dosya Yolu | Sorumluluk / İşlev |
| :--- | :--- |
| `ui/stock/StockActivity.kt` | Material 3 Jetpack Compose tabanlı oyun yönetim ana penceresi (`ComponentActivity`); gezinme çubuğu, arama çubuğu ve `LibPickYou` dosya seçici entegrasyonu. |
| `ui/stock/StockScreens.kt` | Stock ana koordinasyon ekranı (`StockMainScreen`), yatay kaydırmalı `HorizontalPager`, dinamik arama çubuğu ve FAB. |
| `ui/stock/StockNavigation.kt` | Alt navigasyon çubuğu (`FlexibleNavigationBar`, `FlexibleNavItem`) ve üst sekmeler (`StockSegmentedControl`). |
| `ui/stock/GameComponents.kt` | Yüklü oyun listesi (`InstalledGamesList`), Depo listesi (`RemoteGamesList`), oyun kartları (`GameCard`, `RemoteGameCard`) ve diyaloglar. |
| `ui/stock/StockViewModel.java` | Oyun yönetim iş mantığı, dosya seçici koordinasyonu, indirme, XML ayrıştırma ve ayıklama işlemleri. |

---

### E. Kullanıcı Arayüzü: Oyun Oynatma Ekranı (`org/qp/android/ui/game`)
| Dosya Yolu | Sorumluluk / İşlev |
| :--- | :--- |
| `ui/game/GameActivity.kt` | QSP oyununun oynandığı ana aktivite; Material 3 Compose UI + WebView, derin karanlık menüler (`ModalBottomSheet`), kayıt/yükleme slotları (`SaveSlotsSheet`), Hile Modları entegrasyonu ve klavye/durum kontrolleri. |
| `ui/game/CheatModesSheet.kt` | **Hile Modları & QSPSaveEditor**: Canlı değişken arama/düzenleme, değişken dondurucu (freeze), sahne atlama (location warper), eşya yöneticisi (spawner), hile konsolu, save diff ve %100 geri alma (rollback) güvenceli modal. |
| `ui/game/GameViewModel.java` | Oyun döngüsü, kullanıcı girdileri, durum güncellemeleri, değişken/lokasyon köprüleri ve motor iletişimini yöneten ViewModel. |
| `ui/game/GameInterface.java` | ViewModel ile Activity arasındaki haberleşme arayüzü. |
| `ui/game/GameLibRequest.java` | Motor isteklerini sarmalayan veri nesnesi. |

---

### F. Kullanıcı Arayüzü: Ayarlar Ekranı (`org/qp/android/ui/settings`)
| Dosya Yolu | Sorumluluk / İşlev |
| :--- | :--- |
| `ui/settings/SettingsActivity.kt` | Material 3 Compose ayarlar aktivitesi (`ComponentActivity`) ve gezinme yönlendiricisi (`SettingsApp`). |
| `ui/settings/SettingsComponents.kt` | Expressive segmented-list bileşenleri (`ExpressiveSettingsGroup`, `ExpressivePreferenceItem`, `ExpressiveSwitchPreferenceItem`, `ExpressiveListPreferenceItem`, `ExpressiveColorPreferenceItem`, koyu seçim diyalogları, `AboutDialog`, `VersionDialog`). |
| `ui/settings/SettingsMainScreen.kt` | Ayarlar ana menüsü; dinamik olarak kayan arama çubuğu, temiz gruplanmış kartlar ve diyaloglar. |
| `ui/settings/SettingsViewModel.java` | Ayarlar ekranı durum yöneticisi. |
| `ui/settings/SettingsController.java` | SharedPreferences verilerini tip güvenli okuyan/yazan kontrolcü. |
| `ui/settings/SettingsApp.kt` | Ayar verileri ve temalar için data modelleri. |

---

### G. Tema & Ortak Bileşenler (`org/qp/android/ui/common` & `org/qp/android/ui/theme`)
| Dosya Yolu | Sorumluluk / İşlev |
| :--- | :--- |
| `ui/common/MorphingUi.kt` | Yaylanma taşmalarına karşı sıfır Dp (`.coerceAtLeast(0.dp)`) korumalı yay animasyonlu morphing butonlar ve yüzeyler (`MorphingSurface`, `MorphingButton`, `getGroupedItemShape`). |
| `ui/theme/Theme.kt` | Material 3 Dynamic Colors, Saf Siyah AMOLED desteği, Monokrom ve 8 renk ön ayarı barındıran merkezi tema motoru (`QuestopiaTheme`, `getColorScheme`). |

---

## 3. Desktop (Windows x64) Kaynak Kodları Haritası (`desktop/src/main`)

| Dosya Yolu | Sorumluluk / İşlev |
| :--- | :--- |
| `kotlin/org/qp/desktop/Main.kt` | Compose Desktop uygulama giriş noktası, pencere yapılandırması ve Skiko donanım hızlandırma ilklendirmesi. |
| `kotlin/org/qp/desktop/engine/DesktopQspEngine.kt` | Windows üzerinde QSP motor durumunu yöneten ve fail-safe demo oyun enjeksiyonu sağlayan motor yöneticisi. |
| `kotlin/org/qp/desktop/engine/RustEngineCore.kt` | Windows için Rust native köprü sınıfı (`questopia_rust.dll`). |
| `kotlin/org/qp/desktop/ui/DesktopNavigationRail.kt` | Genişleyip daralabilen (spring animasyonlu) sol navigasyon paneli, hızlı oyun geçişi ve son oyunlar listesi. |
| `kotlin/org/qp/desktop/ui/LibraryScreen.kt` | Masaüstü oyun kütüphanesi ve oyun başlatıcı kartları. |
| `kotlin/org/qp/desktop/ui/StockScreen.kt` | Uzak katalog tarayıcısı ve oyun indirme arayüzü. |
| `kotlin/org/qp/desktop/ui/GamePlayScreen.kt` | Masaüstü oyun oynama ekranı, metin çıktısı, eylem/envanter panelleri ve menüler. |
| `kotlin/org/qp/desktop/ui/SettingsScreen.kt` | Masaüstü ayarlar sayfası (Aydınlık, Karanlık, AMOLED ve renk paletleri). |
| `kotlin/org/qp/desktop/ui/common/MorphingUi.kt` | Masaüstü yay animasyonlu morphing kartlar ve yüzeyler. |
| `kotlin/org/qp/desktop/theme/DesktopTheme.kt` | Masaüstü Material 3 renk şemaları ve tema sağlayıcısı. |
| `java/com/libqsp/jni/QSPLib.java` | 3 aşamalı DLL arama ve gömülü classpath çıkarma mekanizmalı JNI köprüsü. |

---

## 4. Yerel Katmanlar (C/C++ & Rust)

| Dizin / Dosya | Sorumluluk / İşlev |
| :--- | :--- |
| `native-rust/src/lib.rs` | Android ve Desktop JNI dışa aktarım fonksiyonları. |
| `native-rust/src/archive.rs` | `zip-rs` + `flate2` tabanlı, Zip Slip korumalı akışkan arşiv okuyucu. |
| `native-rust/src/html_parser.rs` | Sıfır kopyalamalı yüksek hızlı HTML/BBCode temizleyici ve span üretici. |
| `native-rust/src/audio_mixer.rs` | 32-bit Float donanımsal ses karıştırıcı ve soft-clipping limiter. |
| `app/src/main/cpp/CMakeLists.txt` | NDK derleme betiği; Oniguruma regex ve QSP C motorunu statik kütüphane olarak derler. |
| `app/src/main/cpp/qsp/` | QSP C çekirdeği (`actions.c`, `game.c`, `locations.c`, `text.c` vb.). |
| `app/src/main/cpp/qsp/bindings/java/` | C JNI köprü kodları (`com_libqsp_jni_QSPLib.h`, `java_callbacks.c`, `java_control.c`). |
