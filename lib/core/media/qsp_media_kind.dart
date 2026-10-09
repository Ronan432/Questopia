import 'dart:io';
import 'package:path/path.dart' as p;

enum QspMediaKind { image, video, unknown }

const _imageExt = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'};
const _videoExt = {
  '.ogv',
  '.ogg',
  '.webm',
  '.mp4',
  '.m4v',
  '.mkv',
  '.avi',
  '.mov',
  '.3gp',
  '.flv',
  '.ts',
};

QspMediaKind detectMediaKind(String path) {
  final ext = p.extension(path).toLowerCase();
  if (_imageExt.contains(ext)) return QspMediaKind.image;
  if (_videoExt.contains(ext)) return QspMediaKind.video;
  return _sniff(path);
}

QspMediaKind _sniff(String path) {
  try {
    final file = File(path);
    if (!file.existsSync()) return QspMediaKind.unknown;
    final raf = file.openSync();
    final h = raf.readSync(16);
    raf.closeSync();
    if (h.length < 12) return QspMediaKind.unknown;

    // JPEG: FF D8
    if (h[0] == 0xFF && h[1] == 0xD8) return QspMediaKind.image;

    // PNG: 89 50 4E 47
    if (h[0] == 0x89 && h[1] == 0x50 && h[2] == 0x4E && h[3] == 0x43) {
      return QspMediaKind.image;
    }
    if (h[0] == 0x89 && h[1] == 0x50 && h[2] == 0x4E && h[3] == 0x47) {
      return QspMediaKind.image;
    }

    // GIF: 47 49 46
    if (h[0] == 0x47 && h[1] == 0x49 && h[2] == 0x46) return QspMediaKind.image;

    // WEBP: RIFF....WEBP
    if (h[0] == 0x52 &&
        h[1] == 0x49 &&
        h[2] == 0x46 &&
        h[3] == 0x46 &&
        h[8] == 0x57 &&
        h[9] == 0x45 &&
        h[10] == 0x42 &&
        h[11] == 0x50) {
      return QspMediaKind.image;
    }

    // Ogg / OGV container: OggS
    if (h[0] == 0x4F && h[1] == 0x67 && h[2] == 0x67 && h[3] == 0x53) {
      return QspMediaKind.video;
    }

    // WebM / MKV (Matroska container): 1A 45 DF A3
    if (h[0] == 0x1A && h[1] == 0x45 && h[2] == 0xDF && h[3] == 0xA3) {
      return QspMediaKind.video;
    }

    // MP4 / MOV / 3GP (ISO Base Media container): ....ftyp
    if (h.length >= 8 &&
        h[4] == 0x66 &&
        h[5] == 0x74 &&
        h[6] == 0x79 &&
        h[7] == 0x70) {
      return QspMediaKind.video;
    }
  } catch (_) {}
  return QspMediaKind.unknown;
}
