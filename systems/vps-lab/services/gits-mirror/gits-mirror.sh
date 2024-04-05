#!/usr/bin/env bash
cd "/var/public-git"

for f in */*/*/; do
    pushd "$f"
    git remote update &
    popd
done

wait
