#!/usr/bin/env bash
# PostCompact hook: curate pinned context with Sonnet after auto/manual compaction.
# Inputs (stdin): Claude Code PostCompact payload JSON.
# Output (stdout): {"systemMessage": "..."} pointing the assistant at a saved markdown file.
# On any failure, emit {} and exit 0 so compaction is never blocked.
#
# PostCompact cannot inject additionalContext (docs: "no decision control,
# purely for audit logging / observability"). So instead we persist the
# curated markdown to a timestamped file and surface its path via systemMessage —
# the assistant can then Read it to restore pinned items.
#
# Auth: inherits from the `claude` CLI (OAuth via keychain, or ANTHROPIC_API_KEY).

set -uo pipefail

emit_empty() { printf '{}\n'; exit 0; }

# --- Dependencies ---
command -v jq     >/dev/null || emit_empty
command -v claude >/dev/null || emit_empty

# --- Parse hook input ---
input=$(cat)
transcript_path=$(jq -r '.transcript_path // empty' <<<"$input")
trigger=$(jq -r '.trigger // "auto"' <<<"$input")
custom=$(jq -r '.custom_instructions // ""' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
[[ -z "$transcript_path" || ! -r "$transcript_path" ]] && emit_empty

# --- Flatten JSONL transcript to a tagged text blob ---
# Claude Code transcript entries look like {type:"user"|"assistant",message:{content:[...]}}.
transcript=$(jq -r '
  def clip($s; $n): if ($s|length) > $n then ($s[:$n] + "…[truncated]") else $s end;
  select((.type == "user" or .type == "assistant") and (.isCompactSummary != true))
  | .message.content as $c
  | if ($c | type) == "string" then
      "<\(.type)>\n\($c)\n</\(.type)>"
    else
      ($c[] |
        if .type == "text"        then "<\(input_filename // "msg")text>\n\(.text)\n</text>"
        elif .type == "tool_use"  then "<tool_use name=\"\(.name)\">\n\(.input | tostring | clip(.;4000))\n</tool_use>"
        elif .type == "tool_result" then
          (if (.content | type) == "string" then .content
           else ([.content[]? | select(.type=="text") | .text] | join("\n"))
           end) as $txt
          | "<tool_result>\n\(clip($txt;8000))\n</tool_result>"
        else empty end)
    end
' "$transcript_path" 2>/dev/null | head -c 400000)  # hard cap ~400KB to keep payload sane

[[ -z "$transcript" ]] && emit_empty

# --- Rubric (appended to Claude Code's default system prompt) ---
#
# DESIGN NOTE: Do NOT paraphrase disk/PR content — an LLM summarization pass
# cannot guarantee verbatim reproduction of code, field names, or signatures,
# and silent drift produces wrong implementations downstream. Instead, emit
# re-read pointers to authoritative sources. Inline content only for things
# that exist ONLY in the transcript (user constraints, verbal decisions).
rubric='You curate pinned context for a Claude Code session that just underwent compaction. Your job is NOT to summarize or restate content from disk or external sources — it is to list AUTHORITATIVE RE-READ POINTERS the assistant must follow before acting.

OUTPUT FORMAT: Markdown, one `## ` section per pinned item. For each item choose exactly one of:

A. Pointer (content on disk or in a known external source — plan file, PR, issue, thoughts note, shared spec):
   - Emit a one-line imperative directive with the absolute path or canonical identifier.
   - Include section/anchor when known (`§3`, `L120-180`).
   - Example: `AUTHORITATIVE — re-read /abs/path/to/plan.md §3 before implementing GraphQL mutations. Do not rely on any paraphrase.`
   - Do NOT inline file contents. Do NOT restate the code. A pointer is enough.

B. Verbatim quote (content that exists ONLY in the transcript — user constraints, verbal decisions, ad-hoc corrections):
   - Emit the exact user utterance inside a fenced quote with attribution.
   - Example:
     > "never touch the Portfolios app, it is being deprecated"
     — user, mid-session
   - Use this ONLY for things that are not on disk and cannot be re-read.

KEEP:
1. Pointers to context sources loaded at session start (PR views/diffs, plan files under plans/ thoughts/ .agents/ tmp/plans/, specs, requirements docs, issue bodies).
2. Verbatim quotes of mid-session constraints, corrections, or decisions the user added verbally.
3. Active step/index in a plan or task list — only if not inferable by re-reading the plan file pointed to in (1).

DROP:
- Framing messages, confirmations, greetings.
- Assistant narration, tool-call chatter, intermediate reasoning.
- Debugging chatter, dead-end paths, redundant re-reads of the same source.
- Any content where you would have to paraphrase — point to the source instead.

HARD RULES:
- NEVER paraphrase code blocks, field names, function signatures, schemas, type definitions, or file contents. If you are tempted to inline code, replace it with a pointer.
- NEVER include inlined code unless it is an exact verbatim copy of a user-authored transcript utterance.
- If unsure whether to inline or point: point.
- Budget: under 1500 tokens. Fewer, sharper pointers beat many snippets.
- If nothing meaningful to pin, output exactly: `(nothing to pin)`.

Do not call any tools. Respond with the curated markdown only.'

# --- Build the user prompt (trigger + custom instructions + transcript) ---
user_prompt=$(jq -rn \
  --arg trigger "$trigger" \
  --arg custom "$custom" \
  --arg transcript "$transcript" \
  '"Compaction trigger: \($trigger)\n" +
   (if $custom != "" then "User custom instructions: \($custom)\n" else "" end) +
   "\n--- TRANSCRIPT ---\n" + $transcript')

# --- Delegate to the Claude CLI ---
curated=$(printf '%s' "$user_prompt" | timeout 540 claude \
  -p \
  --model sonnet \
  --output-format text \
  --tools "" \
  --disable-slash-commands \
  --no-session-persistence \
  --append-system-prompt "$rubric" \
  2>/dev/null) || emit_empty

curated=${curated%$'\n'}
[[ -z "$curated" || "$curated" == "(nothing to pin)" ]] && emit_empty

# --- Persist curated markdown to a timestamped file ---
timestamp=$(date +%Y-%m-%dT%H-%M-%S)
out_dir="$TMPDIR/claude-post-compact"
mkdir -p "$out_dir" || emit_empty

# Derive a project slug from cwd so multi-project users can tell files apart.
if [[ -n "$cwd" ]]; then
  slug=$(printf '%s' "$cwd" | tr '/' '-' | sed 's/^-//' | tr -c 'A-Za-z0-9.-' '-' | head -c 80)
  out_file="$out_dir/${timestamp}__${slug}.md"
else
  out_file="$out_dir/${timestamp}.md"
fi

{
  printf '<!-- generated: %s -->\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  [[ -n "$cwd" ]] && printf '<!-- cwd: %s -->\n' "$cwd"
  printf '<!-- trigger: %s -->\n\n' "$trigger"
  printf '# Post-compact re-read pointers\n\n'
  printf 'This file lists AUTHORITATIVE re-read pointers and verbatim user quotes pinned from the pre-compaction transcript. Pointers are not a substitute for the source — follow each pointer with the Read tool before acting on the pinned item. Any inlined content that is NOT a verbatim user quote is a bug; treat it as unreliable and re-read the source.\n\n'
  printf '%s\n' "$curated"
} > "$out_file" 2>/dev/null || emit_empty

# --- Surface path via systemMessage so the assistant knows to Read it ---
msg="MANDATORY: Call the Read tool on $out_file before any other action. The file is an INDEX of authoritative pointers — for each pointer inside it, you MUST Read the pointed-to source before acting on that item. Do not rely on paraphrase or recall. Do not skip this step."
jq -n --arg m "$msg" '{systemMessage: $m}'
