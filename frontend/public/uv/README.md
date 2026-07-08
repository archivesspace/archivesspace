# Universal Viewer (bundled IIIF viewer)

This directory contains a self-hosted copy of [Universal Viewer](https://github.com/UniversalViewer/universalviewer)
served as static files. It is the built-in IIIF viewer used when no
`AppConfig[:iiif_viewer_url]` is configured (see the IIIF section of
`common/config/config-defaults.rb` and `common/iiif.rb`).

- Version: **4.4.2** (from the `universalviewer` npm package `dist/`)
- License: MIT (see `LICENSE.txt`)

The embed URL is `uv/uv.html#?manifest=<manifest-uri>` (see `IIIF.viewer_url`).
`uv.html` reads the manifest from the URL hash via UV's `IIIFURLAdapter`.

## Updating

To upgrade, install the desired `universalviewer` release in a scratch dir and
copy the browser-servable subset of its `dist/` here, preserving the layout:

```
umd/            uv.css   uv.html   favicon.ico
uv-iiif-config.json   uv-youtube-config.json   LICENSE.txt
```

Do not copy `dist/esm/`, `dist/cjs/`, or the demo `dist/index.html` — those are
for bundler consumption, not self-hosting.
