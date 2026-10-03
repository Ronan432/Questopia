# Questopia-RE Dosya Haritası (Filemap)

Bu belge, Questopia-RE projesindeki tüm modülleri, kaynak kodlarını, yerel C/Rust/JNI katmanlarını ve kaynak dizinlerini ayrıntılı olarak haritalandırır.

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
├── build.py                      # Otomatik derleme & Çok kanallı Kablosuz ADB Port Tarayıcı Python aracı
├── build.gradle                  # Kök Gradle yapılandırması
├── settings.gradle               # Modül ve repo ayarları (:app, :desktop)
├── gradle.properties             # JVM parametreleri ve AndroidX özellikleri
├── filemap.md                    # Proje dosya haritası (bu dosya)
├── AGENTS.md                     # Agent geliştirme yönergeleri ve mimari kuralları
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
| `model/lib/LibProxyImpl.java` | `LibIProxy` uygulayıcısı; `QSPLib` JNI çağrılarını yönetir, callback'leri işler, arka plan iş parçacığıyla senkronize eder. Dosya yollarındaki ters bölü (`\`) karakterlerini otomatik normalize eder. |
| `model/service/AudioPlayer.java` | QSP ses ve müzik komutlarını yürüten servis. |
| `model/service/HtmlProcessor.java` | QSP metinlerindeki HTML/CSS etiketlerini, çok satırlı `exec:` komutlarını ve resim yollarını ayrıştıran (`Jsoup`) servis. |
| `model/service/ImageProvider.java` | QSP oyun içi grafiklerini ve görsellerini yükleyen/önbelleğe alan sağlayıcı. |
| `model/repository/LocalGame.java` | Cihazdaki yerel oyun dizinlerini tarayan, `.gameInfo` doğrulayan ve yöneten depo sınıfı. |
| `model/repository/RemoteGameRepository.kt` | Ktor Client ile uzak sunucudan oyun listesini çeken depo sınıfı. |
| `model/archive/ArchiveUnpack.kt` | Saf Kotlin/Java `java.util.zip.ZipFile` ile Zip Slip korumalı ve çoklu kodlama destekli arşiv açıcı servis. |

---

### D. Kullanıcı Arayüzü: Oyun Yönetim Ekranı (`org/qp/android/ui/stock`)
| Dosya Yolu | Sorumluluk / İşlev |
| :--- | :--- |
| `ui/stock/StockActivity.kt` | Material 3 Jetpack Compose tabanlı oyun yönetim ana penceresi (`ComponentActivity`). |
| `ui/stock/StockScreens.kt` | Stock ana koordinasyon ekranı (`StockMainScreen`), yatay kaydırmalı `HorizontalPager`, dinamik arama çubuğu ve FAB. |
| `ui/stock/StockNavigation.kt` | Alt navigasyon çubuğu ve üst sekmeler. |
| `ui/stock/GameComponents.kt` | Yüklü oyun listesi (`InstalledGamesList`), Depo listesi (`RemoteGamesList`), oyun kartları (`GameCard`) ve `CustomDrawerHandle` yay animasyonlu tutamaklı basılı tutma context menüsü. |
| `ui/stock/StockViewModel.java` | Oyun yönetim iş mantığı, dosya seçici koordinasyonu, indirme ve ayıklama işlemleri. |

---

### E. Kullanıcı Arayüzü: Oyun Oynatma Ekranı (`org/qp/android/ui/game`)
| Dosya Yolu | Sorumluluk / İşlev |
| :--- | :--- |
| `ui/game/GameActivity.kt` | QSP oyun oynama aktivitesi; Material 3 Compose UI Scaffold, başlık çubuğu, tab gezintisi ve yaşam döngüsü yönetimi (~380 satır). |
| `ui/game/GameModels.kt` | Oyun ekranı için tüm UI veri sınıfları (`InputDialogData`, `MessageDialogData`, `MenuDialogData`, `ErrorDialogData`, `SlotInfo`). |
| `ui/game/GameDialogs.kt` | Merkezi dialog yöneticisi (`GameDialogsHost`); Input, Executor, QSP Hata Raporu, Mesaj, Seçim Menüsü, Tam Ekran Resim ve Kapatma dialogları. |
| `ui/game/InGameOptionsMenuSheet.kt` | 3 nokta seçenekler çekmecesi (`InGameOptionsMenuSheet`), Expressive menü grupları ve yeniden başlatma onay penceresi. |
| `ui/game/SaveSlotsSheet.kt` | 60 kayıt/yükleme slotu, 10 sayfalık pagination çubuğu, bağımsız Auto-save alanı ve harici dosya seçici. |
| `ui/game/CheatModesSheet.kt` | **Hile Modları & QSPSaveEditor**: 0 ms gecikmesiz anlık değişken değiştirme, dairesel kontrol butonları, `MorphingSurface` destekli lokasyon atlama (Teleport), eşya silme onay uyarısı (`AlertDialog`), dondurucu ve hile konsolu. |
| `ui/game/GameMediaHelpers.kt` | Panoya kopyalama, galeriye kaydetme, Yandex tersine görsel arama JSON API yükleyicisi ve `PosterContextMenuSheet`. |
| `ui/game/GameWebViewComponents.kt` | Pinch-to-zoom korumalı `GameHtmlWebView`, dinamik 1/2 column aksiyon gridi ve Morphing efektli `GameListItemCard`. |
| `ui/game/GameViewModel.java` | Oyun döngüsü, kullanıcı girdileri, durum güncellemeleri ve motor iletişimini yöneten ViewModel. |

---

### F. Kullanıcı Arayüzü: Ayarlar Ekranı (`org/qp/android/ui/settings`)
| Dosya Yolu | Sorumluluk / İşlev |
| :--- | :--- |
| `ui/settings/SettingsActivity.kt` | Material 3 Compose ayarlar aktivitesi. |
| `ui/settings/SettingsComponents.kt` | Expressive segmented-list bileşenleri (`ExpressiveSettingsGroup`, `ExpressivePreferenceItem`, `ExpressiveSwitchPreferenceItem`, `ExpressiveListPreferenceItem`, `ExpressiveColorPreferenceItem`, `CustomDrawerHandle` çekmece seçim diyalogları). |
| `ui/settings/SettingsMainScreen.kt` | Ayarlar ana menüsü; kayan arama çubuğu, zorunlu sınır titreşimi (`NestedScrollConnection`), poster şekli seçimi ve otomatik kayıt aralığı ayarları. |
| `ui/settings/SettingsController.java` | Tercihleri yöneten ve varsayılanları sağlayan kontrolcü. |

---

### G. Tema & Ortak Bileşenler (`org/qp/android/ui/common` & `org/qp/android/ui/theme`)
| Dosya Yolu | Sorumluluk / İşlev |
| :--- | :--- |
| `ui/common/MorphingUi.kt` | **Merkezi Morph Shaping & Çekmece Tutamağı Modülü**: Yay animasyonlu morphing butonlar ve yüzeyler (`MorphingSurface`, `MorphingButton`, `getGroupedItemShape`) ve dinamik çekmece tutamağı (`CustomDrawerHandle`). |
| `ui/theme/Theme.kt` | Material 3 Dynamic Colors, Saf Siyah AMOLED desteği, Mavi tonlaması temizlenmiş nötr koyu gri Monokrom ve 8 renk ön ayarı barındıran merkezi tema motoru (`QuestopiaTheme`, `getColorScheme`). |
