# Mirador (bundled IIIF viewer)

This directory contains a self-hosted copy of [Mirador](https://projectmirador.org)
served as static files. It is one of the built-in IIIF viewers ArchivesSpace can
use (see the IIIF section of `common/config/config-defaults.rb` and
`common/iiif.rb`). The other bundled viewer is the Universal Viewer (see
`../uv/`), which is the default.

> **This is one of two copies, so upgrades have to be applied twice.** Each app
> serves its own static files, so Mirador is bundled once for the staff UI
> (`frontend/public/mirador/`) and once for the public UI
> (`public/public/mirador/`). The two copies are identical and are meant to stay
> on the same version, so an upgrade has to be made in both or the staff and
> public viewers will drift apart. The Universal Viewer is duplicated the same
> way (`frontend/public/uv/` and `public/public/uv/`), so upgrading both bundled
> viewers means updating four directories.

- Version: **4.1.0** (from the `mirador` npm package `dist/`)
- License: Apache-2.0 (see `LICENSE.txt`)

Select Mirador with `AppConfig[:iiif_viewer] = 'mirador'` (globally, or per
repo_code via a Hash). The embed URL is `mirador/index.html?manifest=<manifest-uri>`
(see `IIIF.viewer_url`). `index.html` reads the manifest from the `manifest`
query parameter and initializes Mirador with a single window.

## Updating

To upgrade, install the desired `mirador` release in a scratch dir and copy the
UMD bundle and license here, preserving the layout:

```
mirador.min.js   LICENSE.txt   index.html
```

`mirador.min.js` is the package's `dist/mirador.min.js` (the UMD build, which
exposes the global `Mirador` used by `index.html`). `LICENSE.txt` is the
package's root `LICENSE`. Do not copy `dist/mirador.es.js` or the `.map`
sourcemap, which are for bundler consumption and not needed to self-host. The
Vite build used since 4.x ships no `mirador.min.js.LICENSE.txt` third-party
notices sidecar, so there is none to copy. `index.html` is maintained by
ArchivesSpace and is not part of the Mirador package, so keep it when replacing
the bundle.

Then repeat the copy into the other app's `mirador/` directory (see the note
above) and update the version recorded in both READMEs.
