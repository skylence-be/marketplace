#!/bin/bash
# judge-hook.sh -- PreToolUse judge for Claude Code.
#
# Reads stdin JSON ({tool_name, tool_input}), runs the built-in writing-guard
# stage, then evaluates against a rules file, and decides allow / deny /
# escalate-to-LLM. Implements the LLM-as-judge pattern as a Claude Code hook.
#
# Rules file: ~/.claude/judge-rules.json (override with $JUDGE_RULES_FILE).
# If the file is missing or empty, the hook exits 0 silently (no-op). Both
# the writing stage and the rules loop are inert until the file exists.
#
# Writing-guard stage (built-in, runs before rules):
#   Checks Write/Edit content and skyline_edit patch rows for:
#     - Em dashes (zero allowed anywhere)
#     - Banned AI vocabulary and phrases (prose files >= 150 words)
#   Enabled by default once the rules file exists. Opt out with:
#     .writing.enabled = false
#   Extend with extra terms:
#     .writing.extra_vocab   (array of words, OR-joined into the banned scan)
#     .writing.extra_phrases (array of phrases, OR-joined into the phrase scan)
#
# Per-rule behavior:
#   class=deny     -> exit 2 with reason on stdout (Claude Code blocks the call)
#   class=allow    -> exit 0 (used for allowlist patterns that override later rules)
#   class=escalate -> spawn `claude -p` with judge_prompt; LLM returns ALLOW/BLOCK
#
# The hook fails *open* on infrastructure errors (missing jq, missing claude CLI,
# LLM timeout) -- this is a usability tradeoff, not a security guarantee. Use
# `class=deny` rules for anything that must block deterministically.
set -euo pipefail

RULES_FILE="${JUDGE_RULES_FILE:-$HOME/.claude/judge-rules.json}"
LLM_TIMEOUT_SECONDS="${JUDGE_LLM_TIMEOUT:-10}"
LLM_MODEL="${JUDGE_LLM_MODEL:-claude-haiku-4-5-20251001}"

# Missing rules file: no-op (opt-in by file presence).
[ -f "$RULES_FILE" ] || exit 0

# jq is required to iterate rules. Without it, fail open silently.
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT_JSON=$(echo "$INPUT" | jq -c '.tool_input // {}')

[ -z "$TOOL_NAME" ] && exit 0

