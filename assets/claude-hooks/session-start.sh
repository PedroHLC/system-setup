#!/usr/bin/env bash
# SessionStart hook (matcher "compact"): inject the post-compact
# re-read pointers file produced by post-compact.sh into the model's
# context immediately when the session resumes after compaction.
#
# Why this event: PostCompact is observational-only (no additionalContext
# field, stderr only goes to the user). SessionStart with matcher
# "compact" fires on both auto and manual compaction and supports
# hookSpecificOutput.additionalContext, which lands in the model's
# context before it takes its next action.
#
# Pairing: post-compact.sh writes the curated markdown to
# $TMPDIR/claude-post-compact/<ts>__<slug>.md. We pick the newest file
# matching this cwd's slug. No transcript archaeology needed — the
# SessionStart event is already gated to compaction by the "compact"
# matcher, so we trust the source field.

set -uo pipefail

emit_empty() { printf '{}\n'; exit 0; }

command -v jq >/dev/null || emit_empty

input=$(cat)
source=$(jq -r '.source // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")

# Matcher should already filter, but double-check the source field.
[[ "$source" != "compact" ]] && emit_empty
[[ -z "$cwd" ]] && emit_empty

# Slug algorithm MUST match post-compact.sh exactly.
slug=$(printf '%s' "$cwd" | tr '/' '-' | sed 's/^-//' | tr -c 'A-Za-z0-9.-' '-' | head -c 80)

out_dir="${TMPDIR:-/tmp}/claude-post-compact"
[[ -d "$out_dir" ]] || emit_empty

# Pick the newest curated file for this cwd slug. Use `ls -t` for a
# portable newest-first listing (GNU stat on Nix doesn't honour BSD
# `stat -f %m`, so avoid stat entirely).
shopt -s nullglob
matches=("$out_dir"/*__"$slug".md)
(( ${#matches[@]} > 0 )) || emit_empty

newest=$(ls -t "${matches[@]}" 2>/dev/null | head -n 1)
[[ -n "$newest" && -f "$newest" ]] || emit_empty

msg="A compaction just occurred in this session. MANDATORY: Call the Read tool on $newest before any other action. The file is an INDEX of authoritative re-read pointers curated from the pre-compaction transcript — for each pointer it lists, you MUST Read the pointed-to source before acting on that item. Do not rely on paraphrase or recall. Do not skip this step."

jq -n --arg m "$msg" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $m
  }
}'
