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
  /* The canvas is sized from the intrinsic video dimensions, so the page must
     propagate a real height. Without an explicit height on both elements the
     canvas collapses to zero and the surface stays blank. */
  html, body {
    margin: 0;
    padding: 0;
    width: 100%;
    height: 100%;
    background: transparent;
    overflow: hidden;
  }
  body {
    display: flex;
    align-items: center;
    justify-content: center;
  }
  canvas {
    display: block;
    margin: 0 auto;
    /* OGV.js assigns an explicit pixel size to the canvas, so the stylesheet
       only centres it and lets the browser scale it down when needed. */
    max-width: 100%;
    max-height: 100%;
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

    // WebGL can be unavailable or unreliable inside an embedded view on some
    // devices, which leaves the canvas blank. Falling back to the software
    // frame sink keeps playback visible at the cost of some CPU.
    var webglOk = false;
    try {
      var probe = document.createElement('canvas');
      webglOk = !!(probe.getContext('webgl') ||
                   probe.getContext('experimental-webgl'));
    } catch (err) {
      webglOk = false;
    }
    console.log('[OGV] webgl=' + webglOk + ' wasm=' + OGVLoader.wasmSupported());
    if (!webglOk) {
      window.OGV_USE_SOFTWARE_SINK = true;
    }

    var player = new OGVPlayer({
      target: document.body,
      autoplay: $autoplay,
      loop: $loop,
      muted: $muted,
      preload: 'auto',
      worker: false,
      // WebGL is much faster but leaves a blank canvas on some devices, so the
      // software renderer is selected whenever WebGL is unavailable.
      webGL: webglOk
    });
    window.__ogvPlayer = player;
    player.src = '$mediaUrl';

    player.addEventListener('loadeddata', function () {
      var canvas = document.querySelector('canvas');
      console.log('[OGV] loadeddata canvas=' +
        (canvas ? canvas.width + 'x' + canvas.height : 'none') +
        ' viewport=' + window.innerWidth + 'x' + window.innerHeight);
      if ($autoplay) {
        var attempt = player.play();
        if (attempt && attempt.catch) {
          attempt.catch(function () {});
        }
      }
    });

    player.addEventListener('error', function () {
      console.log('[OGV] hata: ' + (player && player.media ? '' : ''));
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