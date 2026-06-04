#!/usr/bin/env bash
# lsp-install.sh — deterministic installer for the LSP server binaries bundled
# in the skylence plugin's .lsp.json.
#
# Usage:
#   lsp-install.sh list                 # show languages, binaries, and install strategy
#   lsp-install.sh install <language>   # install the LSP binary for <language>
#
# Behavior contract:
#   - Detects macOS / Linux / Windows (Git Bash, MSYS, Cygwin).
#   - Checks the required package manager (brew, npm/node, go, dotnet, rustup,
#     gem, winget) BEFORE installing. If it is missing, prints what to install
#     and exits 1. It never installs a package manager itself and never sudos.
#   - If the binary is already on PATH, reports it and exits 0.
set -euo pipefail

case "$(uname -s)" in
  Darwin)                OS=macos ;;
  Linux)                 OS=linux ;;
  MINGW*|MSYS*|CYGWIN*)  OS=windows ;;
  *)                     OS=unknown ;;
esac

have() { command -v "$1" >/dev/null 2>&1; }

fail() { printf 'STOP: %s\n' "$*" >&2; exit 1; }

# require <manager> <how-to-get-it>
require() {
  have "$1" || fail "'$1' is not installed. $2"
}

done_msg() {
  hash -r 2>/dev/null || true
  if have "$1"; then
    printf 'OK: %s installed (%s)\n' "$1" "$(command -v "$1")"
  else
    printf 'WARN: install ran but %s is not on PATH yet. %s\n' "$1" "${2:-Open a new shell or fix PATH.}"
  fi
}

NODE_HINT="Install Node.js first: https://nodejs.org (macOS: 'brew install node')."
BREW_HINT="Install Homebrew first: https://brew.sh"
WINGET_HINT="winget ships with Windows 11 / App Installer from the Microsoft Store."

list() {
  cat <<'EOF'
language    binary                      strategy
--------    ------                      --------
cpp         clangd                      macOS: Xcode CLT or brew llvm | Linux: brew llvm | Windows: winget LLVM.LLVM
csharp      csharp-ls                   dotnet tool install --global csharp-ls
go          gopls                       go install golang.org/x/tools/gopls@latest
java        jdtls                       brew install jdtls
kotlin      kotlin-lsp                  brew install kotlin-lsp
lua         lua-language-server         brew install lua-language-server
php         intelephense                npm install -g intelephense
python      pyright-langserver          npm install -g pyright
ruby        ruby-lsp                    gem install ruby-lsp
rust        rust-analyzer               rustup component add rust-analyzer
swift       sourcekit-lsp               ships with Xcode (macOS) / Swift toolchain (Linux)
typescript  typescript-language-server  npm install -g typescript-language-server typescript
skyway      skyway                      Skylence release (https://github.com/skylence-be/skyway)
EOF
}

npm_install() { # npm_install <binary> <pkg...>
  local bin="$1"; shift
  have "$bin" && { done_msg "$bin"; return; }
  require node "$NODE_HINT"
  require npm  "$NODE_HINT"
  npm install -g "$@"
  done_msg "$bin" "Check 'npm prefix -g'/bin is on PATH."
}

brew_install() { # brew_install <binary> <formula>
  local bin="$1" formula="$2"
  have "$bin" && { done_msg "$bin"; return; }
  [ "$OS" = windows ] && fail "no Homebrew on Windows; install '$formula' manually for your platform."
  require brew "$BREW_HINT"
  brew install "$formula"
  done_msg "$bin"
}

install_lang() {
  case "$1" in
    php)        npm_install intelephense intelephense ;;
    python|py)  npm_install pyright-langserver pyright ;;
    typescript|ts|javascript|js)
                npm_install typescript-language-server typescript-language-server typescript ;;
    go|golang)
      have gopls && { done_msg gopls; return; }
      require go "Install Go first: https://go.dev/dl (macOS: 'brew install go')."
      go install golang.org/x/tools/gopls@latest
      done_msg gopls "Add \$(go env GOPATH)/bin to PATH."
      ;;
    csharp|cs)
      have csharp-ls && { done_msg csharp-ls; return; }
      require dotnet "Install the .NET SDK first: https://dotnet.microsoft.com/download"
      dotnet tool install --global csharp-ls
      done_msg csharp-ls "Add ~/.dotnet/tools to PATH."
      ;;
    rust)
      have rust-analyzer && { done_msg rust-analyzer; return; }
      require rustup "Install Rust first: https://rustup.rs"
      rustup component add rust-analyzer
      done_msg rust-analyzer
      ;;
    ruby|rb)
      have ruby-lsp && { done_msg ruby-lsp; return; }
      require gem "Install Ruby first: https://www.ruby-lang.org (macOS: 'brew install ruby')."
      gem install ruby-lsp
      done_msg ruby-lsp
      ;;
    cpp|c|c++)
      have clangd && { done_msg clangd; return; }
      case "$OS" in
        macos)
          if have brew; then
            brew install llvm
            printf 'NOTE: brew llvm is keg-only. Add to PATH: %s/bin\n' "$(brew --prefix llvm)"
          else
            fail "clangd not found. Either install Xcode Command Line Tools ('xcode-select --install', includes clangd) or Homebrew ($BREW_HINT)."
          fi
          ;;
        linux)
          if have brew; then
            brew install llvm
            printf 'NOTE: brew llvm is keg-only. Add to PATH: %s/bin\n' "$(brew --prefix llvm)"
          else
            fail "clangd not found and no Homebrew. Use your distro's package manager, e.g. 'sudo apt-get install clangd' or 'sudo dnf install clang-tools-extra' (not run automatically; needs sudo)."
          fi
          ;;
        windows)
          require winget "$WINGET_HINT"
          winget install -e --id LLVM.LLVM
          done_msg clangd "LLVM's bin directory may need adding to PATH."
          ;;
        *) fail "unsupported OS for cpp." ;;
      esac
      ;;
    java)       brew_install jdtls jdtls ;;
    kotlin|kt)  brew_install kotlin-lsp kotlin-lsp ;;
    lua)        brew_install lua-language-server lua-language-server ;;
    swift)
      have sourcekit-lsp && { done_msg sourcekit-lsp; return; }
      case "$OS" in
        macos) fail "sourcekit-lsp ships with Xcode / the Command Line Tools. Run 'xcode-select --install'." ;;
        linux) fail "sourcekit-lsp ships with the Swift toolchain. Install Swift: https://www.swift.org/install/linux/" ;;
        *)     fail "install the Swift toolchain: https://www.swift.org/install/" ;;
      esac
      ;;
    skyway|sky)
      have skyway && { done_msg skyway; return; }
      fail "the skyway binary is distributed via Skylence releases: https://github.com/skylence-be/skyway"
      ;;
    *)
      printf 'unknown language: %s\n\n' "$1" >&2
      list >&2
      exit 1
      ;;
  esac
}

cmd="${1:-}"
case "$cmd" in
  list)    list ;;
  install)
    [ $# -ge 2 ] || { printf 'usage: lsp-install.sh install <language>\n\n' >&2; list >&2; exit 1; }
    install_lang "$2"
    ;;
  *)
    printf 'usage: lsp-install.sh list | install <language>\n\n' >&2
    list >&2
    exit 1
    ;;
esac