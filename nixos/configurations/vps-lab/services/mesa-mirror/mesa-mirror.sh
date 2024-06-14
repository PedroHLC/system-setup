#!/usr/bin/env bash
# Mesa has a lot of broken git objects that GitHub refuses when pushing with --mirror, so we do this the hard way.

cache_dir="../mesa-mirror.cache"
cd "$HOME/Projects/cx.chaotic/mesa-mirror"

echo "# Fetching repo"
git fetch -pu origin
git fetch --tags
git pull --all

branches=$(git branch -r | grep -v -- '->')
tags=$(git tag -l)

mkdir -p "$cache_dir"

echo "# Starting branches iterations"
for branch in $branches; do
  local_branch="${branch##origin/}"
  git branch -qf "$local_branch" "$branch"
  commit_hash=$(git rev-parse "$local_branch")
  cache_file="$cache_dir/branch_${local_branch//\//_}"
  if [ ! -f "$cache_file" ] || [ "$(cat "$cache_file")" != "$commit_hash" ]; then
    echo "## Pushing branch: $local_branch"
    echo "#### Cache-file: $cache_file"
    echo "#### Commit: $commit_hash"
    git push -qf origin "$local_branch"
    if [ $? -eq 0 ] || [ "x${HARD_SAVE:-}" == "x1" ]; then
      echo "$commit_hash" > "$cache_file"
    fi
  fi
done

echo "# Starting tags iterations"
for tag in $tags; do
  commit_hash=$(git rev-parse "$tag")
  cache_file="$cache_dir/tag_${tag//\//_}"
  if [ ! -f "$cache_file" ] || [ "$(cat "$cache_file")" != "$commit_hash" ]; then
    echo "## Pushing tag: $tag"
    echo "#### Cache-file: $cache_file"
    echo "#### Commit: $commit_hash"
    git push -qf origin "$tag"
    if [ $? -eq 0 ] || [ "x${HARD_SAVE:-}" == "x1" ]; then
      echo "$commit_hash" > "$cache_file"
    fi
  fi
done

