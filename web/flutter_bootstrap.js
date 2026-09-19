// Custom bootstrap: forces the CanvasKit/Skwasm assets to load from the
// files served alongside this app instead of the gstatic.com CDN, so the
// web build works fully offline / from a local file server.
{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