# =============================================================================
# Writing-guard stage: deterministic lint on Write/Edit/skyline_edit content.
# Runs before rules, returns on skip, exit 2 on violation, falls through on
# clean. Inert unless RULES_FILE exists (already checked above).
# =============================================================================
_writing_guard() {
  # Check enabled flag. Only literal string "false" disables; missing/null/true
  # all leave the stage active. Using jq alternative-operator with a boolean
  # default is a footgun (jq // treats false as absent), so compare explicitly.
  local enabled
  enabled=$(jq -r 'if .writing.enabled == false then "false" else "true" end' "$RULES_FILE" 2>/dev/null || true)
  [ "$enabled" = "false" ] && return 0

  local wg_content=""
  local wg_paths=""
  local wg_is_prose=0

  # Build an em-dash pattern without embedding a literal em dash in this source
  # file (a PreToolUse hook on this machine denies patches whose added rows
  # contain literal em dashes).
  local EMDASH
  EMDASH=$(printf '\342\200\224')

  case "$TOOL_NAME" in
    Write|Edit)
      wg_content=$(echo "$TOOL_INPUT_JSON" | jq -r '.content // .new_string // empty' 2>/dev/null || true)
      wg_paths=$(echo "$TOOL_INPUT_JSON" | jq -r '.file_path // empty' 2>/dev/null || true)
      ;;
    mcp__*skyline_edit)
      local patch
      patch=$(echo "$TOOL_INPUT_JSON" | jq -r '.patch // empty' 2>/dev/null || true)
      [ -z "$patch" ] && return 0
      wg_content=$(printf '%s\n' "$patch" | sed -n 's/^+//p')
      wg_paths=$(printf '%s\n' "$patch" | sed -n 's/^[[:space:]]*¶//p' | sed 's/#[A-Fa-f0-9]*$//')
      ;;
    *)
      return 0
      ;;
  esac

  [ -z "$wg_content" ] && return 0

  # Filter paths: skip data, config, lock, and binary files.
  local SKIP_EXT='\.(json|jsonc|yaml|yml|toml|xml|csv|tsv|lock|lockb|lockfile|sum|mod|svg|map|min\.js|min\.css|png|jpg|jpeg|gif|webp|ico|pdf|zip|gz|tar|docx|xlsx|pptx|doc|xls|ppt|key|numbers|pages)$'
  local live_paths=""
  if [ -n "$wg_paths" ]; then
    live_paths=$(printf '%s\n' "$wg_paths" | grep -viE "$SKIP_EXT" || true)
  fi
  [ -z "$live_paths" ] && return 0

  # Determine if any surviving path is a prose file.
  if printf '%s\n' "$live_paths" | grep -qiE '\.(md|mdx|markdown|html|htm|txt|rst|adoc|tex|rtf)$'; then
    wg_is_prose=1
  fi

  # Strip fenced code blocks and inline backtick spans from content.
  local stripped
  stripped=$(printf '%s\n' "$wg_content" | awk '
    /^```/ { in_code = !in_code; next }
    !in_code { print }
  ' | sed 's/`[^`]*`//g')

  local violations=""
  local first_path
  first_path=$(printf '%s\n' "$live_paths" | head -1)

  # Em dashes: zero allowed everywhere.
  local em_count
  em_count=$(printf '%s\n' "$stripped" | grep -o "$EMDASH" | wc -l | tr -d ' ' || true)
  if [ "$em_count" -gt 0 ]; then
    violations="${violations}  Em dashes: ${em_count} found (zero allowed)\n"
  fi

  # Vocab and phrase checks only on prose files with >= 150 words.
  if [ "$wg_is_prose" -eq 1 ]; then
    local word_count
    word_count=$(printf '%s\n' "$stripped" | wc -w | tr -d ' ')
    if [ "$word_count" -ge 150 ]; then
      local banned='delve|tapestry|pivotal|testament|meticulous|nuanced|multifaceted|embark|spearhead|bolster|garner|interplay|nestled|bustling|vibrant|comprehensive|invaluable|reimagine|empower|groundbreaking|transformative|paramount|myriad|cornerstone|catalyst|seamless|seamlessly'

      # Append user-extensible vocab from .writing.extra_vocab (array).
      local extra_vocab
      extra_vocab=$(jq -r '(.writing.extra_vocab // []) | join("|")' "$RULES_FILE" 2>/dev/null || true)
      if [ -n "$extra_vocab" ]; then
        banned="${banned}|${extra_vocab}"
      fi

      local found_vocab
      found_vocab=$(printf '%s\n' "$stripped" | grep -oiE "\b(${banned})\b" 2>/dev/null | sort -fu | tr '\n' ',' | sed 's/,$//' || true)
      [ -n "$found_vocab" ] && violations="${violations}  Banned AI vocabulary: ${found_vocab}\n"

      local phrases='great question!|certainly!|absolutely!|i hope this helps|let'\''s dive in|without further ado|it'\''s worth noting that|in conclusion,|in summary,'

      # Append user-extensible phrases from .writing.extra_phrases (array).
      local extra_phrases
      extra_phrases=$(jq -r '(.writing.extra_phrases // []) | join("|")' "$RULES_FILE" 2>/dev/null || true)
      if [ -n "$extra_phrases" ]; then
        phrases="${phrases}|${extra_phrases}"
      fi

      local found_phrases
      found_phrases=$(printf '%s\n' "$stripped" | grep -oiE "(${phrases})" 2>/dev/null | sort -fu | tr '\n' ' / ' | sed 's, / $,,' || true)
      [ -n "$found_phrases" ] && violations="${violations}  AI phrases: ${found_phrases}\n"
    fi
  fi

  [ -z "$violations" ] && return 0

  printf "judge-hook: writing-guard blocked %s:\n\n%b\nRewrite the content without these tells and retry.\n" \
    "$first_path" "$violations"
  exit 2
}
_writing_guard

# Evaluate rules in declaration order. First match wins.
RULE_COUNT=$(jq '.rules | length' "$RULES_FILE" 2>/dev/null || echo 0)
[ "$RULE_COUNT" = "0" ] && exit 0

for i in $(seq 0 $((RULE_COUNT - 1))); do
  RULE=$(jq ".rules[$i]" "$RULES_FILE")
  R_TOOL=$(echo "$RULE" | jq -r '.tool // "*"')
  R_PATTERN=$(echo "$RULE" | jq -r '.pattern // ""')
  R_CLASS=$(echo "$RULE" | jq -r '.class // "allow"')
  R_REASON=$(echo "$RULE" | jq -r '.reason // ""')

  # Tool match: exact, or "*" for any.
  if [ "$R_TOOL" != "*" ] && [ "$R_TOOL" != "$TOOL_NAME" ]; then
    continue
  fi

  # Pattern match against tool_input JSON. Empty pattern = match all inputs.
  if [ -n "$R_PATTERN" ]; then
    echo "$TOOL_INPUT_JSON" | grep -qE "$R_PATTERN" || continue
  fi

  case "$R_CLASS" in
    deny)
      echo "judge-hook: blocked: ${R_REASON:-no reason given}"
      exit 2
      ;;
    allow)
      exit 0
      ;;
    escalate)
      JUDGE_PROMPT=$(echo "$RULE" | jq -r '.judge_prompt // ""')
      if [ -z "$JUDGE_PROMPT" ]; then
        # Misconfigured escalate rule: fail open with a warning to stderr.
        echo "judge-hook: escalate rule missing judge_prompt; allowing" >&2
        exit 0
      fi
      # claude CLI required for escalate. Without it, fail open.
      command -v claude >/dev/null 2>&1 || {
        echo "judge-hook: claude CLI not found; escalate rule fails open" >&2
        exit 0
      }

      # Build judge input: prompt + the actual proposal.
      FULL_PROMPT=$(printf '%s\n\nTool: %s\nInput: %s\n\nRespond with exactly one word: ALLOW or BLOCK. Then on a new line, a one-sentence reason.' \
        "$JUDGE_PROMPT" "$TOOL_NAME" "$TOOL_INPUT_JSON")

      # Call the LLM judge with a hard timeout. macOS lacks GNU timeout; use perl.
      DECISION=$(perl -e '
        $SIG{ALRM} = sub { die "timeout\n" };
        alarm $ARGV[0];
        open(my $fh, "-|", "claude", "-p", "--model", $ARGV[1], $ARGV[2]) or die "spawn: $!";
        local $/; my $out = <$fh>; close($fh);
        print $out;
      ' "$LLM_TIMEOUT_SECONDS" "$LLM_MODEL" "$FULL_PROMPT" 2>/dev/null) || {
        echo "judge-hook: LLM judge timed out or failed; allowing" >&2
        exit 0
      }

      VERDICT=$(echo "$DECISION" | head -1 | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
      LLM_REASON=$(echo "$DECISION" | sed -n '2p')

      if [ "$VERDICT" = "BLOCK" ]; then
        echo "judge-hook: LLM judge blocked: ${LLM_REASON:-no reason given}"
        exit 2
      fi
      # ALLOW or unparseable: allow (fail open on the LLM path).
      exit 0
      ;;
  esac
done

# No rule matched.
exit 0
