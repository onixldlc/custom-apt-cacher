#!/bin/sh
# verify the acng cache dir got populated by clients.
set -eu

CACHE=/cache
echo "--- cache tree (top 3 levels) ---"
find "$CACHE" -maxdepth 3 -type d | head -50

echo "--- .deb files cached ---"
deb_count=$(find "$CACHE" -type f -name '*.deb' | wc -l)
echo "deb files: $deb_count"

echo "--- Release / Packages files ---"
meta_count=$(find "$CACHE" -type f \( -name 'Release*' -o -name 'Packages*' -o -name 'InRelease' \) | wc -l)
echo "meta files: $meta_count"

if [ "$deb_count" -gt 0 ] && [ "$meta_count" -gt 0 ]; then
    echo "PASS: cache populated"
    exit 0
fi

echo "FAIL: cache empty or missing"
find "$CACHE" -type f | head -20
exit 1
