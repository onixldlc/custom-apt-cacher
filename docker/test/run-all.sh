#!/bin/sh
# runs each os variant sequentially, tears down between runs.
# exits non-zero on first failure.
set -eu

cd "$(dirname "$0")"

COMPOSE="${COMPOSE:-podman compose}"
VARIANTS="${VARIANTS:-debian ubuntu alpine}"

status=0
for os in $VARIANTS; do
    file="docker-compose.${os}.yml"
    echo "================================================================"
    echo "  running test: $os  ($file)"
    echo "================================================================"

    if ! $COMPOSE -f "$file" up --build --abort-on-container-exit --exit-code-from verify; then
        echo "FAIL: $os"
        status=1
    else
        echo "PASS: $os"
    fi

    $COMPOSE -f "$file" down -v --remove-orphans || true
done

exit $status
