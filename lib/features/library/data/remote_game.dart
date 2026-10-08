/// A game entry coming from the remote QSP repository (`gamestock` XML).
class RemoteGame {
  final String id;
  final String title;
  final String author;
  final String portedBy;
  final String version;
  final String lang;
  final String player;
  final String icon;
  final String fileUrl;
  final int fileSize;
  final String fileExt;
  final String descUrl;
  final String pubDate;
  final String modDate;

  const RemoteGame({
    required this.id,
    required this.title,
    this.author = '',
    this.portedBy = '',
    this.version = '',
    this.lang = '',
    this.player = '',
    this.icon = '',
    required this.fileUrl,
    this.fileSize = 0,
    this.fileExt = '',
    this.descUrl = '',
    this.pubDate = '',
    this.modDate = '',
  });

  String get description => descUrl;

  String get displayName => title.trim().isNotEmpty ? title : 'Game $id';

  /// Resolves relative cover/poster image paths (e.g. `/storage/games/99/cover.jpg`)
  /// to full absolute HTTP/HTTPS URLs on qsp.org.
  String get posterUrl {
    final raw = icon.trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    if (raw.startsWith('/')) {
      return 'https://qsp.org$raw';
    }
    return 'https://qsp.org/$raw';
  }

  /// Parses both the Rust `ParsedRemoteGame` JSON output (snake_case) and a
  /// hand-built map with camelCase keys.
  factory RemoteGame.fromJson(Map<String, dynamic> json) {
    return RemoteGame(
      id: _string(json, ['id', 'game_id']),
      title: _string(json, ['title', 'game_name']),
      author: _string(json, ['author']),
      portedBy: _string(json, ['ported_by', 'portedBy']),
      version: _string(json, ['version']),
      lang: _string(json, ['lang']),
      player: _string(json, ['player']),
      icon: _string(json, ['icon', 'image']),
      fileUrl: _string(json, ['file_url', 'fileUrl']),
      fileSize: _int(json, ['file_size', 'fileSize']),
      fileExt: _string(json, ['file_ext', 'fileExt']),
      descUrl: _string(json, ['desc_url', 'descUrl']),
      pubDate: _string(json, ['pub_date', 'pubDate']),
      modDate: _string(json, ['mod_date', 'modDate']),
    );
  }

  static String _string(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is String) return value;
      if (value is num) return value.toString();
    }
    return '';
  }

  static int _int(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value) ?? double.tryParse(value)?.toInt();
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'ported_by': portedBy,
        'version': version,
        'lang': lang,
        'player': player,
        'icon': icon,
        'file_url': fileUrl,
        'file_size': fileSize,
        'file_ext': fileExt,
        'desc_url': descUrl,
        'pub_date': pubDate,
        'mod_date': modDate,
      };
}
