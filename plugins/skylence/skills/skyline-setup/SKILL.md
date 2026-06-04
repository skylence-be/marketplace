---
name: skyline-setup
description: "Write skyline usage guidance to ~/.claude/CLAUDE.md. Adds a ## Skyline section (from skyline's README agent prompt) telling Claude to prefer skyline MCP tools over built-in read/edit/search, how anchors work, and when to use the semantic tools. Triggers: 'skyline setup', 'add skyline section to CLAUDE.md', 'configure claude for skyline'."
disable-model-invocation: true
---

Configure `~/.claude/CLAUDE.md` with a `## Skyline` section. The prose is skyline's own agent prompt from its README ("Prompts for your agent"), kept verbatim so it stays aligned with upstream guidance.

## Step 1: Backup and strip the ## Skyline section

```bash
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
touch "$CLAUDE_MD"

BACKUP="$HOME/.claude/CLAUDE.md.bak.$(date +%Y%m%d-%H%M%S)"
cp "$CLAUDE_MD" "$BACKUP"
echo "Backup: $BACKUP"

awk '
  BEGIN {
    managed["## Skyline"] = 1
    in_strip = 0
  }
  $0 in managed { in_strip = 1; next }
  in_strip && /^## / { in_strip = 0 }
  !in_strip { print }
' "$CLAUDE_MD" > "$CLAUDE_MD.tmp" && mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
```

## Step 2: Append the ## Skyline section

```bash
cat >> "$CLAUDE_MD" << 'EOF'

## Skyline

Prefer skyline's MCP tools over your built-in file read, edit, and search tools for all code work, and especially when a skyline HTTP MCP server is registered (a shared, always-warm daemon, so calls stay cheap): use `skyline_read` to read a file (it returns a `¶path#TAG` anchor; never reconstruct that header by hand, copy it back verbatim), `skyline_grep` for regex/text search, `skyline_sgrep` for structural/AST search, `skyline_edit` to apply hash-guarded line edits using that anchor, `skyline_srewrite` for one-pass structural find-and-replace across a file or directory, and `skyline_format` for patch-syntax help; when the task is about a SYMBOL rather than text, use the semantic tools: `skyline_definition` (where is it defined, starting from a call site), `skyline_references` (every true caller; comments and strings never match), `skyline_rename` (whole-workspace rename, preview with dry_run), `skyline_symbols` (find by name fragment), and `skyline_diagnostics` (does the file still typecheck after an edit; per-file, so use the build tool for whole-project checks); always read (or grep/sgrep) to get a fresh anchor before editing, pass it back unchanged, and if an edit is rejected as stale, re-read to refresh the tag and retry. For observability (off by default): `skyline_observability_status` to see what is enabled, `skyline_observability_set` to toggle the audit/devlog/bench streams, `skyline_audit_tail` and `skyline_log_tail` to read the mutation-audit and diagnostic logs, `skyline_bench_report` for timing aggregates, and `skyline_audit_prune` / `skyline_bench_prune` to trim them.
EOF

echo "CLAUDE.md updated."
```

## Step 3: Summary

```
Skyline Setup
-----------------------------------------
CLAUDE.md ## Skyline section            done
Backup: ~/.claude/CLAUDE.md.bak.<ts>
```

If no skyline server is registered yet, point the user at the plugin's bundled servers (skyline-http-mcp on 127.0.0.1:7333 when the daemon runs, skyline-npmjs-stdio via npx otherwise) or the manual route: `npm install -g @skylence-ai/skyline`, `skyline daemon start --port 7333`, `claude mcp add --scope user --transport http skyline http://127.0.0.1:7333/mcp`.