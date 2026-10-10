/// Markup for the hidden WebView that runs the bundled OGV.js decoder.
///
/// The page is served from the loopback origin next to the decoder files and
/// the media route, so every request stays same-origin.
class OgvPlayerPage {
  const OgvPlayerPage._();

  static String build({
    required String mediaUrl,
    required bool muted,
    required bool loop,
    required bool autoplay,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<style>
  html, body {
    margin: 0;
    padding: 0;
    background: transparent;
    overflow: hidden;
  }
  canvas {
    display: block;
    max-width: 100%;
    max-height: 100%;
    margin: 0 auto;
  }
</style>
</head>
<body>
<script src="/ogv/ogv-support.js"></script>
<script src="/ogv/ogv.js"></script>
<script>
(function () {
  try {
    OGVLoader.base = '/ogv/';
    OGVLoader.simdLockMutex = false;
    window.OGV_DECODER_PROGRESS = function () {};

    var player = new OGVPlayer({
      target: document.body,
      autoplay: $autoplay,
      loop: $loop,
      muted: $muted,
      preload: 'auto',
      worker: false
    });
    player.src = '$mediaUrl';

    player.addEventListener('loadeddata', function () {
      if ($autoplay) {
        player.play();
      }
    });
  } catch (err) {
    window.__ogvError = String(err);
  }
})();
</script>
</body>
</html>''';
  }
}