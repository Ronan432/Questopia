# Questopia Flutter Geçiş Durumu

Bu belge, Flutter geçişinde bu oturumda yapılan somut değişikliklerin ve işlevsel parite için henüz tamamlanması gereken çalışmaların devir kaydıdır.

## Mevcut Sonuç

Yeni Flutter uygulaması kökteki `flutter/` dizinindedir. Eski Android/Kotlin, Desktop/KMP, C QSP ve Rust kaynakları korunmuştur. Yeni uygulama Android için başarıyla derlenmiş, bağlı cihaza yüklenmiş ve `com.questopia.re/.MainActivity` ile başlatılmıştır.

- APK: `flutter/build/app/outputs/flutter-apk/app-debug.apk`
- APK boyutu: yaklaşık 151 MB
- Android paket adı: `com.questopia.re`
- Minimum Android sürümü: API 26
- Flutter sürümü: 3.44.6
- Dart sürümü: 3.13.3
- Doğrulama: `flutter analyze` temiz tamamlandı, widget testi geçti.
- Cihaz kurulumu: `adb -s 192.168.1.161:5555 install -r -d -t ...` başarıyla tamamlandı.

Son foreground-activity sorgusu kullanıcı tarafından durduruldu. Kurulum ve uygulamayı başlatma komutu ise başarılı döndü.

## Yapılanlar

### Flutter proje altyapısı

- `flutter create` ile Android, iOS ve Windows hedefleri olan bağımsız Flutter uygulaması oluşturuldu.
- Uygulama kimliği ve Android namespace'i `com.questopia.re` olarak ayarlandı.
- Uygulama sürümü eski Android sürümüyle hizalandı: `3.25.5+202505`.
- Flutter varlıkları arasına masaüstü logo dosyası ve mevcut OGV.js/WASM dosyaları taşındı.
- İngilizce ve Rusça ARB başlangıç kaynakları eklendi.
- Flutter SDK'nin yerel kurulumunda eksik olan kök `pubspec.yaml` ve `pubspec.lock` dosyaları SDK'nin kendi Git HEAD sürümünden geri yüklendi; bu, Flutter komutlarının çalışmasını sağladı.

### Arayüz

Material 3 temelli, responsive bir ilk kullanıcı deneyimi oluşturuldu.

- Kütüphane/katalog alt gezintisi.
- Arama alanı ve ekran genişliğine göre bir, iki veya üç sütunlu oyun kartları.
- Yeni oyun ekranı: açıklama alanı, eylem düğmeleri, kullanıcı girdisi ve seçenek menüsü.
- Ayarlar alt sayfası: Sistem/Açık/Koyu tema, AMOLED seçeneği, yazı boyutu kontrolü, medya ve oyun dizini giriş noktaları.
- Kaydet/Yükle alt sayfası: otomatik kayıt kartı, 10 sayfalı 60 slot düzeninin arayüzü, içe/dışa aktarma girişleri.
- Hile modları alt sayfası: Değişkenler, Kilitler, Işınlan, Envanter, Konsol ve Fark sekmeleri.
- Eski proje kurallarına uygun olarak kullanıcı arayüzünde emoji kullanılmadı.

### Native hazırlığı

- `qsp_ffi.dart`, Android'de `libqsp.so`, Windows'ta `qsp.dll` yüklemek için güvenli bir başlangıç FFI sarmalayıcısı içerir.
- `rust_runtime.dart`, Android'de `libquestopia_rust.so`, Windows'ta `questopia_rust.dll` yüklemek için başlangıç yükleyicisi içerir.
- Windows CMake kurulumu, mevcut `libs/native/windows-x64/qsp.dll` ve `questopia_rust.dll` dosyalarını Windows Flutter paketi yanına koyacak şekilde güncellendi.
- `native-rust/` altında hiçbir Rust kaynak dosyası değiştirilmedi.

### Build akışı

- `build.py`, varsayılan Android hedefi için Flutter APK derleyecek şekilde değiştirildi.
- `build.py windows` veya `build.py desktop`, Flutter Windows uygulamasını çalıştırır.
- `build.py all`, Android APK ve Windows Flutter çıktısını üretir.
- Android APK yolu Flutter'ın çıktı yoluna güncellendi.

## Değişen Başlıca Dosyalar

