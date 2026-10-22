ARG NEXTCLOUD_VERSION=35.0.2
FROM nextcloud:${NEXTCLOUD_VERSION}-apache

# ffmpeg (+ffprobe): required by Memories for video transcoding / previews.
# bz2 PHP extension: not needed by Memories or Recognize; kept because it is tiny.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg libbz2-dev && \
    docker-php-ext-install bz2 && \
    apt-get purge -y --auto-remove libbz2-dev && \
    rm -rf /var/lib/apt/lists/*

# The base image's nextcloud.ini sets memory_limit from $PHP_MEMORY_LIMIT and is
# loaded after any conf.d file we could add, so the env var is the way to raise it.
ENV PHP_MEMORY_LIMIT=2048M
