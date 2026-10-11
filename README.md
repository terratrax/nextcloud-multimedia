# nextcloud-multimedia

The official Nextcloud apache image plus what Nextcloud Memories needs and the official base lacks:

- ffmpeg / ffprobe
- bz2 PHP extension
- PHP `memory_limit` raised to 2048M (override with `PHP_MEMORY_LIMIT`)

Works with Memories and Recognize. Recognize downloads its own Node, tfjs-node and ffmpeg when the app is installed, so nothing for it needs to be baked into the image.

## Build

```bash
docker build -t nextcloud-multimedia .
docker build --build-arg NEXTCLOUD_VERSION=34.0.4 -t nextcloud-multimedia .
```
