FROM nextcloud:30.0.5-apache AS builder

# Build and install libraries on builder

RUN apt-get update && \
    apt-get install ffmpeg -y && \
    apt-get install -y build-essential wget cmake libx11-dev libopenblas-dev nodejs unzip && \
    rm -rf /var/lib/apt/lists/*

ARG DLIB_BRANCH=v19.24
RUN wget -c -q https://github.com/davisking/dlib/archive/$DLIB_BRANCH.tar.gz \
    && tar xf $DLIB_BRANCH.tar.gz \
    && mv dlib-* dlib \
    && cd dlib/dlib \
    && mkdir build \
    && cd build \
    && cmake -DBUILD_SHARED_LIBS=ON .. \
    && make \
    && make install

# Build and install PDLib on builder

ARG PDLIB_BRANCH=master
RUN wget -c -q https://github.com/matiasdelellis/pdlib/archive/$PDLIB_BRANCH.zip \
    && unzip $PDLIB_BRANCH \
    && mv pdlib-* pdlib \
    && cd pdlib \
    && phpize \
    && ./configure \
    && make \
    && make install

# Enable PDlib on builder

# If necesary take the php settings folder uncommenting the next line
#RUN php -i | grep "Scan this dir for additional .ini files"
RUN echo "extension=pdlib.so" > /usr/local/etc/php/conf.d/pdlib.ini

# Test PDlib instalation on builer

RUN apt-get update && \
    apt-get install -y git && \
    rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/matiasdelellis/pdlib-min-test-suite.git \
    && cd pdlib-min-test-suite \
    && make

#
# If we pass the tests, we are able to create the final image.
#

FROM nextcloud:30.0.5-apache

# Install dependencies to image

RUN apt-get update ; \
    apt-get install -y libopenblas-dev libopenblas0 libopenblas64-0

# Install dlib and PDlib to image

COPY --from=builder /usr/local/lib/libdlib.so* /usr/local/lib/

# If is necesary take the php extention folder uncommenting the next line
RUN php -i | grep extension_dir
COPY --from=builder /usr/local/lib/php/extensions/no-debug-non-zts-20220829/pdlib.so /usr/local/lib/php/extensions/no-debug-non-zts-20220829/

# Enable PDlib on final image

RUN echo "extension=pdlib.so" > /usr/local/etc/php/conf.d/pdlib.ini

# Increse memory limits

RUN echo memory_limit=2048M > /usr/local/etc/php/conf.d/memory-limit.ini

# Pdlib is already installed, now without all build dependencies.
# You could test again if everything is correct, uncommenting the next lines
#
RUN apt-get install -y git wget
RUN git clone https://github.com/matiasdelellis/pdlib-min-test-suite.git \
    && cd pdlib-min-test-suite \
    && make

#
# At this point you meet all the dependencies to install the application
# If is available you can skip this step and install the application from the application store


RUN apt-get update && apt-get install -y libbz2-dev ffmpeg && \
    docker-php-ext-install bz2 && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y wget unzip nodejs npm aria2 python3-pip && \
    rm -rf /var/lib/apt/lists/*

RUN pip install tensorflow --break-system-packages