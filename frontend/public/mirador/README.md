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
> viewers means updating four directories. The update task below writes both
> copies of a viewer, so the two only drift if they are edited by hand.

- Version: **4.1.0** (from the `mirador` npm package `dist/`)
- License: Apache-2.0 (see `LICENSE.txt`)

Select Mirador with `AppConfig[:iiif_viewer] = 'mirador'` (globally, or per
repo_code via a Hash). The embed URL is `mirador/index.html?manifest=<manifest-uri>`
(see `IIIF.viewer_url`). `index.html` reads the manifest from the `manifest`
query parameter and initializes Mirador with a single window.

## Updating

Both copies are updated by:

```
./build/run iiif:update_mirador
```

That installs the latest release from npm. To pin a version:

```
./build/run iiif:update_mirador -Dversion=4.1.0
```

The task downloads the package from the npm registry, checks the tarball
against the checksum the registry publishes, and copies `dist/mirador.min.js`
and the package's `LICENSE` into both directories, updating the version
recorded in both READMEs. Files an earlier version shipped but the new one does
not are removed, so each directory keeps matching the package. `index.html` is
maintained by ArchivesSpace rather than taken from the package, so the task
leaves it alone.

Before installing anything the task checks that the bundle is still a UMD build
exposing the global `Mirador`, since `index.html` initializes the viewer through
it. If a future release fails that check the task stops rather than install a
viewer that would load but never render. There is deliberately no way to skip
the check: a release that fails it needs `index.html` reworked for the new
build, not the warning silenced.

Review the diff and run the IIIF feature specs afterwards - a major release can
change the viewer's appearance or behaviour even when it installs cleanly.
