#!/usr/bin/env bash
# session-start.sh — injects a steer to prefer skyline MCP tools over the
# built-in file tools whenever the skyline server is connected.

cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "## skyline tool preference\n\nWhen skyline MCP tools (mcp__skyline__* or mcp__skyline-http__*) are connected, ALWAYS prefer them over the built-in file tools:\n\n- skyline_read instead of Read\n- skyline_edit instead of Edit / Write (hash-guarded patches; copy the ¶path#TAG header from skyline_read or skyline_grep output verbatim)\n- skyline_grep instead of Grep (returns ¶path#TAG anchors that feed straight into skyline_edit — no separate read needed)\n- skyline_sgrep / skyline_srewrite for structural (AST) search and multi-file rewrites\n- skyline_definition / skyline_references / skyline_rename / skyline_symbols when symbol identity matters\n\nIf both transports are connected, prefer the local HTTP server (skyline-http-mcp, http://127.0.0.1:7333/mcp) over the npx stdio variant — it is the locally installed daemon: faster startup, shared state across sessions, no per-session npx spawn.\n\nWhy: skyline edits are content-hash guarded, so they reject stale writes instead of silently clobbering concurrent changes, and its grep anchors eliminate read-before-edit round-trips.\n\nUse the built-in tools only when actually needed: skyline is not connected, reading images / PDFs / Jupyter notebooks (built-in Read), editing notebooks (NotebookEdit), or a capability skyline lacks. Brief any delegated subagent with this same rule — it will not infer it."
  }
}
EOF

exit 0