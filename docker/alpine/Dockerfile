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

RUN ./build.sh -DCMAKE_INSTALL_PREFIX=/usr/local -DCFGDIR=/etc/apt-cacher-ng \
    && cmake --install builddir


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
        tini \
    && addgroup -S apt-cacher-ng \
    && adduser -S -G apt-cacher-ng -h /var/cache/apt-cacher-ng -s /sbin/nologin apt-cacher-ng

COPY --from=builder /usr/local/sbin/apt-cacher-ng /usr/local/sbin/apt-cacher-ng
COPY --from=builder /usr/local/bin/acngtool /usr/local/bin/acngtool
COPY --from=builder /usr/local/lib/apt-cacher-ng /usr/local/lib/apt-cacher-ng
COPY --from=builder /etc/apt-cacher-ng /etc/apt-cacher-ng.dist

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
