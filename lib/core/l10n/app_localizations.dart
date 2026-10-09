import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Questopia'**
  String get appTitle;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @catalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @saves.
  ///
  /// In en, this message translates to:
  /// **'Saves'**
  String get saves;

  /// No description provided for @cheatModes.
  ///
  /// In en, this message translates to:
  /// **'Cheat modes'**
  String get cheatModes;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search games...'**
  String get search;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @amoledTheme.
  ///
  /// In en, this message translates to:
  /// **'AMOLED'**
  String get amoledTheme;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @gameFolder.
  ///
  /// In en, this message translates to:
  /// **'Game Folder'**
  String get gameFolder;

  /// No description provided for @importGame.
  ///
  /// In en, this message translates to:
  /// **'Import Game'**
  String get importGame;

  /// No description provided for @exportSave.
  ///
  /// In en, this message translates to:
  /// **'Export Save'**
  String get exportSave;

  /// No description provided for @importSave.
  ///
  /// In en, this message translates to:
  /// **'Import Save'**
  String get importSave;

  /// No description provided for @autoSave.
  ///
  /// In en, this message translates to:
  /// **'Auto-Save'**
  String get autoSave;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @variables.
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get variables;

  /// No description provided for @locks.
  ///
  /// In en, this message translates to:
  /// **'Locks'**
  String get locks;

  /// No description provided for @teleport.
  ///
  /// In en, this message translates to:
  /// **'Teleport'**
  String get teleport;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @tabGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get tabGame;

  /// No description provided for @tabStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get tabStatus;

  /// No description provided for @tabInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get tabInventory;

  /// No description provided for @console.
  ///
  /// In en, this message translates to:
  /// **'Console'**
  String get console;

  /// No description provided for @diff.
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get diff;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @sectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get sectionGeneral;

  /// No description provided for @sectionTypography.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get sectionTypography;

  /// No description provided for @sectionMedia.
  ///
  /// In en, this message translates to:
  /// **'Media and images'**
  String get sectionMedia;

  /// No description provided for @sectionSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sectionSound;

  /// No description provided for @sectionStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get sectionStorage;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @colorAccent.
  ///
  /// In en, this message translates to:
  /// **'Color accent'**
  String get colorAccent;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystem;

  /// No description provided for @immersiveMode.
  ///
  /// In en, this message translates to:
  /// **'Immersive mode'**
  String get immersiveMode;

  /// No description provided for @autoscroll.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll'**
  String get autoscroll;

  /// No description provided for @separatorLine.
  ///
  /// In en, this message translates to:
  /// **'Separator line'**
  String get separatorLine;

  /// No description provided for @edgeFeedback.
  ///
  /// In en, this message translates to:
  /// **'Edge feedback'**
  String get edgeFeedback;

  /// No description provided for @navBarBlur.
  ///
  /// In en, this message translates to:
  /// **'Navigation bar blur'**
  String get navBarBlur;

  /// No description provided for @autoSaveInterval.
  ///
  /// In en, this message translates to:
  /// **'Auto-save interval'**
  String get autoSaveInterval;

  /// No description provided for @clicks.
  ///
  /// In en, this message translates to:
  /// **'clicks'**
  String get clicks;

  /// No description provided for @cheatEngine.
  ///
  /// In en, this message translates to:
  /// **'Cheat engine'**
  String get cheatEngine;

  /// No description provided for @qspCommandLine.
  ///
  /// In en, this message translates to:
  /// **'QSP command line'**
  String get qspCommandLine;

  /// No description provided for @actionsPanelHeight.
  ///
  /// In en, this message translates to:
  /// **'Actions panel height'**
  String get actionsPanelHeight;

  /// No description provided for @binaryPrefixes.
  ///
  /// In en, this message translates to:
  /// **'Binary prefixes'**
  String get binaryPrefixes;

  /// No description provided for @typeface.
  ///
  /// In en, this message translates to:
  /// **'Typeface'**
  String get typeface;

  /// No description provided for @useGameFont.
  ///
  /// In en, this message translates to:
  /// **'Use game font'**
  String get useGameFont;

  /// No description provided for @customTextColor.
  ///
  /// In en, this message translates to:
  /// **'Custom text color'**
  String get customTextColor;

  /// No description provided for @textColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get textColor;

  /// No description provided for @customBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Custom background color'**
  String get customBackgroundColor;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get backgroundColor;

  /// No description provided for @customLinkColor.
  ///
  /// In en, this message translates to:
  /// **'Custom link color'**
  String get customLinkColor;

  /// No description provided for @linkColor.
  ///
  /// In en, this message translates to:
  /// **'Link color'**
  String get linkColor;

  /// No description provided for @squarePosters.
  ///
  /// In en, this message translates to:
  /// **'Square poster cards'**
  String get squarePosters;

  /// No description provided for @disableImages.
  ///
  /// In en, this message translates to:
  /// **'Disable images'**
  String get disableImages;

  /// No description provided for @showAllImagesDialog.
  ///
  /// In en, this message translates to:
  /// **'Show all images in dialog'**
  String get showAllImagesDialog;

  /// No description provided for @pinchZoom.
  ///
  /// In en, this message translates to:
  /// **'Pinch zoom'**
  String get pinchZoom;

  /// No description provided for @fullscreenImages.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen image viewer'**
  String get fullscreenImages;

  /// No description provided for @autoWidth.
  ///
  /// In en, this message translates to:
  /// **'Auto image width'**
  String get autoWidth;

  /// No description provided for @imageWidth.
  ///
  /// In en, this message translates to:
  /// **'Image width'**
  String get imageWidth;

  /// No description provided for @autoHeight.
  ///
  /// In en, this message translates to:
  /// **'Auto image height'**
  String get autoHeight;

  /// No description provided for @imageHeight.
  ///
  /// In en, this message translates to:
  /// **'Image height'**
  String get imageHeight;

  /// No description provided for @playSound.
  ///
  /// In en, this message translates to:
  /// **'Play sound'**
  String get playSound;

  /// No description provided for @muteVideoAudio.
  ///
  /// In en, this message translates to:
  /// **'Mute video audio'**
  String get muteVideoAudio;

  /// No description provided for @gamesFolder.
  ///
  /// In en, this message translates to:
  /// **'Games folder'**
  String get gamesFolder;

  /// No description provided for @defaultInternalFolder.
  ///
  /// In en, this message translates to:
  /// **'Default internal folder'**
  String get defaultInternalFolder;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// No description provided for @themeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeModeTitle;

  /// No description provided for @colorAccentTitle.
  ///
  /// In en, this message translates to:
  /// **'Color Accent'**
  String get colorAccentTitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Application Language'**
  String get languageTitle;

  /// No description provided for @actionsHeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions Panel Height'**
  String get actionsHeightTitle;

  /// No description provided for @binaryPrefixesTitle.
  ///
  /// In en, this message translates to:
  /// **'Binary Prefixes'**
  String get binaryPrefixesTitle;

  /// No description provided for @binaryKiB.
  ///
  /// In en, this message translates to:
  /// **'Binary / KiB'**
  String get binaryKiB;

  /// No description provided for @decimalKB.
  ///
  /// In en, this message translates to:
  /// **'Decimal / KB'**
  String get decimalKB;

  /// No description provided for @livePreview.
  ///
  /// In en, this message translates to:
  /// **'LIVE PREVIEW'**
  String get livePreview;

  /// No description provided for @livePreviewText.
  ///
  /// In en, this message translates to:
  /// **'You stand at the gates of an ancient castle. The heavy oak doors are sealed shut with iron runes.'**
  String get livePreviewText;

  /// No description provided for @accentDynamic.
  ///
  /// In en, this message translates to:
  /// **'Dynamic'**
  String get accentDynamic;

  /// No description provided for @accentBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get accentBlue;

  /// No description provided for @accentGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get accentGreen;

  /// No description provided for @accentOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get accentOrange;

  /// No description provided for @accentPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get accentPurple;

  /// No description provided for @accentPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get accentPink;

  /// No description provided for @accentTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get accentTeal;

  /// No description provided for @accentAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get accentAmber;

  /// No description provided for @accentMonochrome.
  ///
  /// In en, this message translates to:
  /// **'Lana Monochrome'**
  String get accentMonochrome;

  /// No description provided for @fontDefaultSystem.
  ///
  /// In en, this message translates to:
  /// **'Default system'**
  String get fontDefaultSystem;

  /// No description provided for @fontSansSerif.
  ///
  /// In en, this message translates to:
  /// **'Sans-serif'**
  String get fontSansSerif;

  /// No description provided for @fontSerif.
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get fontSerif;

  /// No description provided for @fontMonospace.
  ///
  /// In en, this message translates to:
  /// **'Monospace'**
  String get fontMonospace;

  /// No description provided for @fontMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get fontMedium;

  /// No description provided for @fontCursive.
  ///
  /// In en, this message translates to:
  /// **'Cursive'**
  String get fontCursive;

  /// No description provided for @fontLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get fontLight;

  /// No description provided for @fontCondensed.
  ///
  /// In en, this message translates to:
  /// **'Condensed'**
  String get fontCondensed;

  /// No description provided for @fontBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get fontBlack;

  /// No description provided for @fontThin.
  ///
  /// In en, this message translates to:
  /// **'Thin'**
  String get fontThin;

  /// No description provided for @fontCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get fontCasual;

  /// No description provided for @fontSerifMonospace.
  ///
  /// In en, this message translates to:
  /// **'Serif monospace'**
  String get fontSerifMonospace;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
