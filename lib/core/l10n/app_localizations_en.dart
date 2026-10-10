// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Questopia';

  @override
  String get home => 'Home';

  @override
  String get catalog => 'Catalog';

  @override
  String get settings => 'Settings';

  @override
  String get play => 'Play';

  @override
  String get installedGames => 'Installed games';

  @override
  String get favoriteGames => 'Favorites';

  @override
  String get saves => 'Saves';

  @override
  String get cheatModes => 'Cheat modes';

  @override
  String get search => 'Search games...';

  @override
  String get theme => 'Theme';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get amoledTheme => 'AMOLED';

  @override
  String get fontSize => 'Font Size';

  @override
  String get gameFolder => 'Game Folder';

  @override
  String get importGame => 'Import Game';

  @override
  String get exportSave => 'Export Save';

  @override
  String get importSave => 'Import Save';

  @override
  String get autoSave => 'Auto-Save';

  @override
  String get restart => 'Restart';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get variables => 'Variables';

  @override
  String get locks => 'Locks';

  @override
  String get teleport => 'Teleport';

  @override
  String get inventory => 'Inventory';

  @override
  String get tabGame => 'Game';

  @override
  String get tabStatus => 'Status';

  @override
  String get tabInventory => 'Inventory';

  @override
  String get console => 'Console';

  @override
  String get diff => 'Diff';

  @override
  String get download => 'Download';

  @override
  String get delete => 'Delete';

  @override
  String get downloading => 'Downloading...';

  @override
  String get addGame => 'Add Game';

  @override
  String get emptyLibraryHint =>
      'No games in your library yet.\nDownload from Catalog or import a folder.';

  @override
  String get fileOrArchive => 'File or Archive';

  @override
  String get fileOrArchiveHint => '.qsp, .gam, .zip, .rar, .aqsp, .7z';

  @override
  String get selectFolder => 'Select folder';

  @override
  String pageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get retry => 'Retry';

  @override
  String get prev => 'Prev';

  @override
  String get next => 'Next';

  @override
  String get noCatalogItems => 'No catalog items available.';

  @override
  String downloadedGame(String title) {
    return 'Downloaded $title';
  }

  @override
  String get searchOnlineCatalog => 'Search online catalog...';

  @override
  String get allLanguages => 'All Languages';

  @override
  String get featured => 'Featured';

  @override
  String get sortCatalog => 'Sort Catalog';

  @override
  String get selectGameFolder => 'Select Game Folder';

  @override
  String get selectGameFileOrArchive => 'Select Game File or Archive';

  @override
  String unsupportedGameFormat(Object ext) {
    return 'Selected file is not a supported game format (.$ext). Please select a .qsp, .gam, or archive file.';
  }

  @override
  String importedGame(String title) {
    return 'Imported $title';
  }

  @override
  String importFailed(String reason) {
    return 'Import failed: $reason';
  }

  @override
  String gameFileNotFound(String path) {
    return 'Game file not found at $path. Folder may have been moved or storage permission revoked.';
  }

  @override
  String get importGameTooltip => 'Import game';

  @override
  String get gameOptionsTooltip => 'Game Options';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionGeneral => 'General';

  @override
  String get sectionTypography => 'Typography';

  @override
  String get sectionMedia => 'Media and images';

  @override
  String get sectionSound => 'Sound';

  @override
  String get sectionStorage => 'Storage';

  @override
  String get sectionAbout => 'About';

  @override
  String get colorAccent => 'Color accent';

  @override
  String get language => 'Language';

  @override
  String get followSystem => 'Follow system';

  @override
  String get immersiveMode => 'Immersive mode';

  @override
  String get autoscroll => 'Auto-scroll';

  @override
  String get separatorLine => 'Separator line';

  @override
  String get edgeFeedback => 'Edge feedback';

  @override
  String get navBarBlur => 'Navigation bar blur';

  @override
  String get autoSaveInterval => 'Auto-save interval';

  @override
  String get clicks => 'clicks';

  @override
  String get cheatEngine => 'Cheat engine';

  @override
  String get qspCommandLine => 'QSP command line';

  @override
  String get actionsPanelHeight => 'Actions panel height';

  @override
  String get binaryPrefixes => 'Binary prefixes';

  @override
  String get typeface => 'Typeface';

  @override
  String get useGameFont => 'Use game font';

  @override
  String get customTextColor => 'Custom text color';

  @override
  String get textColor => 'Text color';

  @override
  String get customBackgroundColor => 'Custom background color';

  @override
  String get backgroundColor => 'Background color';

  @override
  String get customLinkColor => 'Custom link color';

  @override
  String get linkColor => 'Link color';

  @override
  String get squarePosters => 'Square poster cards';

  @override
  String get disableImages => 'Disable images';

  @override
  String get showAllImagesDialog => 'Show all images in dialog';

  @override
  String get pinchZoom => 'Pinch zoom';

  @override
  String get fullscreenImages => 'Fullscreen image viewer';

  @override
  String get autoWidth => 'Auto image width';

  @override
  String get imageWidth => 'Image width';

  @override
  String get autoHeight => 'Auto image height';

  @override
  String get imageHeight => 'Image height';

  @override
  String get playSound => 'Play sound';

  @override
  String get muteVideoAudio => 'Mute video audio';

  @override
  String get gamesFolder => 'Games folder';

  @override
  String get defaultInternalFolder => 'Default internal folder';

  @override
  String get version => 'Version';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get themeModeTitle => 'Theme Mode';

  @override
  String get colorAccentTitle => 'Color Accent';

  @override
  String get languageTitle => 'Application Language';

  @override
  String get actionsHeightTitle => 'Actions Panel Height';

  @override
  String get binaryPrefixesTitle => 'Binary Prefixes';

  @override
  String get binaryKiB => 'Binary / KiB';

  @override
  String get decimalKB => 'Decimal / KB';

  @override
  String get livePreview => 'LIVE PREVIEW';

  @override
  String get livePreviewText =>
      'You stand at the gates of an ancient castle. The heavy oak doors are sealed shut with iron runes.';

  @override
  String get accentDynamic => 'Dynamic';

  @override
  String get accentBlue => 'Blue';

  @override
  String get accentGreen => 'Green';

  @override
  String get accentOrange => 'Orange';

  @override
  String get accentPurple => 'Purple';

  @override
  String get accentPink => 'Pink';

  @override
  String get accentTeal => 'Teal';

  @override
  String get accentAmber => 'Amber';

  @override
  String get accentMonochrome => 'Lana Monochrome';

  @override
  String get fontDefaultSystem => 'Default system';

  @override
  String get fontSansSerif => 'Sans-serif';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontMonospace => 'Monospace';

  @override
  String get fontMedium => 'Medium';

  @override
  String get fontCursive => 'Cursive';

  @override
  String get fontLight => 'Light';

  @override
  String get fontCondensed => 'Condensed';

  @override
  String get fontBlack => 'Black';

  @override
  String get fontThin => 'Thin';

  @override
  String get fontCasual => 'Casual';

  @override
  String get fontSerifMonospace => 'Serif monospace';
}
