class LocalGame {
  final String id;
  final String title;
  final String author;
  final String version;
  final String folderPath;
  final String gameFilePath;
  final String posterPath;
  final int fileSize;
  final bool isFavorite;
  final bool isFromRepo;

  const LocalGame({
    required this.id,
    required this.title,
    this.author = '',
    this.version = '',
    required this.folderPath,
    required this.gameFilePath,
    this.posterPath = '',
    this.fileSize = 0,
    this.isFavorite = false,
    this.isFromRepo = false,
  });

  LocalGame copyWith({
    String? id,
    String? title,
    String? author,
    String? version,
    String? folderPath,
    String? gameFilePath,
    String? posterPath,
    int? fileSize,
    bool? isFavorite,
    bool? isFromRepo,
  }) {
    return LocalGame(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      version: version ?? this.version,
      folderPath: folderPath ?? this.folderPath,
      gameFilePath: gameFilePath ?? this.gameFilePath,
      posterPath: posterPath ?? this.posterPath,
      fileSize: fileSize ?? this.fileSize,
      isFavorite: isFavorite ?? this.isFavorite,
      isFromRepo: isFromRepo ?? this.isFromRepo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'version': version,
        'folderPath': folderPath,
        'gameFilePath': gameFilePath,
        'posterPath': posterPath,
        'fileSize': fileSize,
        'isFavorite': isFavorite,
        'isFromRepo': isFromRepo,
      };

  factory LocalGame.fromJson(Map<String, dynamic> json) => LocalGame(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        author: json['author'] as String? ?? '',
        version: json['version'] as String? ?? '',
        folderPath: json['folderPath'] as String? ?? '',
        gameFilePath: json['gameFilePath'] as String? ?? '',
        posterPath: json['posterPath'] as String? ?? '',
        fileSize: json['fileSize'] as int? ?? 0,
        isFavorite: json['isFavorite'] as bool? ?? false,
        isFromRepo: json['isFromRepo'] as bool? ?? false,
      );

  factory LocalGame.fromRegistry(Map<String, dynamic> json) => LocalGame(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        author: json['author'] as String? ?? '',
        version: json['version'] as String? ?? '',
        folderPath: (json['path'] ?? json['folderPath']) as String? ?? '',
        gameFilePath:
            (json['gameFile'] ?? json['gameFilePath']) as String? ?? '',
        posterPath: json['posterPath'] as String? ?? '',
        fileSize: json['fileSize'] as int? ?? 0,
        isFavorite: json['isFavorite'] as bool? ?? false,
        isFromRepo: json['isFromRepo'] as bool? ?? false,
      );

  Map<String, dynamic> toRegistry() => {
        'id': id,
        'title': title,
        'author': author,
        'version': version,
        'path': folderPath,
        'gameFile': gameFilePath,
        'posterPath': posterPath,
        'fileSize': fileSize,
        'isFavorite': isFavorite,
        'isFromRepo': isFromRepo,
        'importedAt': DateTime.now().toIso8601String(),
      };
}
