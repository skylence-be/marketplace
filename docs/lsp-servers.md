# LSP Servers

The `skylence` plugin bundles 13 LSP servers via `plugins/skylence/.lsp.json`.

You don't need all 13. Each server only activates when its binary is on PATH — if `gopls` is missing, the Go entry just doesn't start. No error, no breakage. Only the languages you have toolchains for light up.

Install any of them with `/lsp install <language>` (e.g. `/lsp install php`). The bundled installer (`plugins/skylence/scripts/lsp-install.sh`) detects your OS, checks the required package manager first, and stops with instructions if it's missing. `/lsp list` shows the full matrix.

| Language | Server name | Binary needed on PATH | Extensions | Install |
|----------|-------------|----------------------|------------|---------|
| Sky workflows | `skyway` | `skyway` | `.sky` | Skylence release |
| C / C++ | `cpp-lsp` | `clangd` | `.c .h .cpp .cc .cxx .hpp .hxx` | `brew install llvm` / Xcode CLT |
| C# | `csharp-lsp` | `csharp-ls` | `.cs` | `dotnet tool install -g csharp-ls` |
| Go | `go-lsp` | `gopls` | `.go` | `go install golang.org/x/tools/gopls@latest` |
| Java | `java-lsp` | `jdtls` | `.java` | [Eclipse JDT.LS](https://github.com/eclipse-jdtls/eclipse.jdt.ls) |
| Kotlin | `kotlin-lsp` | `kotlin-lsp` | `.kt .kts` | [JetBrains kotlin-lsp](https://github.com/Kotlin/kotlin-lsp) |
| Lua | `lua-lsp` | `lua-language-server` | `.lua` | `brew install lua-language-server` |
| PHP | `php-lsp` | `intelephense` | `.php` | `npm i -g intelephense` |
| Python | `python-lsp` | `pyright-langserver` | `.py .pyi` | `npm i -g pyright` |
| Ruby | `ruby-lsp` | `ruby-lsp` | `.rb .rake .gemspec .ru .erb` | `gem install ruby-lsp` |
| Rust | `rust-lsp` | `rust-analyzer` | `.rs` | `rustup component add rust-analyzer` |
| Swift | `swift-lsp` | `sourcekit-lsp` | `.swift` | ships with Xcode |
| TypeScript / JavaScript | `typescript-lsp` | `typescript-language-server` | `.ts .tsx .js .jsx .mts .cts .mjs .cjs` | `npm i -g typescript-language-server typescript` |

The 12 language servers are the official Claude Code LSP plugin definitions from [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) — same commands, args, and timeouts (including the 120s `startupTimeout` on the Java and Kotlin servers), renamed to `<language>-lsp` keys.