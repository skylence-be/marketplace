# Skylence Marketplace

Claude Code plugin marketplace. One plugin: **skylence** — wires the Skylence toolchain into Claude Code: MCP servers, language LSPs, and a judge safety hook.

## Install

```
/plugin marketplace add skylence-be/marketplace
/plugin install skylence@skylence-marketplace
```

## LSP servers

The plugin bundles LSP support for `.sky` files plus 12 languages. Install the server for your language:

```
/lsp install php
```

Works for `php`, `python`, `typescript`, `go`, `rust`, `ruby`, `csharp`, `cpp`, `java`, `kotlin`, `lua`, `swift`. `/lsp list` shows the full matrix; details in [docs/lsp-servers.md](docs/lsp-servers.md).

## Also included

- **6 MCP servers** via `.mcp.json` — skylence-content, skyline (HTTP + npx), skyway, skybox. Dormant unless reachable.
- **Judge hook** — PreToolUse deny/allow/escalate rules engine. Inert until `~/.claude/judge-rules.json` exists; run the `judge-setup` skill to opt in (writes CLAUDE.md guidance, seeds rules from the example, registers the user-scope hook). Eval suite in `plugins/skylence/hooks/judge-eval/`.
- **judge-design skills** — action-surface-audit, judge-criteria, judge-prompt-writer, judge-eval-suite, judge-architecture-review.
- **SessionStart steer** — prefers skyline MCP tools over built-in file tools; offers the skyline daemon setup once (declines are remembered).

## License

MIT — see [LICENSE](LICENSE).