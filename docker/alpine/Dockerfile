### Stage 1: build ###
FROM alpine:3.20 AS builder

RUN apk add --no-cache \
        build-base \
        cmake \
        pkgconf \
        linux-headers \
        libevent-dev \
        c-ares-dev \
        openssl-dev \
        bzip2-dev \
        xz-dev \
        zlib-dev \
        ca-certificates

WORKDIR /src
COPY . /src

RUN rm -rf builddir && mkdir builddir && cd builddir \
    && cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_INSTALL_SYSCONFDIR=/etc \
        -DCMAKE_CXX_FLAGS="-include sys/time.h" \
    && cmake --build . -- -j"$(nproc)" \
    && DESTDIR=/rootfs cmake --install .


### Stage 2: runtime ###
FROM alpine:3.20

RUN apk add --no-cache \
        libevent \
        c-ares \
        libcrypto3 \
        libssl3 \
        libbz2 \
        xz-libs \
        zlib \
        libstdc++ \
        ca-certificates \
        wget \
        tini \
    && addgroup -S apt-cacher-ng \
    && adduser -S -G apt-cacher-ng -h /var/cache/apt-cacher-ng -s /sbin/nologin apt-cacher-ng

COPY --from=builder /rootfs/usr/local /usr/local
COPY --from=builder /rootfs/etc/apt-cacher-ng /etc/apt-cacher-ng.dist

# musl ldconfig only rebuilds cache — export lib path via ld.so.conf-style file
RUN mkdir -p /etc \
    && echo "/usr/local/lib" > /etc/ld-musl-x86_64.path \
    && ln -s /usr/local/lib/apt-cacher-ng/acngtool /usr/local/bin/acngtool

ENV LD_LIBRARY_PATH=/usr/local/lib

COPY docker/alpine/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /var/cache/apt-cacher-ng /var/log/apt-cacher-ng /etc/apt-cacher-ng \
    && chown -R apt-cacher-ng:apt-cacher-ng /var/cache/apt-cacher-ng /var/log/apt-cacher-ng /etc/apt-cacher-ng

EXPOSE 3142

VOLUME ["/var/cache/apt-cacher-ng", "/var/log/apt-cacher-ng"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD /usr/local/bin/entrypoint.sh healthcheck || exit 1

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["run"]
