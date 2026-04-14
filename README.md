# install-modern-macos-tools

One script to replace every outdated tool that Apple ships on macOS.

## Why

In 2007, the GNU project moved most of their tools from GPLv2 to GPLv3. The new license includes an anti-Tivoization clause that requires distributors to let users install modified versions of the software on their hardware. Apple's platform control strategy (code signing, secure boot, locked-down devices) is fundamentally incompatible with this requirement.

Apple's solution: freeze every GNU tool at its last GPLv2 version and never update again. Some tools were replaced with BSD equivalents, others were simply left to rot. The result is that a stock macOS install ships coreutils, bash, make, grep, sed, and dozens of other tools that are 15 to 20 years out of date.

This script installs modern versions of all of them via Homebrew and configures your PATH so they take priority.

## What gets installed

### GPL-frozen (stuck at last GPLv2 versions)

| Tool | Apple ships | You get |
|------|------------|---------|
| bash | 3.2.57 (2007) | 5.x |
| make | 3.81 (2006) | 4.x |
| coreutils (ls, cp, mv, cat, sort, etc.) | BSD variants | GNU coreutils |
| findutils (find, xargs, locate) | 4.2.33 (2006) | GNU findutils |
| sed | BSD sed | GNU sed |
| grep | BSD grep | GNU grep (with PCRE) |
| awk | BWK awk | GNU awk (gawk) |
| tar | bsdtar | GNU tar |
| diffutils | BSD diff | GNU diffutils |
| which | BSD which | GNU which |
| screen | 4.0.3 (2006) | 5.x |
| nano | 2.0.6 (2007) | 9.x |
| gnu-indent | removed | GNU indent |
| gnu-getopt | BSD getopt (no long opts) | GNU getopt |

### Stale for other reasons

| Tool | Apple ships | You get |
|------|------------|---------|
| rsync | 2.6.9 (2006) | 3.x |
| curl | old, LibreSSL-linked | latest, OpenSSL-linked (not added to PATH*) |
| vim | old vi | Vim 9.x |
| git | Xcode git (lags behind) | latest upstream |
| openssh | Apple's patched fork | upstream OpenSSH (not added to PATH*) |
| gzip | old | latest |
| zip / unzip | ancient | latest |

*\*curl and openssh are installed but not added to PATH. Brew curl uses OpenSSL instead of macOS SecureTransport, which breaks tools relying on system certificate handling. Brew openssh lacks macOS Keychain integration. Use them explicitly via `$(brew --prefix)/opt/curl/bin/curl` and `$(brew --prefix)/opt/openssh/bin/ssh`.*

### Extras

| Tool | Notes |
|------|-------|
| wget | Apple doesn't ship it at all |
| gh | GitHub CLI for PRs, issues, and repo management |

## Install

```bash
git clone https://github.com/tatsuikeda/install-modern-macos-tools.git
cd install-modern-macos-tools
bash install-modern-tools.sh
```

Or just run it directly:

```bash
curl -fsSL https://raw.githubusercontent.com/tatsuikeda/install-modern-macos-tools/main/install-modern-tools.sh | bash
```

### What the script does

1. Installs all packages via `brew install` (idempotent, skips what you already have)
2. Fixes `/usr/local/share/man` ownership if needed (common post-macOS-upgrade issue)
3. Re-links packages that failed due to permissions (vim, git, nano)
4. Adds a PATH block to your shell rc files so GNU tools take priority over system versions
5. Registers Bash 5 in `/etc/shells` and optionally sets it as your default shell

The script detects your shell and writes to the right config files:
- **zsh users**: `~/.zshrc`
- **bash users**: `~/.bash_profile` and/or `~/.bashrc`
- **both**: writes to all that exist

Safe to run multiple times. The PATH block is only added once per file.

## Verify

After opening a new terminal:

```bash
bash --version   # GNU bash 5.x
grep --version   # GNU grep
sed --version    # GNU sed
make --version   # GNU Make 4.x
find --version   # GNU findutils
awk --version    # GNU Awk
```

## Requirements

- macOS
- [Homebrew](https://brew.sh)

## License

MIT
