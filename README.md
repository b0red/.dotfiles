# Dotfiles Configuration

A comprehensive, cross-platform dotfiles setup with modular bash configuration, visual loading feedback, universal package management, and automated installation.

> **Repository**: Canonical on GitHub at `git@github.com:b0red/.dotfiles.git`, checked out into `~/.dotfiles`.

---

## Features

- **Modular Configuration**: Split into logical files in `.bashrc.d/` with smart loading
- **Visual Loading Feedback**: See each file load with color-coded progress indicators
- **Universal Package Management**: Unified `p_install`, `install`, `update`, `upgrade` commands across all distros
- **Smart Prompt**: Color-coded by privilege level (green for users, red for root)
- **Intelligent Backups**: Only backs up changed files, keeps pristine originals forever
- **Automatic Cleanup**: Keeps only 3 most recent backup archives
- **Re-runnable**: Safe to run multiple times, skips unchanged files
- **Comprehensive Logging**: Timestamped logs with color-coded output
- **One-Command Setup**: `./run_me_first.sh` does everything
- **Cross-Platform**: Supports Debian, Ubuntu, RHEL, Fedora, Arch, Gentoo, Alpine, Void, FreeBSD, OpenBSD, macOS
- **Docker Integration**: Conditional loading — Docker shortcuts only appear when Docker is installed
- **Smart File Loading**: Core files load everywhere, interactive files only in interactive shells
- **Tmux Auto-Start**: New terminal windows automatically launch a configured tmux session via `~/.start_tmux.sh`

---

## Quick Start

```bash
# Clone the repository
git clone git@github.com:b0red/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the installer
./run_me_first.sh
```

The script will:
1. Detect your OS and distribution
2. Backup existing dotfiles to `~/.dotfiles/oldfiles/` (only if changed)
3. Create symlinks from `~/.bashrc`, `~/.profile`, etc. to repo files
4. Load package manager functions for your distro
5. Install essential applications from `.install_apps.inc`
6. Update git submodules (if any included)
7. Clone additional repos (`.tmux`, `.vim`)
8. Create archived backups (tar.gz)
9. Clean up old archives (keeps 3 most recent)
10. Log everything to `~/.dotfiles/logs/install-YYYY-MM-DD_HH-MM-SS.log`

---

## Installation Options

```bash
./run_me_first.sh                   # Normal installation
./run_me_first.sh --help            # Show help message
./run_me_first.sh --version         # Show version (v15.8.0)
./run_me_first.sh --revert          # Revert changes (restore backups)
./run_me_first.sh --select-apps      # Choose specific packages to install
./run_me_first.sh --skip-apps        # Skip package installation
./run_me_first.sh --debug           # Enable debug mode
./run_me_first.sh --trace           # Enable trace mode (set -x)
DEBUG=1 ./run_me_first.sh           # Debug with environment variable
TRACE_DEBUG=1 ./run_me_first.sh     # Trace with environment variable
```

