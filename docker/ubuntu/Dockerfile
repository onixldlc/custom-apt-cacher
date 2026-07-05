### Stage 1: build ###
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

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

RUN ./build.sh -DCMAKE_INSTALL_PREFIX=/usr/local -DCFGDIR=/etc/apt-cacher-ng \
    && cmake --install builddir


### Stage 2: runtime ###
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        libevent-2.1-7t64 \
        libcares2 \
        libssl3t64 \
        libbz2-1.0 \
        liblzma5 \
        zlib1g \
        ca-certificates \
        tini \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r apt-cacher-ng \
    && useradd -r -g apt-cacher-ng -d /var/cache/apt-cacher-ng -s /usr/sbin/nologin apt-cacher-ng

COPY --from=builder /usr/local/sbin/apt-cacher-ng /usr/local/sbin/apt-cacher-ng
COPY --from=builder /usr/local/bin/acngtool /usr/local/bin/acngtool
COPY --from=builder /usr/local/lib/apt-cacher-ng /usr/local/lib/apt-cacher-ng
COPY --from=builder /etc/apt-cacher-ng /etc/apt-cacher-ng.dist

COPY docker/ubuntu/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /var/cache/apt-cacher-ng /var/log/apt-cacher-ng /etc/apt-cacher-ng \
    && chown -R apt-cacher-ng:apt-cacher-ng /var/cache/apt-cacher-ng /var/log/apt-cacher-ng /etc/apt-cacher-ng

EXPOSE 3142

VOLUME ["/var/cache/apt-cacher-ng", "/var/log/apt-cacher-ng"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD /usr/local/bin/entrypoint.sh healthcheck || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["run"]
