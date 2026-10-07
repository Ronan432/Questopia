class RemoteGame {
  final String id;
  final String title;
  final String author;
  final String version;
  final String fileUrl;
  final int fileSize;
  final String description;

  const RemoteGame({
    required this.id,
    required this.title,
    this.author = '',
    this.version = '',
    required this.fileUrl,
    this.fileSize = 0,
    this.description = '',
  });

  factory RemoteGame.fromJson(Map<String, dynamic> json) => RemoteGame(
        id: json['id'] as String? ?? json['game_id'] as String? ?? '',
        title: json['title'] as String? ?? json['game_name'] as String? ?? '',
        author: json['author'] as String? ?? '',
        version: json['version'] as String? ?? '',
        fileUrl: json['fileUrl'] as String? ?? json['file_url'] as String? ?? '',
        fileSize: json['fileSize'] as int? ?? json['file_size'] as int? ?? 0,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'version': version,
        'fileUrl': fileUrl,
        'fileSize': fileSize,
        'description': description,
      };
}
