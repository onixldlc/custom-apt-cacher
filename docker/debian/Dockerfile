### Stage 1: build ###
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        pkg-config \
        libevent-dev \
        libc-ares-dev \
        libssl-dev \
        libbz2-dev \
        liblzma-dev \
        zlib1g-dev \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . /src

RUN rm -rf builddir && mkdir builddir && cd builddir \
    && cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_INSTALL_SYSCONFDIR=/etc \
    && cmake --build . -- -j"$(nproc)" \
    && DESTDIR=/rootfs cmake --install .


### Stage 2: runtime ###
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        libevent-2.1-7 \
        libcares2 \
        libssl3 \
        libbz2-1.0 \
        liblzma5 \
        zlib1g \
        ca-certificates \
        wget \
        tini \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r apt-cacher-ng \
    && useradd -r -g apt-cacher-ng -d /var/cache/apt-cacher-ng -s /usr/sbin/nologin apt-cacher-ng

COPY --from=builder /rootfs/usr/local /usr/local
COPY --from=builder /rootfs/etc/apt-cacher-ng /etc/apt-cacher-ng.dist

RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf && ldconfig \
    && ln -s /usr/local/lib/apt-cacher-ng/acngtool /usr/local/bin/acngtool

COPY docker/debian/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /var/cache/apt-cacher-ng /var/log/apt-cacher-ng /etc/apt-cacher-ng \
    && chown -R apt-cacher-ng:apt-cacher-ng /var/cache/apt-cacher-ng /var/log/apt-cacher-ng /etc/apt-cacher-ng

EXPOSE 3142

VOLUME ["/var/cache/apt-cacher-ng", "/var/log/apt-cacher-ng"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD /usr/local/bin/entrypoint.sh healthcheck || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["run"]
