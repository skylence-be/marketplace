# LSP Servers

The `skylence` plugin bundles 13 LSP servers via `plugins/skylence/.lsp.json`.

You don't need all 13. Each server only activates when its binary is on PATH — if `gopls` is missing, the Go entry just doesn't start. No error, no breakage. Only the languages you have toolchains for light up.

| Server | Binary needed on PATH | Extensions | Install |
|--------|----------------------|------------|---------|
| `sky-workflow` | `sky` | `.sky` | Skylence release |
| `clangd` | `clangd` | `.c .h .cpp .cc .cxx .hpp .hxx` | `brew install llvm` / Xcode CLT |
| `csharp-ls` | `csharp-ls` | `.cs` | `dotnet tool install -g csharp-ls` |
| `gopls` | `gopls` | `.go` | `go install golang.org/x/tools/gopls@latest` |
| `jdtls` | `jdtls` | `.java` | [Eclipse JDT.LS](https://github.com/eclipse-jdtls/eclipse.jdt.ls) |
| `kotlin-lsp` | `kotlin-lsp` | `.kt .kts` | [JetBrains kotlin-lsp](https://github.com/Kotlin/kotlin-lsp) |
| `lua` | `lua-language-server` | `.lua` | `brew install lua-language-server` |
| `intelephense` | `intelephense` | `.php` | `npm i -g intelephense` |
| `pyright` | `pyright-langserver` | `.py .pyi` | `npm i -g pyright` |
| `ruby-lsp` | `ruby-lsp` | `.rb .rake .gemspec .ru .erb` | `gem install ruby-lsp` |
| `rust-analyzer` | `rust-analyzer` | `.rs` | `rustup component add rust-analyzer` |
| `sourcekit-lsp` | `sourcekit-lsp` | `.swift` | ships with Xcode |
| `typescript` | `typescript-language-server` | `.ts .tsx .js .jsx .mts .cts .mjs .cjs` | `npm i -g typescript-language-server typescript` |

The 12 language servers are the official Claude Code LSP plugin definitions from [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official), copied verbatim (including the 120s `startupTimeout` on jdtls and kotlin-lsp).