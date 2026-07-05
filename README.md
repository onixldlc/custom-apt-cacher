# custom-apt-cacher
cloned [apt cacher](https://salsa.debian.org/blade/apt-cacher-ng) with some ai slop changes 

## Quick start (Docker Compose)

Runs the cacher behind an nginx reverse proxy on port 80.

```sh
docker compose up -d
# or: podman compose up -d
```

Then point apt clients at the host:

```conf
# /etc/apt/apt.conf.d/00acng
Acquire::http::Proxy "http://<host-ip>:80";
```

Verify: `curl http://<host-ip>:80/acng-report.html` (HTTP 200).

## Image tags on GHCR

`ghcr.io/onixldlc/custom-apt-cacher`

| Tag | Base image |
| --- | --- |
| `latest`, `ubuntu`, `ubuntu-v<X.Y.Z>-r<N>` | Ubuntu 24.04 |
| `debian`, `debian-v<X.Y.Z>-r<N>` | Debian bookworm |
| `alpine`, `alpine-v<X.Y.Z>-r<N>` | Alpine 3.20 |

`latest` always points at the Ubuntu variant. Debian/Alpine must be pulled by explicit name.

## Environment variables

The entrypoint maps every `ACNG_<KEY>=value` env var to a `Key=value` CLI arg for `apt-cacher-ng`. Names are case-insensitive.

| Env var | Description | Default |
| --- | --- | --- |
| `ACNG_PORT` | Listen port inside container | `3142` |
| `ACNG_BINDADDRESS` | Bind address | `0.0.0.0` |
| `ACNG_CACHEDIR` | Cache dir | `/var/cache/apt-cacher-ng` |
| `ACNG_LOGDIR` | Log dir | `/var/log/apt-cacher-ng` |
| `ACNG_FOREGROUND` | Stay in foreground (required for docker) | `1` |
| `ACNG_ADMINAUTH` | `user:password` for admin UI | *(unset)* |
| `ACNG_REPORTPAGE` | Report page path | `acng-report.html` |
| `ACNG_VERBOSELOG` | Verbose logging | `0` |
| `ACNG_CONF_DIR` | Config dir inside container | `/etc/apt-cacher-ng` |
| `ACNG_EXTRA_ARGS` | Raw extra args appended to command | *(unset)* |
| `NGINX_CONF_DIR` | If mounted (shared with nginx sidecar), the bundled `default.conf` is seeded here on start | `/shared/nginx` |

Any other `acng.conf` directive can be passed the same way (e.g. `ACNG_REMAP_DEBREP=...`, `ACNG_PROXYAUTHINFO=...`). See `conf/acng.conf.in` for the full list.

## Building the image locally

```sh
# ubuntu variant
docker build -f docker/ubuntu/Dockerfile -t custom-apt-cacher:ubuntu .

# debian variant
docker build -f docker/debian/Dockerfile -t custom-apt-cacher:debian .

# alpine variant
docker build -f docker/alpine/Dockerfile -t custom-apt-cacher:alpine .
```

## Releasing

Push a git tag matching `vX.Y.Z-rN`:

```sh
git tag v3.7.5-r1
git push --tags
```

The workflow parses the tag, publishes `ghcr.io/onixldlc/custom-apt-cacher:<os>-v3.7.5-r1` for each OS variant (plus rolling `<os>` tags; ubuntu additionally gets `latest`).
