#!/usr/bin/env bash
cd "/var/public-git"

for f in */*/*/; do
    pushd "$f" >/dev/null
    (git remote update || (echo "Failed ${f}" >&2)) &
    popd >/dev/null
done

wait
