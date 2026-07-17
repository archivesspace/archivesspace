# Universal Viewer (bundled IIIF viewer)

This directory contains a self-hosted copy of [Universal Viewer](https://github.com/UniversalViewer/universalviewer)
served as static files. It is the default bundled IIIF viewer, used when
`AppConfig[:iiif_viewer]` is `'universal_viewer'` (the default). The other
bundled viewer is Mirador (see `../mirador/`). See the IIIF section of
`common/config/config-defaults.rb` and `common/iiif.rb`.

> **This is one of two copies, so upgrades have to be applied twice.** Each app
> serves its own static files, so Universal Viewer is bundled once for the staff
> UI (`frontend/public/uv/`) and once for the public UI (`public/public/uv/`).
> The two copies are identical and are meant to stay on the same version, so an
> upgrade has to be made in both or the staff and public viewers will drift
> apart. Mirador is duplicated the same way (`frontend/public/mirador/` and
> `public/public/mirador/`), so upgrading both bundled viewers means updating
> four directories.

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

Do not copy `dist/esm/`, `dist/cjs/`, or the demo `dist/index.html`, which are
for bundler consumption, not self-hosting.

Then repeat the copy into the other app's `uv/` directory (see the note above)
and update the version recorded in both READMEs.