| Konum | Amaç |
| --- | --- |
| `flutter/pubspec.yaml` | Flutter uygulama bilgisi ve OGV/logo varlıkları |
| `flutter/lib/main.dart` | Uygulama başlangıcı ve tema durumunun üstte tutulması |
| `flutter/lib/core/theme/questopia_theme.dart` | Material 3 açık, koyu ve AMOLED temaları |
| `flutter/lib/core/native/qsp_ffi.dart` | QSP C kitaplığı yükleyici başlangıcı |
| `flutter/lib/core/native/rust_runtime.dart` | Rust binary yükleyici başlangıcı |
| `flutter/lib/features/library/presentation/library_screen.dart` | Kütüphane ve katalog başlangıç ekranı |
| `flutter/lib/features/game/presentation/game_screen.dart` | Oyun ekranı koordinatörü |
| `flutter/lib/features/game/presentation/sheets/save_slots_sheet.dart` | Kayıt slotu arayüzü |
| `flutter/lib/features/game/presentation/sheets/cheat_modes_sheet.dart` | Hile düzenleyici arayüzü |
| `flutter/lib/features/settings/presentation/settings_sheet.dart` | Ayarlar arayüzü |
| `flutter/windows/CMakeLists.txt` | Windows native DLL paketleme |
| `build.py` | Flutter derleme, kurulum ve başlatma akışı |

## Kalan Kritik İşler

Bu geçiş henüz tam özellik paritesine ulaşmış değildir. Aşağıdaki maddeler, eski Kotlin/Java uygulamasındaki işlevleri gerçek üretim uygulamasına taşımak için gereklidir.

### 1. QSP FFI köprüsünü tamamlamak

Mevcut `QspFfi` yalnızca kitaplık yükleme, `QSPInit` ve `QSPDeInit` başlangıç çağrılarını içerir. Aşağıdakiler eklenmelidir:

- UTF-16 bellek yönetimi ile oyun yükleme, kaydetme, yeniden başlatma ve QSP kodu yürütme.
- Ana açıklama, değişken açıklaması, eylemler, nesneler, konumlar ve hata verileri için tam veri modelleri.
- QSP callback'lerini Dart isolate/port mekanizmasına güvenle köprüleyen native adapter.
- `onShowMessage`, `onShowImage`, `onPlayFile`, `onShowMenu`, `onInputBox`, zamanlayıcı, kayıt ve oyun açma callback'leri.
- Android için QSP C kaynağını Flutter'ın NDK derlemesine dahil eden CMake/Gradle katmanı ve tüm ABI'ler için `libqsp.so` üretimi.
- iOS için QSP C derleme ve framework paketleme.

Not: Mevcut QSP C API Java callback katmanı etrafında düzenlenmiştir. Dart callback'lerinin güvenli çalışması için küçük bir C ABI adapter katmanı gerekecektir. Bu adapter Rust kodunu değiştirmez.

### 2. Rust kütüphanesini üretim akışına bağlamak

Rust kaynakları korunmuştur fakat Dart çağrıları henüz uygulanmamıştır.

- Rust kitaplığının JNI-dışında çağrılabilecek stabil C ABI fonksiyonları olup olmadığı doğrulanmalıdır.
- Mevcut export'lar yalnızca JNI ise, Rust'a dokunmadan Android platform channel üzerinden mevcut JNI sınıfını çağırmak veya ayrı bir dar C adapter kullanmak gerekir.
- Android için her ABI'de `libquestopia_rust.so` paketlenmelidir.
- Windows DLL paketleme yapılandırması eklendi; Windows runtime yükleme testi yapılmalıdır.
- Arşiv açma, karakter kodlaması, HTML temizleme ve XML depo ayrıştırmasının sonuçları Dart modellerine dönüştürülmelidir.

### 3. Gerçek veri katmanı

- Riverpod veya eşdeğer bir reaktif durum yönetim katmanı eklenmelidir.
- Drift veya onaylanacak başka bir yerel veritabanı ile yerel oyun metadatası, favoriler, indirme durumları ve kayıt indeksi saklanmalıdır.
- `shared_preferences` ile tema, font, ses, yakınlaştırma ve dizin tercihleri kalıcı yapılmalıdır.
- Dio ile uzak katalog istemcisi, retry politikası, hata durumu ve JSON modelleri oluşturulmalıdır.
- ZIP indirme ve Zip Slip güvenli açma gerçek dosya sistemi üzerinde uygulanmalıdır.
- `.gameInfo` okuma/yazma ve yerel klasör boyutu hesaplama taşınmalıdır.
- Android SAF, iOS belge seçici ve Windows dosya seçici gerçek `file_picker`/platform katmanlarıyla bağlanmalıdır.

### 4. Oyun içi web ve medya

