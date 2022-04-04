FROM alpine:latest

ARG BUILD_DATE
ARG BUILD_VCS_REF

ARG FFMPEG_VERSION=5.0
ARG JASPER_VERSION=3.0.3
ARG SERVIIO_VERSION=2.2.1

LABEL \
  org.label-schema.build-date="${BUILD_DATE}" \
  org.label-schema.description="DLNA Serviio Container" \
  org.label-schema.name="DLNA Serviio Container" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.url="https://riftbit.com/" \
  org.label-schema.vcs-ref="${BUILD_VCS_REF}" \
  org.label-schema.vcs-url="https://github.com/danie1k/docker-serviio/" \
  org.label-schema.vendor="[riftbit] ErgoZ <ergozru@gmail.com>" \
  org.label-schema.version="${SERVIIO_VERSION}" \
  maintainer="[riftbit] ErgoZ <ergozru@gmail.com>"

WORKDIR /tmp/

ADD \
  "http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz" \
  "https://github.com/jasper-software/jasper/releases/download/version-${JASPER_VERSION}/jasper-${JASPER_VERSION}.tar.gz" \
  "http://download.serviio.org/releases/serviio-${SERVIIO_VERSION}-linux.tar.gz" \
  https://raw.githubusercontent.com/riftbit/dcraw/master/dcraw.c \
  /tmp/

RUN set -ex \
 && apk update && apk upgrade \
 && apk add --no-cache --update \
    alsa-lib \
    bzip2 \
    expat \
    fdk-aac \
    gnutls-dev \
    lame \
    lame-dev \
    libass-dev \
    libbz2 \
    libdrm \
    libffi \
    libjpeg-turbo \
    libogg \
    libpciaccess \
    librtmp \
    libstdc++ \
    libtasn1 \
    libtheora \
    libva \
    libvorbis \
    libvpx \
    libwebp-dev \
    mesa-gl \
    mesa-glapi \
    musl \
    openjdk8-jre \
    openssl \
    opus \
    p11-kit \
    sdl \
    shadow \
    v4l-utils-libs \
    x264 \
    x264-libs \
    x265 \
    xvidcore \
 && apk add --no-cache --update --virtual=.build-dependencies \
    alsa-lib-dev \
    bzip2-dev \
    cmake \
    coreutils \
    curl \
    fdk-aac-dev \
    freetype-dev \
    g++ \
    gcc \
    git \
    imlib2-dev \
    lcms2-dev \
    libgcc \
    libjpeg-turbo-dev \
    libogg-dev \
    libtheora-dev \
    libva-dev \
    libvorbis-dev \
    libvpx-dev \
    libx11 \
    libxau \
    libxcb \
    libxcb-dev \
    libxdamage \
    libxdmcp \
    libxext \
    libxfixes \
    libxfixes-dev \
    libxshmfence \
    libxxf86vm \
    make \
    musl-dev \
    nasm \
    nettle \
    openssl-dev \
    opus-dev \
    pkgconf \
    pkgconf-dev \
    rtmpdump-dev \
    sdl-dev \
    tar \
    ttf-dejavu \
    v4l-utils-dev \
    x264-dev \
    x265-dev \
    xvidcore-dev \
    yasm-dev \
    zlib-dev \
### Compile and install FFmpeg
 && tar xfv ffmpeg-*.tar.gz && cd ffmpeg-*/ \
 && ./configure \
    --disable-debug \
    --disable-doc \
    --disable-shared \
    --enable-avfilter \
    --enable-gnutls \
    --enable-gpl \
    --enable-libass \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-librtmp \
    --enable-libtheora \
    --enable-libv4l2 \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libwebp \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libxcb \
    --enable-libxvid \
    --enable-nonfree \
    --enable-pic \
    --enable-postproc \
    --enable-pthreads \
    --enable-small \
    --enable-static \
    --enable-vaapi \
    --enable-version3 \
    --extra-libs="-lpthread -lm" \
    --prefix=/usr \
 && make -j$(nproc) && make install \
 && gcc -o tools/qt-faststart $CFLAGS tools/qt-faststart.c \
 && install -v -D -m755 tools/qt-faststart /usr/bin/qt-faststart \
 && make distclean \
 && cd /tmp \
### Compile and install JasPer
 && tar xfv jasper-*.tar.gz && cd jasper-*/ \
 && mkdir ./obj && cd ./obj \
 && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=/usr/lib \
 && make -j$(nproc) && make install \
 && cd /tmp \
### Compile and install dcraw
 && gcc -o dcraw -O4 dcraw.c -lm -ljasper -ljpeg -llcms2 \
 && cp dcraw /usr/bin/dcraw && chmod +x /usr/bin/dcraw \
 && cd /tmp \
### Prepare filesystem for later installation of Serviio
 && mkdir -p /opt/serviio /serviio_src /media \
 && tar xfv serviio-*.tar.gz \
 && mv -fv ./serviio-*/* /serviio_src/ \
  # Remove original loging configuration files
 && rm -fv \
    /serviio_src/config/log4j2.xml \
    /serviio_src/library/derby.properties \
 && chmod +x /serviio_src/bin/serviio.sh \
### Create non-root user
 && groupmod -g 1000 users \
 && useradd -u 911 -U -d /opt/serviio -s /bin/false abc \
 && usermod -G users abc \
### Post-install cleanup
 && cd / \
 && rm -rf /tmp/* /var/cache/apk/* \
 && apk del --purge .build-dependencies

ADD ./root/ /
RUN set -ex \
 && chmod -R 555 /serviio_src \
 && chmod -R 777 /opt/serviio \
 && chmod +x /docker-entrypoint.sh

WORKDIR /opt/serviio

ENV \
  JAVA_HOME=/usr \
  SERVIIO_HOME=/opt/serviio/ \
  # OFF, FATAL, ERROR, WARN, INFO, DEBUG, TRACE, ALL
  LOG_LEVEL=INFO

VOLUME ["/opt/serviio", "/media"]

EXPOSE \
  1900/udp \
  8895/tcp \
  # HTTP/1.1 /console /rest
  23423/tcp \
  # HTTP/1.1 /cds /mediabrowser
  23424/tcp \
  # HTTPS/1.1 /console /rest
  23523/tcp \
  # HTTPS/1.1 /cds /mediabrowser
  23524/tcp

HEALTHCHECK --start-period=5m CMD wget --quiet --tries=1 -O /dev/null --server-response --timeout=5 http://127.0.0.1:23423/console/ || exit 1

CMD /docker-entrypoint.sh
