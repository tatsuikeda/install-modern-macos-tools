#!/usr/bin/env bash
#
# install-modern-tools.sh
#
# Installs modern versions of tools that Apple ships outdated due to
# GPLv3 licensing or other reasons, then configures PATH so they
# take priority over the system versions.
#
# Run: bash install-modern-tools.sh
# Idempotent: safe to run multiple times.

set -euo pipefail

# ──────────────────────────────────────────────────────────────────
# Preflight
# ──────────────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: this script is for macOS only."
  exit 1
fi

if ! command -v brew &>/dev/null; then
  echo "Homebrew not found. Install it first: https://brew.sh"
  exit 1
fi

BREW_PREFIX="$(brew --prefix)"

echo "==> Installing modern replacements for Apple's outdated tools..."
echo "    Homebrew prefix: ${BREW_PREFIX}"
echo ""

# ──────────────────────────────────────────────────────────────────
# Fix common permissions issues before installing
# ──────────────────────────────────────────────────────────────────
# After macOS upgrades, /usr/local/share/man subdirs can end up owned
# by root, which causes "brew link" to fail for packages that install
# man pages (vim, git, etc.). Fix ownership preemptively.

if [[ -d "${BREW_PREFIX}/share/man" ]]; then
  MAN_OWNER="$(stat -f '%u' "${BREW_PREFIX}/share/man")"
  CURRENT_UID="$(id -u)"
  if [[ "$MAN_OWNER" != "$CURRENT_UID" ]]; then
    echo "==> Fixing ${BREW_PREFIX}/share/man ownership (needs sudo)..."
    sudo chown -R "$(whoami)" "${BREW_PREFIX}/share/man"
  fi
fi

# ──────────────────────────────────────────────────────────────────
# Install packages
# ──────────────────────────────────────────────────────────────────
# brew install is idempotent: already-installed packages are skipped.
# Errors for individual packages are caught so the script continues.

PACKAGES=(
  # ── Shell ──
  # Bash: Apple ships 3.2.57 (2007, last GPLv2). Modern: 5.x (GPLv3)
  bash

  # ── GNU coreutils, findutils, and friends ──
  # coreutils: ls, cp, mv, cat, date, sort, cut, head, tail, wc, etc.
  # Apple ships BSD variants; GNU versions have more flags and features.
  coreutils

  # findutils: find, xargs, locate.
  # Apple ships ancient GNU find 4.2.33 (2006).
  findutils

  # GNU sed: Apple ships BSD sed (different -i syntax, fewer features)
  gnu-sed

  # GNU grep: Apple ships BSD grep (no PCRE via -P, fewer features)
  grep

  # GNU awk (gawk): Apple ships BWK awk (one true awk)
  gawk

  # GNU tar: Apple ships bsdtar
  gnu-tar

  # diffutils: Apple ships old BSD diff
  diffutils

  # GNU which: Apple ships a shell builtin / BSD which
  gnu-which

  # ── Build tools ──
  # make: Apple ships 3.81 (2006, last GPLv2). Modern: 4.x (GPLv3)
  make

  # ── Other stale tools ──
  # rsync: Apple ships 2.6.9 (2006). Modern: 3.x
  rsync

  # less: Apple ships older less
  less

  # nano: Apple ships 2.0.6 (2007). Modern: 7.x+
  nano

  # screen: Apple ships 4.0.3 (2006)
  screen

  # curl: Apple ships older LibreSSL-linked curl; brew gives OpenSSL + latest
  curl

  # vim: Apple ships old "vi" with minimal features
  vim

  # git: Xcode git lags behind upstream
  git

  # openssh: Apple ships a patched fork, often behind on features
  openssh

  # gzip: Apple ships old gzip
  gzip

  # zip/unzip: Apple's are ancient
  zip
  unzip

  # GNU indent: not shipped anymore
  gnu-indent

  # GNU getopt: Apple ships BSD getopt (no long options)
  gnu-getopt

  # ── Extras (not GPL-frozen but commonly wanted) ──
  # wget: Apple doesn't ship it at all
  wget
)

for pkg in "${PACKAGES[@]}"; do
  echo "==> Installing ${pkg}..."
  if ! brew install "$pkg" 2>&1; then
    echo "    Warning: ${pkg} had an issue, continuing..."
  fi
done

echo ""
echo "==> All packages installed."

# ──────────────────────────────────────────────────────────────────
# Re-link packages that commonly fail due to permissions
# ──────────────────────────────────────────────────────────────────
for pkg in vim git nano; do
  if brew list --formula "$pkg" &>/dev/null; then
    brew link --overwrite "$pkg" 2>/dev/null || true
  fi
done

echo ""

# ──────────────────────────────────────────────────────────────────
# PATH configuration
# ──────────────────────────────────────────────────────────────────
# Brew installs GNU tools with a "g" prefix by default (ggrep, gsed,
# etc.). To use them unprefixed, their gnubin dirs go first in PATH.

