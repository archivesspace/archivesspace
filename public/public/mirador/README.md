# Mirador (bundled IIIF viewer)

This directory contains a self-hosted copy of [Mirador](https://projectmirador.org)
served as static files. It is one of the built-in IIIF viewers ArchivesSpace can
use (see the IIIF section of `common/config/config-defaults.rb` and
`common/iiif.rb`). The other bundled viewer is the Universal Viewer (see
`../uv/`), which is the default.

- Version: **3.4.3** (from the `mirador` npm package `dist/`)
- License: Apache-2.0 (see `LICENSE.txt`; bundled dependency notices are in
  `mirador.min.js.LICENSE.txt`)

Select Mirador with `AppConfig[:iiif_viewer] = 'mirador'` (globally, or per
repo_code via a Hash). The embed URL is `mirador/index.html?manifest=<manifest-uri>`
(see `IIIF.viewer_url`). `index.html` reads the manifest from the `manifest`
query parameter and initializes Mirador with a single window.

## Updating

To upgrade, install the desired `mirador` release in a scratch dir and copy the
UMD bundle and licenses here, preserving the layout:

```
mirador.min.js   mirador.min.js.LICENSE.txt   LICENSE.txt   index.html
```

Copy only the UMD `dist/mirador.min.js` — not `dist/es/`, `dist/cjs/`, or the
`.map` sourcemap, which are for bundler consumption and not needed to self-host.
