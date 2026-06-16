# Skylence Marketplace

Claude Code and Codex plugin marketplace for Skylence tooling.

Claude-side plugins live under `.claude-plugin/` and currently expose:

- **skylence** — language LSPs, judge-design skills, and a judge safety hook for Claude Code.
- **agent-org** — the Claude/Solo orchestrator doctrine pack with hooks, role skills, build-slot, ghost-probe, and Codex conduct files.

Codex-side marketplace metadata lives under `.agents/plugins/` and exposes Codex-native companion packages:

- **skylence-codex** — judge-design skills and a Codex SessionStart skyline steering hook; omits Claude-only commands and LSP setup.
- **agent-org-codex** — full Codex-side agent-org pack: orchestrator, replacer, org-audit, Codex solo-worker, AGENTS.md guidance, execpolicy rules, build-slot, ghost-probe helper, and Codex lifecycle hooks for SessionStart/PreToolUse.

The split follows the private cross-vendor guide's model/tooling map: Claude Code, Codex, and Gemini CLI occupy similar agent-shell roles (skills/hooks/MCP/subagents), but plugin manifests should stay native to each shell instead of sharing Claude-only contracts.

## Claude Code install

```
/plugin marketplace add skylence-be/marketplace
/plugin install skylence@skylence-marketplace
/plugin install agent-org@skylence-marketplace
```

## Codex install

This repo includes a Codex marketplace at `.agents/plugins/marketplace.json`. Add the repo-local marketplace root, then install either Codex companion plugin:

```
codex plugin marketplace add /Users/jv/Code/skylence/marketplace/.agents/plugins
codex plugin add skylence-codex@skylence-marketplace
codex plugin add agent-org-codex@skylence-marketplace
```

## LSP servers

The plugin bundles LSP support for `.sky` files plus 12 languages. Install the server for your language:

```
/lsp install php
```

Works for `php`, `python`, `typescript`, `go`, `rust`, `ruby`, `csharp`, `cpp`, `java`, `kotlin`, `lua`, `swift`. `/lsp list` shows the full matrix; details in [docs/lsp-servers.md](docs/lsp-servers.md).

## Also included

- **Judge hook** — PreToolUse deny/allow/escalate rules engine. Inert until `~/.claude/judge-rules.json` exists; run the `judge-setup` skill to opt in (writes CLAUDE.md guidance, seeds rules from the example, registers the user-scope hook). Eval suite in `plugins/skylence/hooks/judge-eval/`.
- **judge-design skills** — action-surface-audit, judge-criteria, judge-prompt-writer, judge-eval-suite, judge-architecture-review.
- **SessionStart steer** — prefers skyline MCP tools over built-in file tools; offers the skyline daemon setup once (declines are remembered).

## License

MIT — see [LICENSE](LICENSE).