read -r -d '' PATH_BLOCK << PATHEOF || true
# ── Modern GNU tools (installed by install-modern-tools.sh) ──
# Puts brew-installed GNU tools ahead of Apple system versions.
export PATH="${BREW_PREFIX}/opt/coreutils/libexec/gnubin:\$PATH"
export PATH="${BREW_PREFIX}/opt/findutils/libexec/gnubin:\$PATH"
export PATH="${BREW_PREFIX}/opt/gnu-sed/libexec/gnubin:\$PATH"
export PATH="${BREW_PREFIX}/opt/grep/libexec/gnubin:\$PATH"
export PATH="${BREW_PREFIX}/opt/gawk/libexec/gnubin:\$PATH"
export PATH="${BREW_PREFIX}/opt/gnu-tar/libexec/gnubin:\$PATH"
export PATH="${BREW_PREFIX}/opt/diffutils/libexec/gnubin:\$PATH"
export PATH="${BREW_PREFIX}/opt/gnu-which/libexec/gnubin:\$PATH"
export PATH="${BREW_PREFIX}/opt/make/libexec/gnubin:\$PATH"
export PATH="${BREW_PREFIX}/opt/gnu-indent/libexec/gnubin:\$PATH"
export PATH="${BREW_PREFIX}/opt/gnu-getopt/bin:\$PATH"
export PATH="${BREW_PREFIX}/opt/curl/bin:\$PATH"
export PATH="${BREW_PREFIX}/opt/openssh/bin:\$PATH"
export PATH="${BREW_PREFIX}/opt/rsync/bin:\$PATH"
export PATH="${BREW_PREFIX}/opt/unzip/bin:\$PATH"
export PATH="${BREW_PREFIX}/opt/zip/bin:\$PATH"
export PATH="${BREW_PREFIX}/opt/gzip/bin:\$PATH"

export MANPATH="${BREW_PREFIX}/opt/coreutils/libexec/gnuman:\${MANPATH:-}"
export MANPATH="${BREW_PREFIX}/opt/findutils/libexec/gnuman:\${MANPATH:-}"
export MANPATH="${BREW_PREFIX}/opt/gnu-sed/libexec/gnuman:\${MANPATH:-}"
export MANPATH="${BREW_PREFIX}/opt/grep/libexec/gnuman:\${MANPATH:-}"
export MANPATH="${BREW_PREFIX}/opt/gnu-tar/libexec/gnuman:\${MANPATH:-}"
export MANPATH="${BREW_PREFIX}/opt/make/libexec/gnuman:\${MANPATH:-}"
# ── End modern GNU tools ──
PATHEOF

MARKER="# ── Modern GNU tools (installed by install-modern-tools.sh) ──"

# ──────────────────────────────────────────────────────────────────
# Write PATH block to all relevant shell rc files
# ──────────────────────────────────────────────────────────────────
# Both zsh and bash users get the PATH block. On macOS, zsh is the
# default since Catalina, but plenty of people still use bash.

RC_FILES=()

# zsh: always write if .zshrc exists or zsh is the login shell
if [[ -f "$HOME/.zshrc" ]] || [[ "${SHELL:-}" == */zsh ]]; then
  RC_FILES+=("$HOME/.zshrc")
fi

# bash: .bash_profile is loaded for login shells on macOS (Terminal.app
# and iTerm2 open login shells by default). .bashrc is loaded for
# non-login interactive shells. Write to whichever exists, preferring
# .bash_profile. If the user has both, write to both.
if [[ -f "$HOME/.bash_profile" ]]; then
  RC_FILES+=("$HOME/.bash_profile")
fi
if [[ -f "$HOME/.bashrc" ]]; then
  RC_FILES+=("$HOME/.bashrc")
fi

# Fallback: if nothing matched, create .zshrc (macOS default since Catalina)
if [[ ${#RC_FILES[@]} -eq 0 ]]; then
  RC_FILES+=("$HOME/.zshrc")
fi

# Deduplicate
declare -A SEEN_RC
UNIQUE_RC=()
for rc in "${RC_FILES[@]}"; do
  if [[ -z "${SEEN_RC[$rc]:-}" ]]; then
    SEEN_RC[$rc]=1
    UNIQUE_RC+=("$rc")
  fi
done

for rc in "${UNIQUE_RC[@]}"; do
  if grep -qF "$MARKER" "$rc" 2>/dev/null; then
    echo "==> PATH block already present in $rc, skipping."
  else
    touch "$rc"
    printf '\n%s\n' "$PATH_BLOCK" >> "$rc"
    echo "==> PATH block added to $rc"
  fi
done

# ──────────────────────────────────────────────────────────────────
# Add modern bash to /etc/shells and optionally set as default
# ──────────────────────────────────────────────────────────────────
BREW_BASH="${BREW_PREFIX}/bin/bash"

if [[ -x "$BREW_BASH" ]]; then
  if ! grep -qF "$BREW_BASH" /etc/shells 2>/dev/null; then
    echo "==> Adding $BREW_BASH to /etc/shells (needs sudo)..."
    echo "$BREW_BASH" | sudo tee -a /etc/shells >/dev/null
  fi

  echo ""
  read -rp "Set Bash 5 ($BREW_BASH) as your default shell? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    chsh -s "$BREW_BASH"
    echo "==> Default shell changed to $BREW_BASH"
  else
    echo "==> Skipped. Change it later with: chsh -s $BREW_BASH"
  fi
fi

# ──────────────────────────────────────────────────────────────────
# Done
# ──────────────────────────────────────────────────────────────────
echo ""
echo "==> Done. Open a new terminal or run:"
for rc in "${UNIQUE_RC[@]}"; do
  echo "    source $rc"
done
echo ""
echo "Verify with:"
echo "  bash --version   # should say 5.x"
echo "  grep --version   # should say GNU grep"
echo "  sed --version    # should say GNU sed"
echo "  make --version   # should say GNU Make 4.x"
echo "  find --version   # should say GNU findutils"
echo "  awk --version    # should say GNU Awk"
