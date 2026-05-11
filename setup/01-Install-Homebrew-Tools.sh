#!/usr/bin/env bash
# =============================================================================
# Nexus Automation — macOS Tool Installer
# Run this FIRST, in a standard Terminal (bash or zsh).
# After this completes, open a NEW terminal tab before running step 02.
#
# Tested: macOS 26.x, Apple Silicon (arm64)
# =============================================================================

set -e  # exit on first error

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # no color

header() { echo -e "\n${CYAN}── $1 ──${NC}"; }
ok()     { echo -e "${GREEN}[OK]${NC}  $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()   { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

echo ""
echo "Nexus Automation — Environment Setup (macOS Apple Silicon)"
echo "============================================================"

# ── Architecture check ────────────────────────────────────────────────────────
header "Architecture check"
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    ok "Apple Silicon (arm64) detected"
elif [ "$ARCH" = "x86_64" ]; then
    warn "Intel x86_64 detected — most steps work, but paths may differ"
    warn "Homebrew will be at /usr/local instead of /opt/homebrew"
else
    fail "Unknown architecture: $ARCH"
fi

# ── macOS version ─────────────────────────────────────────────────────────────
MACOS_VER=$(sw_vers -productVersion)
ok "macOS $MACOS_VER"

# ── Homebrew ──────────────────────────────────────────────────────────────────
header "Homebrew"
if command -v brew &>/dev/null; then
    ok "Homebrew already installed ($(brew --version | head -1))"
else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for this session (Apple Silicon path)
    if [ "$ARCH" = "arm64" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        # Add to shell profile if not already there
        if ! grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            ok "Added Homebrew to ~/.zprofile"
        fi
    fi
    ok "Homebrew installed"
fi

# ── PowerShell ────────────────────────────────────────────────────────────────
header "PowerShell 7.x"
if command -v pwsh &>/dev/null; then
    ok "PowerShell already installed ($(pwsh --version))"
else
    echo "Installing PowerShell (this also installs .NET and icu4c)..."
    # NOTE: 'brew install --cask powershell' does NOT work — cask was removed.
    # Use the formula: 'brew install powershell'
    brew install powershell
    ok "PowerShell installed ($(pwsh --version))"
fi

# ── .NET SDK (installed as PowerShell dependency, verify it's accessible) ────
header ".NET SDK"
if command -v dotnet &>/dev/null; then
    ok ".NET SDK ($(dotnet --version))"
else
    warn ".NET not found on PATH — may need to add Homebrew to PATH"
    warn "Run: eval \"\$(/opt/homebrew/bin/brew shellenv)\" and retry"
fi

# ── PAC CLI ───────────────────────────────────────────────────────────────────
header "PAC CLI (Power Platform)"

# DOTNET_ROOT must point to Homebrew's .NET location for PAC CLI to run.
# This is the Apple Silicon Homebrew path.
DOTNET_ROOT_PATH="/opt/homebrew/opt/dotnet/libexec"
export DOTNET_ROOT="$DOTNET_ROOT_PATH"
export PATH="$PATH:$HOME/.dotnet/tools"

# Check if already installed
if command -v pac &>/dev/null 2>&1; then
    PAC_VER=$(pac help 2>&1 | grep "^Version:" | head -1)
    ok "PAC CLI already installed ($PAC_VER)"
else
    echo "Installing PAC CLI as a .NET global tool..."
    # NOTE: 'npm install -g @microsoft/powerplatform-cli' returns 404 — wrong package name.
    # PAC CLI is a .NET tool, not an npm package.
    # Pin to 1.33.5 — versions 2.x crash on macOS ARM (WAM broker NullRef bug).
    dotnet tool install --global Microsoft.PowerApps.CLI.Tool --version 1.33.5
    ok "PAC CLI installed"
fi

# Verify PAC CLI runs (it needs DOTNET_ROOT)
PAC_CHECK=$(DOTNET_ROOT="$DOTNET_ROOT_PATH" PATH="$PATH:$HOME/.dotnet/tools" pac help 2>&1 | head -1)
if echo "$PAC_CHECK" | grep -q "Microsoft PowerPlatform CLI"; then
    ok "PAC CLI functional"
else
    warn "PAC CLI may not be working. Check DOTNET_ROOT. Details: $PAC_CHECK"
fi

# ── Shell profile — persist DOTNET_ROOT and PATH ─────────────────────────────
header "Shell profile (~/.zshrc)"

PROFILE="$HOME/.zshrc"
MARKER="# PAC CLI (Power Platform) — required for Nexus automation scripts"

if grep -q "$MARKER" "$PROFILE" 2>/dev/null; then
    ok "DOTNET_ROOT already configured in $PROFILE"
else
    cat >> "$PROFILE" << EOF

$MARKER
export DOTNET_ROOT="$DOTNET_ROOT_PATH"
export PATH="\$PATH:\$HOME/.dotnet/tools"
EOF
    ok "Added DOTNET_ROOT and PATH to $PROFILE"
    echo "   NOTE: Run 'source ~/.zshrc' or open a new terminal before using pac."
fi

# ── Node.js (optional — kept for future npm tooling) ─────────────────────────
header "Node.js (optional)"
if command -v node &>/dev/null; then
    ok "Node.js already installed ($(node --version))"
else
    echo "Installing Node.js..."
    brew install node
    ok "Node.js installed ($(node --version))"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo -e "${GREEN}Step 1 complete.${NC}"
echo ""
echo "Next steps:"
echo "  1. Open a NEW terminal tab (to pick up ~/.zshrc changes)"
echo "  2. Run:  pwsh setup/02-Install-PSModules.ps1"
echo "  3. Run:  pwsh setup/03-Verify-Setup.ps1"
echo ""
