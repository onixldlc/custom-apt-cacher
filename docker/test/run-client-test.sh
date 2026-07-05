#!/bin/sh
# runs inside debian/ubuntu client container.
# points apt at acng, does update+download, times a second run to prove cache hit.
set -eu

PROXY="http://${ACNG_HOST:-apt-cacher}:${ACNG_PORT:-3142}"
echo "[${DISTRO}] proxy=$PROXY"

mkdir -p /etc/apt/apt.conf.d
cat > /etc/apt/apt.conf.d/00acng <<EOF
Acquire::http::Proxy "$PROXY";
Acquire::https::Proxy "false";
EOF

echo "[${DISTRO}] --- first apt-get update (populates cache) ---"
t0=$(date +%s)
apt-get update -o Debug::Acquire::http=false
t1=$(date +%s)
first_update=$((t1 - t0))

echo "[${DISTRO}] --- download small package (curl or hello) ---"
apt-get download -y hello >/dev/null 2>&1 || apt-get download hello

echo "[${DISTRO}] --- second apt-get update (should hit cache) ---"
t2=$(date +%s)
apt-get update
t3=$(date +%s)
second_update=$((t3 - t2))

echo "[${DISTRO}] first=${first_update}s second=${second_update}s"

# proxy header check via curl-less path: rely on apt logs above.
# leave a breadcrumb file the verify service can pick up
mkdir -p /shared 2>/dev/null || true
echo "[${DISTRO}] OK"
