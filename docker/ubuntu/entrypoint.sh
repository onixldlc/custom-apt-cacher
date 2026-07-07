#!/bin/sh
# entrypoint for apt-cacher-ng docker image
# every acng.conf directive maps to an ACNG_<Name> env var.
# examples:
#   ACNG_PORT=3142
#   ACNG_CACHEDIR=/var/cache/apt-cacher-ng
#   ACNG_LOGDIR=/var/log/apt-cacher-ng
#   ACNG_BINDADDRESS="0.0.0.0"
#   ACNG_FOREGROUND=1
#   ACNG_ADMINAUTH="user:pass"
#   ACNG_REMAP_DEBREP="..."
# any ACNG_FOO=bar becomes CLI arg Foo=bar (case handled by acng, insensitive).
# extra passthrough: ACNG_EXTRA_ARGS for anything not fitting the pattern.
#
# nginx sidecar helper:
#   if NGINX_CONF_DIR is a directory (typically a shared docker volume also
#   mounted into nginx at /etc/nginx/conf.d), the bundled default.conf is
#   dropped there on first start so the nginx service picks it up with no
#   manual bind-mount.

set -eu

CONF_DIR="${ACNG_CONF_DIR:-/etc/apt-cacher-ng}"
DIST_DIR="/etc/apt-cacher-ng.dist"
BIN="/usr/local/sbin/apt-cacher-ng"

NGINX_CONF_DIR="${NGINX_CONF_DIR:-/shared/nginx}"
NGINX_BUNDLED_CONF="/usr/local/share/apt-cacher-ng/nginx/default.conf"

seed_conf() {
    # first run: copy shipped defaults if user's conf dir empty
    if [ ! -f "$CONF_DIR/acng.conf" ]; then
        mkdir -p "$CONF_DIR"
        if [ -d "$DIST_DIR" ] && [ -n "$(ls -A "$DIST_DIR" 2>/dev/null)" ]; then
            echo "seeding conf -> $CONF_DIR (from $DIST_DIR)"
            cp -r "$DIST_DIR"/. "$CONF_DIR"/
        else
            echo "warn: $DIST_DIR missing or empty; conf not seeded" >&2
        fi
    fi
}

seed_nginx_conf() {
    # only if the shared dir exists (i.e. mounted from a compose volume)
    # and the bundled conf is present, and target file is missing.
    if [ -d "$NGINX_CONF_DIR" ] && [ -f "$NGINX_BUNDLED_CONF" ]; then
        if [ ! -f "$NGINX_CONF_DIR/default.conf" ]; then
            echo "seeding nginx conf -> $NGINX_CONF_DIR/default.conf"
            cp "$NGINX_BUNDLED_CONF" "$NGINX_CONF_DIR/default.conf"
        fi
    fi
}

build_args() {
    # emit Key=Value pairs from every ACNG_<KEY> env var (excluding reserved)
    # ACNG_CONF_DIR + ACNG_EXTRA_ARGS handled separately.
    env | while IFS='=' read -r k v; do
        case "$k" in
            ACNG_CONF_DIR|ACNG_EXTRA_ARGS) continue ;;
            ACNG_*)
                key="${k#ACNG_}"
                # empty value still valid (e.g. clear default)
                printf '%s=%s\n' "$key" "$v"
                ;;
        esac
    done
}

healthcheck() {
    port="${ACNG_PORT:-3142}"
    host="127.0.0.1"
    # minimal probe: TCP connect + HTTP get on report page
    if command -v wget >/dev/null 2>&1; then
        wget -q -O /dev/null "http://${host}:${port}/acng-report.html"
    else
        # /dev/tcp trick, dash lacks it. use exec redirect via sh? fallback to nc
        exec 3<>"/dev/tcp/${host}/${port}" 2>/dev/null || return 1
        printf 'GET /acng-report.html HTTP/1.0\r\n\r\n' >&3
        head -1 <&3 | grep -q '200'
    fi
}

run() {
    seed_conf
    seed_nginx_conf

    # default foreground so PID 1 stays alive for docker
    : "${ACNG_FOREGROUND:=1}"
    export ACNG_FOREGROUND

    # collect args
    set -- -c "$CONF_DIR"
    # shellcheck disable=SC2046
    IFS='
'
    for kv in $(build_args); do
        set -- "$@" "$kv"
    done
    unset IFS

    # extra raw args (space-separated, evaluated as shell words)
    if [ -n "${ACNG_EXTRA_ARGS:-}" ]; then
        # deliberately unquoted to allow arg splitting
        # shellcheck disable=SC2086
        set -- "$@" $ACNG_EXTRA_ARGS
    fi

    echo "starting: $BIN $*"
    exec "$BIN" "$@"
}

case "${1:-run}" in
    run) run ;;
    healthcheck) healthcheck ;;
    sh|bash) exec "$@" ;;
    *) exec "$@" ;;
esac
