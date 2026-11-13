#!/usr/bin/env bash
# Runs a program inside the current directory's direnv environment.
# Covers launchd (bare environment) and Zed (clobbers direnv's PATH).

if ! command -v nix >/dev/null; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
if [ -z "${__HM_SESS_VARS_SOURCED:-}" ]; then
  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

set -eu
REAL_EXECUTABLE=${REAL_EXECUTABLE:-$(which program)}
DIRENV=${DIRENV:-$(which direnv)}

devenv_in_path() {
  [ -n "${DEVENV_PROFILE:-}" ] || return 1
  # devenv CLI shells add the profile; flake shells add the flake-compat shim instead
  case ":$PATH:" in
    *":$DEVENV_PROFILE/bin:"* | *-devenv-flake-compat/bin:*) return 0 ;;
    *) return 1 ;;
  esac
}

if ! devenv_in_path; then
  # Clear direnv tracking so it re-exports the full environment
  unset DIRENV_WATCHES DIRENV_DIR DIRENV_DIFF
  eval "$("$DIRENV" export bash 2>/dev/null)"
fi

exec "$REAL_EXECUTABLE" "$@"
