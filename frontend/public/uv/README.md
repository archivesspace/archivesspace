# Universal Viewer (bundled IIIF viewer)

> **For ArchivesSpace maintainers.** The update instructions below need to run
> in a development environment. They are not a way to change the viewer on a
> deployed instance. To point a running installation at a different viewer, set
> `AppConfig[:iiif_viewer]` (see the IIIF section of `config/config.rb`).
> Upgrading the bundled viewers requires installing a newer version of
> ArchivesSpace.

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
> four directories. The update task below writes both copies of a viewer, so
> the two only drift if they are edited by hand.

- Version: **4.4.2** (from the `universalviewer` npm package `dist/`)
- License: MIT (see `LICENSE.txt`)

The embed URL is `uv/uv.html#?manifest=<manifest-uri>` (see `IIIF.viewer_url`).
`uv.html` reads the manifest from the URL hash via UV's `IIIFURLAdapter`.

## Updating

Both copies are updated by:

```
./build/run iiif:update_uv
```

That installs the latest release from npm. To pin a version:

```
./build/run iiif:update_uv -Dversion=4.4.2
```

The task downloads the package from the npm registry, checks the tarball
against the checksum the registry publishes, and copies the browser-servable
subset of `dist/` into both directories, updating the version recorded in both
READMEs:

```
umd/            uv.css   uv.html   favicon.ico
uv-iiif-config.json   uv-youtube-config.json   LICENSE.txt
```

`dist/esm/` and `dist/cjs/` are for bundler consumption and `dist/index.html`
is a demo page, so none of them are copied. `umd/` is replaced wholesale on
each update rather than written over, because its chunk filenames contain a
content hash and writing in place would leave every previous release's chunks
behind. Anything else an earlier version left in the directory is removed for
the same reason.

Before installing anything the task checks that `umd/UV.js` is still a UMD
build exposing the global `UV`, and that `uv.html` still reads the manifest
through `IIIFURLAdapter` - `IIIF.viewer_url` embeds this viewer as
`uv.html#?manifest=<uri>`, so that is the part of the package ArchivesSpace
depends on by name. If a release fails either check the task stops rather than
install a viewer that would load but never render the record. There is
deliberately no way to skip the check: a release that fails it needs the
ArchivesSpace integration reworked, not the warning silenced.

Review the diff and run the IIIF feature specs afterwards - a major release can
change the viewer's appearance or behaviour even when it installs cleanly.
