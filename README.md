# Skylence Marketplace

Claude Code plugin marketplace. One plugin: **skylence** — author, run, lint, and debug `.sky` workflows.

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

## License

MIT — see [LICENSE](LICENSE).