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
    window.__ogvPlayer = player;
    player.src = '$mediaUrl';

    player.addEventListener('loadeddata', function () {
      if ($autoplay) {
        var attempt = player.play();
        if (attempt && attempt.catch) {
          attempt.catch(function () {});
        }
      }
    });

    // The page is loaded without a user gesture, so playback always starts
    // muted. Sound is enabled by the host once the player is touched.
    window.__ogvUnmute = function () {
      try {
        player.muted = !$muted;
        var resume = player.play();
        if (resume && resume.catch) {
          resume.catch(function () {});
        }
        return true;
      } catch (err) {
        return false;
      }
    };
  } catch (err) {
    window.__ogvError = String(err);
  }
})();
</script>
</body>
</html>''';
  }
}