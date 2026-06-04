---
description: Install LSP server binaries for the skylence plugin (OS-aware, deterministic)
argument-hint: install <language> | list
allowed-tools: Bash
---

# /lsp — install LSP server binaries

Run the bundled installer script with the user's arguments:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/lsp-install.sh" $ARGUMENTS
```

The script is the single source of truth. It:

1. Detects the OS (macOS / Linux / Windows via Git Bash).
2. Checks the required package manager for the language (npm/node, Homebrew, go, dotnet, rustup, gem, winget) **before** installing.
3. Stops with a `STOP:` line if the package manager is missing — it never installs package managers and never runs sudo.
4. Skips installation if the binary is already on PATH (`OK:` line).

## Rules

- Run the script exactly as shown. Do NOT improvise alternative install commands when the script stops — relay the `STOP:` message to the user; it names exactly what they must install first.
- If no arguments were given, run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/lsp-install.sh" list` and show the table.
- If the script prints a `NOTE:` or `WARN:` about PATH, surface it verbatim — the user must act on it before the LSP server will start.
- After a successful install, mention that the LSP server activates on next session start (or `/reload-plugins`).

## Supported languages

`php`, `python`, `typescript` (npm) · `go` (go) · `csharp` (dotnet) · `rust` (rustup) · `ruby` (gem) · `cpp`, `java`, `kotlin`, `lua` (brew; cpp also winget on Windows) · `swift` (Xcode / Swift toolchain) · `skyway` (Skylence release)