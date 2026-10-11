# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A single, small `Dockerfile` (no source code, tests, or CI) that extends the official `nextcloud:<version>-apache` image with ffmpeg/ffprobe (required by Nextcloud Memories; the official base has none), the `bz2` PHP extension, and a higher PHP memory limit. It is meant to be used with the Memories and Recognize apps.

## Commands

```bash
podman build -t nextcloud-multimedia .          # or docker build
podman build --build-arg NEXTCLOUD_VERSION=34.0.4 -t nextcloud-multimedia .
```

There is no test suite. To verify a bump functionally, boot the image with `-e SQLITE_DATABASE=nc -e NEXTCLOUD_ADMIN_USER=admin -e NEXTCLOUD_ADMIN_PASSWORD=...`, then `podman exec -u www-data <ctr> php occ app:install memories` / `recognize` and run `php occ memories:index`.

## Design decisions (do not re-add without a reason)

- **No node, npm, python/tensorflow, aria2, or pdlib/dlib.** Recognize downloads its own Node binary, tfjs-node/libtensorflow and ffmpeg-static at app install time (`InstallDeps.php`) and only extracts `.tar.gz`. Memories bundles its own exiftool and go-vod in `bin-ext/` (it copies them to a temp dir and chmods them at runtime, so `Permission denied` on the originals is expected). Earlier revisions of this repo carried pdlib/dlib (for the Face Recognition app), pip tensorflow, node/npm and aria2; removing them took the image from ~4.5 GB to ~1.9 GB.
- **PHP memory limit is set with `ENV PHP_MEMORY_LIMIT`**, not a `conf.d/memory-limit.ini`. The base image's `nextcloud.ini` (`memory_limit=${PHP_MEMORY_LIMIT}`) loads later alphabetically and silently overrides any such file; the old setup was a no-op for years.
- **`NEXTCLOUD_VERSION` is the only version pin**; check the app store before bumping, because the apps lag the server (as of Oct 2026: Memories 9.0.1 = NC 34-35, Recognize 12.x = NC 34, 13.x = NC 35-36).

## If Face Recognition (pdlib) ever has to come back

The old recipe is in `git log` but does not build on current bases as-is. What it took on NC 35 / PHP 8.5 / trixie:

- pdlib v1.1.0 hardcodes `-std=c++11` in `config.m4`, but dlib >= 19.24 needs C++14+: `sed -i 's/-std=c++11/-std=c++17/' config.m4` before `phpize`. dlib v20.0.1 works with this.
- Build dlib against system `libjpeg-dev libpng-dev`; otherwise its bundled libjpeg 9 collides with the libjpeg62 that PHP `gd` loads (`Wrong JPEG library version: library is 62, caller expects 90`).
- Do not set `DLIB_NO_GUI_SUPPORT` (pdlib includes GUI headers; needs `libx11-dev` to build, `libx11-6` at runtime).
- Resolve the extension dir with `php-config --extension-dir` rather than hardcoding the PHP API date.
- The Face Recognition app itself had no release for NC > 31 as of Oct 2026 (git master targets NC 34 only), which is the main reason not to use it.