> **Note:** `--notify-only` is not yet implemented. See [Known Issues / Migration TODOs](#known-issues--migration-todos).

---

## Recent Changes

### v15.8.0 (2026-06-21)
- **`run_me_first.sh` refactor**: Modularised into canonical Vibecoding v5.6 structure — `parse_args()`, `show_brief_help()`, `show_version()`, `show_info()`, `IFS`, `SCRIPT_DIR`, `VERSION_DATE` globals added; `main()` moved to canonical bottom position; dead `_clone_if_missing_UNUSED` (115 lines) removed; all Bitbucket URLs → GitHub
- **9 logical bug fixes in `run_me_first.sh`**:
  - `validate_installation()` always reported tmux/vim as unlinked — was checking `~/.tmux/.git` but both are symlinks to repo subtrees (no `.git`)
  - `check_mode()` never displayed `LAST_RUN` — `log_info()` prefixed ANSI codes onto the first line, breaking key=value parsing; fixed with `printf`
  - State file conflict — `update_installation_state()` and `mark_installation_complete()` wrote different key formats to the same file; merged into one function with all keys
  - `load_package_functions()` piped through `tee` — swallowed `set_package_aliases` exit code via `PIPESTATUS`; fixed with `PIPESTATUS[0]`
  - `setup_taskwarrior_config()` backed up `~/.taskrc` after copying to repo; reordered to backup-first
  - `install_apps_direct()` matched `ubuntu/redhat/fedora/centos/opensuse/manjaro` — `DISTRO_BASE` never contains those; corrected to `debian/rhel/suse/arch`
  - `revert_changes()` ran legacy glob restore unconditionally alongside manifest restore — moved to `else` branch
  - Symlink direction logged backwards in `symlink_dotfiles()` and `symlink_external_repos()`
  - `add_file_header()` only matched `RunMe.sh` header pattern; added `run_me_first.sh` to prevent duplicate headers on re-run
- **`.bashrc.d` bug fixes**:
  - `aliases.bash`: `ltree` and `myip` aliases shadowed the more capable functions in `functions.bash` — aliases removed
  - `docker.bash`: `lzd`/`lzj` self-referential alias definitions removed; `dkclean`/`dclean` unquoted container ID variables fixed with arrays + `command docker`; `docker_check()` redundant install check removed
  - `exports.bash`: `PAGER='most'` now falls back to `less` when `most` is not installed; `$(id -un)` and `$(uname -x)` separated from `export` declarations; 8 individual uname guards collapsed into one block
  - `env.bash`: Dead `color_prompt` variable removed
  - `logout.bash`: `~/.bash_logout_log` now rotated to last 50 lines on exit (`LOGOUT_LOG_MAX_LINES` variable)

### v15.7.1 (2026-06-20)
- **Tmux Auto-Start**: `.bashrc` now launches `~/.start_tmux.sh` automatically on first interactive login (guarded: interactive shell only, first load only, not already in tmux)
- **Bug Fixes**:
  - `colorcodes.bash`: `NC` was mapped to black (`\033[0;30m`) instead of reset (`\033[0m`) — text following colored output was invisible on dark terminals
  - `aliases.bash`: `list_extensions()` used double-quoted perl string — bash expanded `$1` before perl saw it, silently breaking capture group printing; fixed with single quotes
  - `aliases.bash`: `please` alias ran `$(fc -ln -1)` at definition time (shell startup), not at invocation time — converted to a function
  - `aliases.bash`: `ghost` alias embedded `$1` which is always empty in aliases — converted to a function
  - `aliases.bash`: `tm` alias had a trailing `\;` that passed an empty command to tmux — removed
  - `pkg_aliases.bash`: `set_package_aliases()` printed "Package functions configured for…" on every shell startup — silenced

### v15.7.0 (2026-05-11)
- **Enhanced Installer Options**: Added `--select-apps` for interactive package selection and `--skip-apps` to bypass package installation entirely
- **Improved Backup System**: Implemented manifest-backed backups for robust revert functionality with detailed change tracking
- **Repository Migration**: Updated all references to canonical Bitbucket repository (`git@bitbucket.org:b0red/dotfiles.git`)
- **Taskwarrior Integration**: Added automatic detection and setup of Taskwarrior configuration (`.taskrc`) if installed
- **Documentation Updates**: Refreshed help text, examples, and README with new features and options

### v15.6.0 (2026-05-06)
- Initial release with comprehensive dotfiles installer

---

## Files Modified by Installer

The installer creates these symlinks in your home directory. Your originals are backed up to `~/.dotfiles/oldfiles/` with timestamps before any change is made.

| Symlink | Points to |
|---------|-----------|
| `~/.bashrc` | `~/.dotfiles/.bashrc` |
| `~/.bash_profile` | `~/.dotfiles/.bash_profile` |
| `~/.profile` | `~/.dotfiles/.profile` |
| `~/.inputrc` | `~/.dotfiles/.inputrc` |
| `~/.tmux.conf` | `~/.tmux/.tmux.conf` |
| `~/.vimrc` | `~/.vim/.vimrc` |

---

## Script Output Key

Understanding the installer's output at a glance:

| Symbol | Color | Meaning |
|--------|-------|---------|
| `✔` | Green | Success — file backed up, symlink created, package installed |
| `⚠️` | Yellow | Warning — skipped unchanged file, missing optional dependency |
| `✗` | Red | Error — failed operation, missing required file, permission issue |
| `⏭️` | — | Skipped — file unchanged from repo version, no backup needed |

Example install run:
```
=========================================
Starting Dotfiles Installation
Version: v15.7.0 (2026-05-11)
=========================================
🎨 Color output enabled
Detected: OS=linux, Distro=ubuntu, Base=debian, Kernel=6.6.87, Arch=x86_64
✅ Package functions configured for debian
✔ Loaded 25 applications from .install_apps.inc

🔐 Checking sudo access...
✔ Sudo access verified

Backing up existing dotfiles...
⏭️  Skipping /home/user/.bashrc (unchanged from repo)
✔ Backed up: /home/user/.profile
Backed up 1 files to /home/user/.dotfiles/oldfiles/
```

---

## Visual Loading System

When you open a new shell or run `reload`, each config file loads with visual feedback:

```
✔ Loading: exports.bash
✔ Loading: env.bash
✔ Loading: functions.bash
✔ Loading: pkg_aliases.bash
✔ Loading: git.bash
✔ Loading: docker.bash      # Only if Docker is installed
✔ Loading: aliases.bash
✅ All dotfiles loaded
```

- Files appear in the upper-left corner with cursor positioning
- Green `✔` for success, Red `✗` for errors
- Screen clears before and after loading for a clean display

### Adjusting Loading Speed

Edit `BASHRC_LOAD_DELAY` in `~/.bashrc`:

```bash
BASHRC_LOAD_DELAY=.2     # Default (fast)
BASHRC_LOAD_DELAY=0.5    # More visible
BASHRC_LOAD_DELAY=1      # One second per file
BASHRC_LOAD_DELAY=2      # Slowest
```

---

## Color-Coded Prompt

The prompt automatically adjusts based on privilege level:

- **Green** — Normal user: `user@hostname:~/path$`
- **Red** — Root/privileged: `root@hostname:~/path#`

Checks EUID, USER, and LOGNAME to determine privilege.

---

## Directory Structure

```
~/.dotfiles/
├── .bashrc                 # Main bash config (tmux guard, recursion guard, SSH agent)
├── .bash_profile           # Login shell config (sources .bashrc, sets BASHRC_SKIP_IN_TMUX)
├── .profile                # POSIX shell config (loads .bashrc.d and .profile.d)
├── .bashrc.d/              # Modular bash configs
│   ├── Core Files (load everywhere — no interactive guard):
│   │   ├── exports.bash        # Environment variables, PATH, locale, history
│   │   ├── env.bash            # Shell options (shopt), settings
│   │   ├── functions.bash      # Utility functions
│   │   └── pkg_aliases.bash    # Cross-distro package manager abstraction
│   │
│   └── Interactive Files (guarded — interactive shells only):
│       ├── aliases.bash        # Command aliases + tmux behaviour controls
│       ├── extra_alias.bash    # Local aliases (gitignored — safe for customization)
│       ├── git.bash            # Git shortcuts (50+ aliases)
│       ├── docker.bash         # Docker shortcuts (conditional on Docker being installed)
│       ├── colorcodes.bash     # ANSI color code definitions
│       ├── variables.bash      # Custom variables
│       ├── profile.bash        # Login shell settings
│       └── logout.bash         # Exit handlers
│
├── .profile.d/             # POSIX shell modules (sourced by .bashrc and .profile)
│   ├── browser.sh
│   ├── pager.sh
│   ├── timezone.sh
│   └── welcome.sh          # Optional: fortune, rem, verse (if installed)
│
├── helpers/
│   └── debug.sh            # Standalone test script for pkg_aliases.bash (run manually)
│
├── .install_apps.inc       # Application list for run_me_first.sh
├── .gitignore              # Excludes: extra_alias.bash, local_alias.bash, logs, oldfiles
├── symlink.sh              # Distro-specific symlink helper (called by run_me_first.sh)
├── system_detector.sh      # Standalone POSIX system info reporter
├── run_me_first.sh         # Main installer script (v15.8.0)
├── oldfiles/               # Backup directory (pristine originals + archived old scripts)
├── logs/                   # Installation logs (gitignored)
│   └── install-*.log
└── README.md               # This file
```

---

## File Loading Architecture

### Core Files (No Guards — Load Everywhere)

These load in **both interactive and non-interactive contexts** (scripts, `run_me_first.sh`, cron):

| File | Purpose |
|------|---------|
| `exports.bash` | Environment variables, PATH, locale, history settings |
| `env.bash` | Shell options (`shopt`), completion |
| `functions.bash` | Utility functions available everywhere |
| `pkg_aliases.bash` | Package management `p_*` functions |

**Why no guards?** `run_me_first.sh` and other scripts need `p_install`, env vars, and utility functions to operate correctly.

### Interactive Files (With Guards — Interactive Only)

These only load when `[[ $- == *i* ]]`:

| File | Purpose |
|------|---------|
| `aliases.bash` | Convenience aliases, tmux behaviour toggles |
| `extra_alias.bash` | Your local aliases (gitignored) |
| `git.bash` | Git workflow shortcuts |
| `docker.bash` | Docker shortcuts (also checks if Docker is installed) |
| `colorcodes.bash` | ANSI color definitions |
| `variables.bash` | Custom variables |
| `profile.bash` | Login shell settings |
| `logout.bash` | Session cleanup |

**Why guards?** Aliases don't work in scripts. Convenience features add overhead in non-interactive contexts and can cause unexpected behaviour in automation.

### Conditional Loading: Docker

`docker.bash` uses two-stage loading:
1. Is Docker installed? If no — skip entirely
2. Is the shell interactive? If no — skip

Result: Docker shortcuts appear only when Docker is present and you're in an interactive session. No clutter otherwise.

### Function Export Pattern

```bash
# pkg_aliases.bash — works everywhere
p_install() { sudo apt-get install -y "$@"; }
export -f p_install

# Interactive alias (via ENABLE_SHORT_ALIASES=1)
alias install='p_install'
```

- `p_install` works in scripts ✔
- `p_install` works interactively ✔
- `install` works interactively ✔
- `install` does not shadow `/usr/bin/install` in scripts ✔

---

## Package Manager Commands

### Function-Based (Work Everywhere)

Use these in scripts and interactive shells:

```bash
p_install <pkg>      # Install package(s)
p_remove <pkg>       # Remove package(s)
p_uninstall <pkg>    # Alias for remove
p_purge <pkg>        # Purge including config (Debian)
p_update             # Refresh package lists
p_upgrade            # Install all updates
p_dist_upgrade       # Distribution upgrade (Debian/RHEL)
p_search <query>     # Search for packages
p_clean              # Remove orphans & cache
p_info <pkg>         # Show package details
p_list [<pkg>]       # List packages
p_installed          # Show all installed packages
p_which <file>       # Find which package owns a file
```

> **In scripts: always use `p_install`, not `install`.** The `install` alias is interactive-only and conflicts with `/usr/bin/install` in scripts.

### Alias-Based (Interactive Only)

Enabled when `ENABLE_SHORT_ALIASES=1` in `pkg_aliases.bash`:

| Command | Description |
|---------|-------------|
| `install <pkg>` | Install package(s) |
| `remove <pkg>` | Remove package(s) |
| `uninstall <pkg>` | Alias for remove |
| `update` | Refresh package lists |
| `upgrade` | Install all updates |
| `search <query>` | Search for packages |
| `clean` | Remove orphans & cache |
| `info <pkg>` | Show package details |
| `version` | Show system info (fastfetch/neofetch/onefetch) |

### Supported Distributions

| Family | Distros | Package Manager |
|--------|---------|-----------------|
| Debian | Ubuntu, Debian, Mint, Pop!_OS, Kali | apt-get |
| RHEL | RHEL, CentOS, Fedora, Rocky, AlmaLinux | dnf/yum |
| Arch | Arch, Manjaro, EndeavourOS, Garuda | pacman |
| SUSE | openSUSE, SLES | zypper |
| Gentoo | Gentoo | emerge |
| Alpine | Alpine Linux | apk |
| Void | Void Linux | xbps |
| BSD | FreeBSD | pkg |
| BSD | OpenBSD | pkg_add |
| macOS | macOS | Homebrew |

---

## System Detector

`system_detector.sh` is a standalone POSIX-compatible utility — it does not require bash and works on minimal systems:

```bash
./system_detector.sh            # Show system info + shell capabilities
./system_detector.sh --debug    # Enable set -x tracing
./system_detector.sh --version
```

Reports: OS, distro, kernel, arch, environment (WSL / native / Cygwin), login shell, execution shell, and shell capabilities (aliases, functions, arrays, associative arrays).

> **Note:** This script intentionally uses `#!/bin/sh` for maximum portability. This is a documented exception to the bash-only guideline.

---

## Daily Usage

### Reloading Configuration

The `.bashrc` includes a recursion guard (up to 3 re-sources per session) and a tmux guard:

```bash
reload              # Force reload, bypass tmux guard, clear screen
src                 # Force reload without clearing screen
srcquiet            # Silent reload
```

### TMUX Behaviour Control

Set `BASHRC_SKIP_IN_TMUX` in `~/.bash_profile` to control whether `.bashrc` loads in new tmux panes:

| Value | Behaviour |
|-------|-----------|
| `"yes"` | Skip in tmux panes — load only on terminal start |
| `"no"` | Always load in tmux panes (current default) |
| `"ask"` | Prompt on first tmux pane |

```bash
export BASHRC_SKIP_IN_TMUX="yes"   # Persist in ~/.bash_profile
bashrc-toggle-tmux                  # Interactive toggle alias
bashrc-reset-choice                 # Reset ask-mode decision
```

### Package Management

```bash
install neofetch htop     # Interactive shell
p_install neofetch htop   # Scripts or interactive

update && upgrade         # Update system
search python             # Search packages
clean                     # Clean orphans/cache
version                   # Show system info
```

### Docker Commands (If Docker Installed)

```bash
dps              # docker ps
dcp              # docker compose
dex <container>  # docker exec -it <container> /bin/sh
dkln <container> # Follow container logs
dclean           # Clean dangling images/volumes
```

### Useful Functions

```bash
up [n|name]        # Navigate up n levels or to named parent directory
mcd <dir>          # mkdir + cd in one step
ff <name>          # Find file by exact name recursively
fif <text> [path]  # Find text in files (rg preferred, grep fallback)
fstr <pattern>     # Find and highlight pattern in files
extract <archive>  # Extract any archive format (zip, tar, gz, bz2, rar, 7z...)
ii                 # Display detailed host info (IP, uptime, memory, disk)
mydf <path>        # Pretty df output with visual usage bar
ltree [path]       # Tree view with default ignores, paged through less
functions          # List all defined function names
functions -?       # List all functions with descriptions
version            # Show system info via fastfetch / neofetch / onefetch
sssh <host>        # SSH and auto-attach to tmux or screen session
sshtmux <host>     # SSH and attach to named tmux session
authme             # Copy SSH public key to remote server
quickscan [host]   # Quick port scan of common ports (default: localhost)
```

---

## Smart Backup System

### How Backups Work

1. **First Run** — Creates pristine originals in `oldfiles/`
   - Example: `.bashrc.bak-2026-01-20_10-00-00`
   - These are **never deleted** — they are your permanent restoration point

2. **Subsequent Runs** — Compares files byte-by-byte with repo versions
   - Only backs up if changed; skips unchanged files
   - Creates a timestamped tar.gz archive: `backup-HOSTNAME-DATE.tar.gz`

3. **Automatic Cleanup** — Keeps only 3 most recent tar.gz archives; deletes older ones

### Backup Output Example

```
Backing up existing dotfiles...
⏭️  Skipping /home/user/.bashrc (unchanged from repo)
✔ Backed up: /home/user/.profile
Backed up 1 files to /home/user/.dotfiles/oldfiles/

✔ Archived backups: backup-DESKTOP-JLMCRD0-2026-05-06_10-30-00.tar.gz

Cleaning up old backup archives (keeping 3 most recent)...
🗑️  Deleted old archive: backup-DESKTOP-JLMCRD0-2026-01-10_10-00-00.tar.gz
✔ Cleaned up 1 old archive(s), kept 3 most recent
```

---

## Customization

### Adding Your Own Aliases

Edit `~/.bashrc.d/extra_alias.bash`. This file is listed in `.gitignore` — it will never be overwritten by `git pull` and is safe for machine-specific customizations:

```bash
alias mycommand='echo "Hello World"'
alias ll='ls -lah'
alias ..='cd ..'
```

> If `extra_alias.bash` doesn't exist yet, create it — it will be picked up automatically.

### Adding Custom Functions

Edit `~/.bashrc.d/functions.bash`. A `###` comment on the first line inside the function makes it appear in `functions -?`:

```bash
function my_function() {
    ### Short description of what this does
    echo "This is my function"
}
```

### Adding Environment Variables

Edit `~/.bashrc.d/exports.bash`:

```bash
export MY_VAR="my_value"
export PATH="$HOME/bin:$PATH"
export EDITOR="vim"
```

### Customizing the Application List

Edit `.install_apps.inc` — one package per line, `#` for comments. Re-run `./run_me_first.sh` and it will only install missing packages:

```bash
curl
htop
vim
# nano    # commented out — skipped
```

### Modifying Package Manager Behaviour

Edit `~/.bashrc.d/pkg_aliases.bash` and add your distro to the `case "$DISTROBASE"` block:

```bash
yourdistro*)
    p_install() { sudo your-pkg-manager install "$@"; }
    p_remove()  { sudo your-pkg-manager remove "$@"; }
    p_update()  { sudo your-pkg-manager update; }
    p_upgrade() { sudo your-pkg-manager upgrade; }
    p_search()  { your-pkg-manager search "$@"; }
    p_clean()   { sudo your-pkg-manager autoremove; }
    p_info()    { your-pkg-manager info "$@"; }
    ;;
```

---

## Advanced Configuration

### WSL-Specific Setup

The installer automatically configures `.bash_profile` to source `.bashrc` for WSL compatibility. The `BASHRC_SKIP_IN_TMUX` variable is also set there. No additional setup needed.

### Tmux Configuration

The installer automatically:
- Links tmux configuration from the repo → `~/.tmux`
- Installs Coffee plugin manager → `~/.local/share/coffee`
- Creates symlink `~/.tmux.conf` → `~/.tmux/.tmux.conf`

#### Window & Pane Numbering

The tmux configuration uses 1-based indexing (both windows and panes start at 1):
```bash
set-option -g base-index 1
set -g pane-base-index 1
```

This affects all window/pane references. The `start_tmux.sh` script creates a multi-pane session with windows and panes numbered starting from 1.

#### Coffee Plugin Manager

Coffee is a modern replacement for TPM. Plugins are configured via YAML files in `~/.config/tmux/coffee/plugins/`.

**Fresh Setup**
Create plugin configurations:
```bash
~/.config/tmux/coffee/plugins/your-plugin.yaml
```

**Minimal Plugin Configuration**
```yaml
# ~/.config/tmux/coffee/plugins/tmux-resurrect.yaml
url: "tmux-plugins/tmux-resurrect"
```

**Installing/Updating Plugins**
Prefix + C, opens the Coffee TUI. It has 4 menus;  
* Home  
* Install  
* Update  
* Remove

[Read more: Coffee](https://github.com/PraaneshSelvaraj/coffee.tmux)

#### Custom Keybindings

| Binding | Action |
|---------|--------|
| `prefix + C` | Open Coffee plugin-manager (Capital C)|
| `prefix + h` | Open Htop in display-popup (80% size) |
| `prefix + H` | Open Htop in new window |
| `prefix + o` | Open B-Top in display-popup (80% size) |
| `prefix + O` | Open B-Top in new window |
| `prefix + t` | Open Task Monitor in display-popup (80% size)|
| `prefix + T` | Open System Resouce Overview Dashboard in display-popup (80% size)|
| `prefix + Tab` | Toggle sidebar with tree view |
| `prefix + Space` | Next layout (cycles trough all variants) |
| `prefix + d` | Detach |
| `~~ prefix + m` | Open man page (prompt for command) ~~|

#### Session Creation

The session is created automatically when you open a new terminal (`.bashrc` calls `~/.start_tmux.sh` on first load). To launch it manually:

```bash
~/.start_tmux.sh
```

This creates a session with:
- **Window 1, Pane 1** — Left pane (50% width) — default shell
	+ Opens to ~
- **Window 1, Pane 2** — Top-right (60% height) — default shell
	+ If docker is installed, opens to ~/docker/config
- **Window 1, Pane 3** — Bottom-right (60% height) — default shell
	+ opens with "Midnight Commander", requires root
- **Window 1, Pane 4** — Bottom-right (40% height) — default shell
	+ if Taskwarrior is installed, opens with the task list loaded

(Requires `tmux` and optionally `mc` for file browser)

#### Status Bar

Status bar shows (left to right):
- Session name `[1]`
- Window name with current path
- Window list with indicators
- Plugin status indicators
- Right side: Prefix highlight | CPU | RAM | User | Host | WAN IP

#### Troubleshooting

**Config won't parse**
```bash
tmux -f ~/.tmux.conf list-keys    # Check for syntax errors
```

**Coffee plugins not installing**
```bash
# Verify symlink exists
ls -la ~/.config/tmux/coffee      # Should point to ~/.tmux/coffee

# Force reinstall
coffee uninstall
coffee install --force
```

**Keybindings not working**
```bash
tmux list-keys | grep -E "h|o"    # Verify bindings are loaded
tmux source ~/.tmux.conf           # Reload config
```

### SSH Key Management

The `.bashrc` runs keychain or falls back to `ssh-agent` in interactive non-tmux shells (avoids agent conflicts inside tmux). Install keychain for the preferred path:

```bash
p_install keychain
```

Keys loaded in preference order:
- `~/.ssh/id_ed25519` (preferred)
- `~/.ssh/id_rsa`
- `~/.ssh/id_ecdsa`
- `~/.ssh/id_dsa`

### Vim Setup

The installer links your vim configuration from the repo:
- Linked to `~/.vim`
- Symlink: `~/.vimrc` → `~/.vim/.vimrc`

If you need to set it up manually:
```bash
git clone git@bitbucket.org:b0red/dotfiles.git ~/.dotfiles
ln -s ~/.dotfiles/vim ~/.vim
ln -s ~/.vim/.vimrc ~/.vimrc
ln -s ~/.vim/.gvimrc ~/.gvimrc
```

#### Vim Plugin Manager
This repo uses [vim-plug](https://github.com/junegunn/vim-plug).

Install vim-plug:
```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

Plugin commands:
```vim
:PlugInstall
:PlugUpdate
:PlugClean
:PlugUpgrade
:PlugStatus
```

#### Current plugins
- [vim-fugitive](https://github.com/tpope/vim-fugitive)
- [NERDTree](https://github.com/preservim/nerdtree)
- [auto-pairs](https://github.com/jiangmiao/auto-pairs)
- [nerdcommenter](https://github.com/preservim/nerdcommenter)
- [vim-afterglow](https://github.com/danilo-augusto/vim-afterglow)

#### Useful key mappings
- `Ctrl+F` or `Ctrl+O` — Toggle NERDTree
- `:NERDTree` — Open NERDTree manually
- `F7` — Auto-indent entire file
- `F11` — Toggle paste mode
- `\c<space>` — Toggle comment on current line/selection
- `:Git status`, `:Git commit`, `:Git push`, `:Git blame`, `:Gdiff`

#### Configuration highlights
- 4-space indentation, no tabs
- Line numbers enabled
- 256-color support
- Afterglow dark colorscheme
- Smart case search

### Broot Integration

If `broot` is installed, `.bashrc` sources its launcher at runtime via `$HOME/.config/broot/launcher/bash/br`. Note: `.bash_profile` currently has this path hardcoded — see [Known Issues / Migration TODOs](#known-issues--migration-todos).

---

## Reverting Changes

### Automatic Revert

```bash
./run_me_first.sh --revert
```

Restores original dotfiles from `oldfiles/` backups, removes all created symlinks, and shows a summary. Installed packages are left in place.

### Manual Revert

```bash
# 1. Restore pristine backups
cd ~/.dotfiles/oldfiles/
for f in .bashrc.bak-* .profile.bak-* .bash_profile.bak-* .inputrc.bak-*; do
    [ -f "$f" ] || continue
    original=$(echo "$f" | sed 's/\.bak-.*$//')
    cp "$f" ~/"$original"
    echo "Restored: $original"
done

# 2. Remove symlinks
rm -f ~/.bashrc ~/.bash_profile ~/.profile ~/.inputrc

# 3. Restart shell
exec bash
```

---

## Maintenance

### Updating Dotfiles

```bash
cd ~/.dotfiles
git pull origin main
reload
```

### Backing Up Current Config

```bash
cd ~/.dotfiles
git add .bashrc .bash_profile .profile .bashrc.d/ .profile.d/
git commit -m "chore: update configuration"
git push
```

### Cleaning Up Old Archives

Archives are automatically culled to 3 most recent. To clean manually:

```bash
cd ~/.dotfiles
ls -t backup-*.tar.gz | tail -n +4 | xargs rm -f
```

### Viewing Logs

```bash
tail -f ~/.dotfiles/logs/install-*.log     # Follow latest log
ls -lth ~/.dotfiles/logs/                  # List all logs
find ~/.dotfiles/logs -name "*.log" -mtime +30 -delete   # Clean logs > 30 days
```

---

## Troubleshooting

### Colors Not Showing

```bash
echo -e "\033[0;32mGreen\033[0m \033[0;31mRed\033[0m"
```

If no colors appear, your terminal doesn't support ANSI. Try a different terminal emulator.

### Package Functions Not Working in Scripts

In scripts, `install` is unavailable — use `p_install`:

```bash
p_install htop          # Correct in scripts
install htop            # Interactive only
```

### Docker Shortcuts Not Appearing

Docker shortcuts only load if Docker is installed:

```bash
command -v docker       # Is Docker installed?
p_install docker.io     # Ubuntu/Debian
p_install docker        # Other distros
reload
```

### Aliases Not Working

```bash
declare -f p_install                            # Is pkg_aliases loaded?
source ~/.dotfiles/.bashrc.d/pkg_aliases.bash   # Source manually if not
reload
```

### Recursion Guard Preventing Re-source

```bash
BASHRC_SOURCED=0 source ~/.bashrc   # Reset counter manually
reload                               # Or use reload (handles it automatically)
```

### Symlinks Not Created

```bash
ls -la ~/.dotfiles/.bashrc   # Confirm file exists in repo
ls -la ~/.bashrc             # Confirm symlink exists at home
ln -sf ~/.dotfiles/.bashrc ~/.bashrc   # Create manually if needed
```

### Package Installation Fails

1. Check internet connection
2. Update package lists: `sudo apt-get update` / `sudo dnf check-update`
3. Check the log: `tail -f ~/.dotfiles/logs/install-*.log`
4. Install manually: `sudo apt-get install -y curl htop vim`

### Visual Loading Not Showing

Loading feedback only appears in interactive shells:

```bash
echo $-   # Must contain 'i' for interactive
```

### "Unknown OS" Error

Add your distro to `pkg_aliases.bash`. See [Modifying Package Manager Behaviour](#modifying-package-manager-behaviour).

### Files Loading Twice

The `loaded_files` associative array in `.bashrc` prevents duplicate loading. If you see doubles, check for extra `source` calls outside the standard loading blocks.

### `functions -?` Showing Wrong File

See [Known Issues / Migration TODOs](#known-issues--migration-todos) — `functions.bash` has a hardcoded `~/dotfiles/` path that breaks after migration.

---

## Security Notes

- The installer never modifies system files (user home directory only)
- Sudo is used only for package installation
- All changes are logged to timestamped log files
- Original files are backed up before any change is made
- Recursion guard prevents infinite sourcing loops
- Run guard (`RUNME_INITIATED`) prevents concurrent installer execution
- Docker shortcuts load only when Docker is present

---

## Getting Help

1. **Check logs**: `tail -f ~/.dotfiles/logs/install-*.log`
2. **Check bash syntax**: `bash -n ~/.bashrc`
3. **Debug mode**: `DEBUG=1 ./run_me_first.sh`
4. **Trace mode**: `TRACE_DEBUG=1 ./run_me_first.sh`
5. **Version check**: `./run_me_first.sh --version`
6. **Shell reload check**: `reload` (should show visual feedback)
7. **Test pkg_aliases**: `source ~/.dotfiles/helpers/debug.sh`

---

## Known Issues / Migration TODOs

### Remaining Items

| File | Location | Issue |
|------|----------|-------|
| `.bash_profile` | line 29 | Hardcoded `/home/patrick/.config/broot/...` → use `$HOME` |
| `.bashrc` header | line 3 | Still says "Created by RunMe.sh" — auto-corrected on next `./run_me_first.sh` run |
| `system_detector.sh` | — | Missing `-?/--info`, `--dry-run`, compliant header (low priority — standalone utility) |
| `symlink.sh` | — | No flags (called by installer, not user-facing — acceptable) |

### Vibecoding v5.6 Compliance Gaps

| File | Guideline | Issue |
|------|-----------|-------|
| `run_me_first.sh` | Part V §1 | Inline ANSI codes only — no `ColorCodes.inc` sourcing |
| `system_detector.sh` | Part II §2 | Missing compliant script header |
| `symlink.sh` | Part II §2 | Missing compliant script header |

---

## Version History
- **v15.8.0** (2026-06-21)
  - Full refactor of `run_me_first.sh` to Vibecoding v5.6 canonical structure
  - 9 logical bug fixes in `run_me_first.sh` (state file conflict, validate_installation false positives, revert double-restore, symlink log direction, add_file_header regex, PIPESTATUS, distro case patterns, taskwarrior backup order)
  - 6 `.bashrc.d` bug fixes (ltree/myip alias shadowing, docker.bash lzd/lzj conflict + unquoted IDs, exports.bash PAGER fallback + export/assign split + uname consolidation, env.bash dead variable, logout.bash log rotation)
  - Repository migration complete: all Bitbucket URLs → GitHub; `~/dotfiles` → `~/.dotfiles`

- **v15.7.1** (2026-06-20)
  - Tmux auto-start on new terminal via `~/.start_tmux.sh` (guarded for interactive, first-load, non-tmux)
  - Fixed `NC` color code in `colorcodes.bash` (was black, now proper reset)
  - Fixed `list_extensions()` perl quoting bug (bash was eating `$1` before perl)
  - Fixed `please` and `ghost` from broken aliases to proper functions
  - Fixed `tm` alias trailing `\;` sending empty tmux command
  - Silenced noisy `pkg_aliases.bash` startup message

- **v15.6.1** (2026-05-13)
  - Changed info regarding tmux plugin manager from TPM to Coffee (modern replacement)
  - Updated tmux configuration instructions to reflect Coffee usage
  - Added `start_tmux.sh` script for easy session creation with the new tmux configuration
  - Updated tmux keybinding documentation to reflect new bindings and Coffee integration
  - Added troubleshooting steps for tmux configuration and Coffee plugin manager
  - Updated Known Issues / Migration TODOs to reflect changes and new tmux setup

- **v15.6.0** (2026-05-06)
  - Restructured repo: `debug.sh` moved from `.bashrc.d/` to `helpers/`
  - Added `extra_alias.bash` and `local_alias.bash` to `.gitignore` (safe local customizations)
  - README fully restructured for new-user-first flow
  - README completed with all sections from original (previously omitted in migration)
  - Added Vibecoding v5.6 compliance audit to Known Issues
  - Confirmed migration target: `https://github.com/b0red/.dotfiles`
  - Updated version references throughout

- **v15.5.0** (2026-02-18)
  - Renamed installer: `RunMe.sh` → `run_me_first.sh`
  - Replaced `SystemDetector.sh` with portable POSIX `system_detector.sh`
  - Moved diagnostic/test scripts to `oldfiles/`
  - Added `symlink_config_folders` for `~/.config` directory linking
  - Added `archive_backup` and automatic cleanup of old archives (keeps 3)
  - Added revert functionality (`--revert`)
  - Added tmux guard with `BASHRC_SKIP_IN_TMUX` control + `bashrc-toggle-tmux` alias
  - Added `bashrc-reset-choice` for ask-mode reset
  - `.bashrc` updated to reference `~/.dotfiles` (migration target)

- **v15.2.0–v15.4.0** (2026-01, undocumented)
  - Intermediate versions released during this period — changelog not recorded at time of release.

- **v15.1.0** (2026-01-20)
  - Visual loading feedback with cursor positioning
  - Conditional Docker loading (only if Docker installed)
  - Smart file loading architecture (core vs interactive)
  - Package management with `p_*` functions and aliases
  - Configurable loading delay
  - Enhanced cross-distro support

- **v15.0.0** (2026-01-16)
  - Added version support (`--version` flag)
  - Smart backup system (only backs up changed files)
  - Automatic cleanup (keeps 3 most recent archives)
  - Color-coded output (green/yellow/red)
  - Smart recursion guard in `.bashrc`
  - Privilege-aware prompt colors (green user / red root)

---

## Credits & Inspiration

- [Shell Config Subfiles](https://sanctum.geek.nz/arabesque/shell-config-subfiles/)
- [CLI Improved](https://remysharp.com/2018/08/23/cli-improved)
- [kenorb/dotfiles Functions](https://github.com/kenorb/dotfiles/blob/master/.bash_functions)
- [kenorb/dotfiles Aliases](https://github.com/kenorb/dotfiles/blob/master/.bash_aliases)
- [sharkdp/bat](https://github.com/sharkdp/bat/)
- [prettyping](https://github.com/denilsonsa/prettyping.git)

Created and maintained by **Patrick Österlund**.

If you find this useful, consider supporting: [PayPal](https://paypal.me/fotosbypatrick)

---

**Last Updated**: 2026-06-21
**Script Version**: v15.8.0
**Guidelines**: Vibecoding v5.6 / Semantic Versioning 2.0.0
