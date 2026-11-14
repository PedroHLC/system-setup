#!/usr/bin/env bash
# Register an existing checkout without moving it or checking out any files.
# Usage: bash link-existing-worktree.sh [bare-repository [existing-worktree]]
# Defaults: $HOME/.system.git and /etc/nixos. Requires Git with worktree repair.
# Run as the repository owner, with write access to both directories, while no
# other Git commands are running against this repository.
set -euo pipefail

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  sed -n '2,6p' "${BASH_SOURCE[0]}"
  exit 0
fi
(( $# <= 2 )) || die 'Expected at most two arguments; see --help.'

# Explicit paths below must not be redirected by inherited Git variables.
for variable in GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES; do
  [[ ! -v $variable ]] || die "Unset $variable before running this script."
done
export GIT_OPTIONAL_LOCKS=0

repo=$(cd -- "${1:-$HOME/.system.git}" && pwd -P)
worktree=$(cd -- "${2:-/etc/nixos}" && pwd -P)
bare_git() { git --git-dir="$repo" "$@"; }
existing_git() { git --git-dir="$repo" --work-tree="$worktree" "$@"; }

[[ $(bare_git rev-parse --is-bare-repository) == true ]] || die 'Repository must be bare.'
[[ ! -e "$worktree/.git" && ! -L "$worktree/.git" ]] || die "$worktree/.git already exists; nothing changed."
[[ -w "$worktree" && -w "$repo" ]] || die 'Both directories must be writable.'
[[ -f "$repo/index" ]] || die 'Expected an existing index in the bare repository.'
[[ ! -e "$repo/index.lock" ]] || die 'The repository index is locked.'
branch=$(bare_git symbolic-ref --short HEAD) || die 'Expected HEAD to point to a branch.'
bare_git rev-parse --verify HEAD >/dev/null

scratch=$(mktemp -d "${TMPDIR:-/tmp}/link-existing-worktree.XXXXXXXX")
staging="$scratch/worktree"
on_exit() {
  result=$?
  if (( result != 0 )); then
    printf 'Stopped. Diagnostic files and any temporary registration remain at %s.\n' "$scratch" >&2
    printf 'Inspect git worktree list before retrying; do not prune the registration blindly.\n' >&2
  fi
}
trap on_exit EXIT

existing_git status --porcelain=v1 -z --untracked-files=all > "$scratch/status.before"
existing_git diff --no-ext-diff --no-textconv --binary > "$scratch/unstaged.before"
existing_git diff --cached --no-ext-diff --no-textconv --binary > "$scratch/staged.before"
cp -- "$repo/index" "$scratch/index.before"

# Git creates only the pointer and administrative files; no checkout occurs.
bare_git -c core.hooksPath=/dev/null worktree add --no-checkout "$staging" "$branch"
admin=$(git -C "$staging" rev-parse --absolute-git-dir)
cp -- "$scratch/index.before" "$admin/index"
# Preserve split-index dependencies too, if the original index uses them.
for shared_index in "$repo"/sharedindex.*; do
  [[ ! -f "$shared_index" ]] || cp -- "$shared_index" "$admin/"
done

# Copy only the pointer, including across filesystems. Never move the mount.
# noclobber also protects against a .git file created since the initial check.
(set -o noclobber; cat -- "$staging/.git" > "$worktree/.git")
rm -- "$staging/.git"
bare_git worktree repair "$worktree"
rmdir -- "$staging"

git -C "$worktree" status --porcelain=v1 -z --untracked-files=all > "$scratch/status.after"
git -C "$worktree" diff --no-ext-diff --no-textconv --binary > "$scratch/unstaged.after"
git -C "$worktree" diff --cached --no-ext-diff --no-textconv --binary > "$scratch/staged.after"
cmp -- "$scratch/status.before" "$scratch/status.after"
cmp -- "$scratch/unstaged.before" "$scratch/unstaged.after"
cmp -- "$scratch/staged.before" "$scratch/staged.after"
cmp -- "$scratch/index.before" "$repo/index"
[[ $(bare_git rev-parse --is-bare-repository) == true ]]
[[ $(git -C "$worktree" rev-parse --is-bare-repository) == false ]]

rm -- "$scratch"/{status,unstaged,staged}.{before,after} "$scratch/index.before"
rmdir -- "$scratch"
trap - EXIT
printf 'Registered %s on branch %s; existing changes and index preserved.\n' "$worktree" "$branch"
bare_git worktree list
