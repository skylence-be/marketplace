# Skylence Marketplace

A [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin marketplace. One plugin: **skylence**.

## Install

```
/plugin marketplace add skylence-be/claude-code-marketplace
/plugin install skylence@skylence-marketplace
```

## Plugin: `skylence`

Author, run, lint, and debug `.sky` workflows for the Skylence harness builder.

- **1 agent** — `skylence-workflow-author`
- **4 slash commands** — `/skylence-workflow-new`, `/skylence-run`, `/skylence-lint`, `/skylence-doctor`
- **5 skills** — four-delimiter `.sky` format, sky CLI reference, debugging runs, MUST/MUST NOT rules, meta-workflows catalogue
- **5 MCP servers** — bundled via `.mcp.json`: `sky mcp stdio` plus HTTP endpoints for skylence-content (`mcp.skylence.be`), skyline (`:7333`), skyway (`:3090`), and skybox (`:7070`)
- **13 LSP servers** — bundled via `.lsp.json`: `sky lsp stdio` for `.sky` files plus the official Claude Code language servers (clangd, csharp-ls, gopls, jdtls, kotlin-lsp, lua, intelephense, pyright, ruby-lsp, rust-analyzer, sourcekit-lsp, typescript). Per-server binaries and install commands: [docs/lsp-servers.md](docs/lsp-servers.md)

**Prerequisite:** the `sky` binary on PATH.

## License

MIT — see [LICENSE](LICENSE).