- `webview_flutter` veya `flutter_inappwebview` seçilip eklenmelidir.
- Eski `HtmlProcessor` mantığı Dart'a taşınmalıdır: çok satırlı `exec:` bağlantılarını Base64'e dönüştürme, HTML satır sonu normalizasyonu ve güvenli URL işleme.
- OGV.js/WASM varlıkları taşındı ancak henüz WebView içine servis edilmemektedir.
- `https://questopia.local/` benzeri özel şema veya yerel HTTP sunucusu ile oyun klasöründeki medya, OGV/OGG ve WASM varlıkları CORS sorunları olmadan sunulmalıdır.
- WebView yakınlaştırma ve scroll korunması, resim bağlam menüsü, galeriye kaydetme, panoya kopyalama ve Yandex ters görsel arama özellikleri tamamlanmalıdır.
- Ses oynatma ve QSP motorunun dosya oynatma callback'i bağlanmalıdır.

### 5. Ekranların işlevsel paritesi

Şu anki ekranlar tasarım ve navigasyon iskeletidir. Aşağıdaki davranışlar native/veri katmanı bağlandığında eklenmelidir:

- Yerel oyunları gerçekten tarama, ayrıntı modalı, silme, favorileme ve başlatma.
- Uzak katalog senkronizasyonu, indirme ilerlemesi, RFC 5987 `Content-Disposition` dosya adı çözümleme ve otomatik arşiv açma.
- Sekiz QSP diyaloğu: giriş, yürütücü, mesaj, seçim menüsü, hata tanılama, tam ekran görsel, çıkış onayı ve harici dosya yükleme.
- 60 kayıt slotunun gerçek save byte verisiyle çalışması ve otomatik kayıt.
- Harici `.sav` içe/dışa aktarma.
- Hile sayfasında değişken yazma, snapshot alma/geri yükleme, kilit izleme, konum ışınlama, envanter değişikliği, konsol ve fark karşılaştırması.
- Hile sayfasından geri çıkıldığında iptal için yüzde yüz rollback güvenliği.

### 6. Yerelleştirme

`app_en.arb` ve `app_ru.arb` başlangıç olarak eklendi. Ancak mevcut arayüz metinleri henüz ARB üretimli localization sınıfından okunmuyor.

- Flutter `gen-l10n` yapılandırması eklenmelidir.
- Şu an Dart dosyalarında bulunan kullanıcı metinleri ARB anahtarlarına taşınmalıdır.
- İngilizce, Rusça ve hedeflenirse Türkçe çeviriler tamamlanmalıdır.

### 7. iOS ve Windows doğrulaması

- iOS, macOS üzerinde Xcode ile derlenmelidir; bu Windows ortamında yapılamaz.
- Windows için `flutter build windows` çalıştırılmalı, `qsp.dll` ve `questopia_rust.dll` kopyalandıktan sonra native yükleme testi yapılmalıdır.
- Windows QSP/Rust DLL'lerinin mimarisi ve bağımlılıkları release paketi üzerinde doğrulanmalıdır.

### 8. Test ve yayın

- QSP FFI dönüşümleri, HTML `exec:` dönüşümü, arşiv yolu güvenliği ve repository parser için birim testleri yazılmalıdır.
- Kayıt/geri yükleme, WebView navigasyonu ve oyun callback'leri için entegrasyon testleri eklenmelidir.
- Kütüphane, oyun ekranı ve alt sayfalar için golden testler oluşturulmalıdır.
- GitHub Actions Flutter analyze/test/build akışları eklenmelidir.
- Android release imzalama, AAB üretimi, iOS imzalama ve Windows release dağıtımı yapılandırılmalıdır.

## Önerilen Devam Sırası

1. Android için QSP C ABI adapter ve tam `QspFfi` fonksiyonlarını bitir.
2. QSP callback akışını Riverpod oyun durumuna bağla.
3. Yerel oyun dosya/depolama katmanı ile gerçek oyun yüklemeyi çalıştır.
4. WebView, HTML işleme ve medya proxy'sini tamamla.
5. Rust arşiv/encoding işlevlerini platform kanalı veya FFI adapter aracılığıyla bağla.
6. Uzak katalog, indirme ve güvenli arşiv açmayı ekle.
7. Kayıt sistemi, bütün diyaloglar ve hile düzenleyicisini gerçek motor verisine bağla.
8. ARB tabanlı yerelleştirme, otomatik legacy veri aktarımı, iOS/Windows ve yayın doğrulamasını tamamla.

## Çalıştırma

Proje kökünden:

```powershell
python build.py android
python build.py windows
python build.py all
```

Flutter dizininden:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
