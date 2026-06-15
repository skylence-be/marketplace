# skylence-codex

Codex-native companion to the Claude Code `skylence` plugin.

It keeps the Codex-compatible pieces:

- `skills/` — judge-design skill chain for action-surface audit, criteria writing, prompt writing, eval-suite design, and architecture review.
- `.mcp.json` — Skylence MCP server definitions, dormant until the endpoints or binaries are available.
- `hooks/hooks.json` — a Codex `SessionStart` hook that injects skyline-first steering when the plugin is enabled and its hook is trusted.

It intentionally omits Claude-only plugin pieces:

- Claude slash commands (`commands/lsp.md`).
- Claude LSP plugin definitions (`.lsp.json`).
- `judge-setup`, because it edits `~/.claude/*` and has no Codex-side equivalent.

The Claude judge hook is not copied verbatim; if/when a Codex judge hook is needed, it should be implemented against Codex hook payloads and trust review rather than the Claude Code hook contract.

Install from the repo-local Codex marketplace:

```sh
codex plugin marketplace add /Users/jv/Code/skylence/marketplace/.agents/plugins
codex plugin add skylence-codex@skylence-marketplace
```
