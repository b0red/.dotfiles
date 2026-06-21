# Dotfiles Dependencies

Covers the full repo — shell environment, installer, and tmux config.
See [tmux/DEPENDENCIES.md](tmux/DEPENDENCIES.md) for tmux plugin detail.

---

## Required

These must be present. The installer or core shell functionality will fail
without them.

| Tool | Min version | Used by |
|------|------------|---------|
| `bash` | 4.0+ | All scripts (`run_me_first.sh` checks at startup) |
| `git` | any | Installer, submodule setup, `tmux_installer.sh` |
| `tmux` | 3.0+ | Core config, Coffee plugin manager |
| `python3` | 3.10+ | Coffee plugin manager (venv + dependencies) |
| `python3-venv` | — | Coffee venv creation in `tmux_installer.sh` |

```bash
# Debian/Ubuntu
sudo apt-get install -y bash git tmux python3 python3-venv
```

---

## Installer Essentials

Installed by `run_me_first.sh` from `.install_apps.inc`. Listed here so
a manual or partial install knows what to grab.

| Tool | Purpose |
|------|---------|
| `curl` | Downloads, general HTTP |
| `wget` | Downloads |
| `vim` | Default `$EDITOR` |
| `zip` / `unzip` | Archive handling |
| `tree` | Directory listing (superseded by `broot` if installed) |

---

## Tmux Plugins (via Coffee)

| Tool | Required by | Notes |
|------|------------|-------|
| `bc` | tmux-menus | Basic calculator |
| `yq` ≥ 4 | tmux-nerd-font-window-name | YAML parser |
| Nerd Font | tmux-nerd-font-window-name | Must be set in your terminal emulator |

```bash
sudo apt-get install -y bc
# yq v4: https://github.com/mikefarah/yq (snap or binary — apt version is too old)
snap install yq
```

---

## Nice to Have

All of these are guarded with `command -v` checks. The shell degrades
gracefully if they are absent; the listed alias or function simply falls
back to the standard tool or is skipped.

### Modern CLI Replacements

| Tool | Replaces | Alias/function |
|------|----------|---------------|
| `eza` | `ls` | `ll`, `kk`, `oo` switch to `eza` |
| `bat` | `cat` | `cat` alias |
| `fd` / `fdfind` | `find` | `fd` alias + search functions |
| `rg` (ripgrep) | `grep` | `search()` function |
| `broot` | `tree` | `tree` alias |
| `most` | `less` | `$PAGER`, `.profile.d/pager.sh` |
| `prettyping` | `ping` | `ping` alias |
| `btop` | `top` | `top` alias |
| `bottom` | — | `btm` alias |
| `ncdu` | `du` | `du` alias |

```bash
sudo apt-get install -y bat fd-find ripgrep broot most prettyping btop ncdu
# eza: https://github.com/eza-community/eza (not in default apt on older distros)
# bottom: https://github.com/ClementTsang/bottom
```

### System Info / Monitoring

| Tool | Used by | Notes |
|------|---------|-------|
| `fastfetch` | `sysinfo()` function | Preferred over neofetch |
| `neofetch` | `sysinfo()` function | Fallback if fastfetch absent |
| `onefetch` | `sysinfo()` function | Used inside git repos instead |
| `htop` | — | Installed by default via `.install_apps.inc` |
| `atop` | — | Installed by default via `.install_apps.inc` |
| `btop` | `top` alias | Installed by default via `.install_apps.inc` |

### Task & File Management

| Tool | Used by | Notes |
|------|---------|-------|
| `task` (taskwarrior) | `tasks` alias, `start_tmux.sh` pane 4 | Pane only created if present |
| `mc` (Midnight Commander) | `start_tmux.sh` pane 3, `mc` alias | Pane runs `mc` if present |
| `fzf` | Various functions | Fuzzy finder |
| `jq` | `docker.bash` functions | JSON processor |
| `entr` | — | File watcher for automation |
| `tldr` | — | Simplified man pages |
| `ncdu` | `du` alias | Interactive disk usage |
| `pydf` | — | Coloured `df` replacement |

### Docker

| Tool | Required by |
|------|------------|
| `docker` | All of `docker.bash` (skipped entirely if absent) |

### Markdown / Writing

| Tool | Used by |
|------|---------|
| `ghostwriter` | `ghost` alias |

### System Info at Login (welcome.sh)

These are entirely optional — `welcome.sh` skips each one silently if absent.

| Tool | Purpose |
|------|---------|
| `fortune` | Random quote on login |
| `rem` | Daily reminders |
| `verse` | Daily verse |

### Text Browser

| Tool | Set by |
|------|--------|
| `lynx` | `.profile.d/browser.sh` sets `$BROWSER=lynx` |

### Networking

| Tool | Used by |
|------|---------|
| `lazyports` | `lzp` alias (skipped if absent) |

---

## PATH Extensions Added by This Repo

`exports.bash` prepends these to `$PATH`:

| Path | Contents |
|------|----------|
| `~/bin` | User scripts (`ColorCodes.inc`, `spinner.sh`, etc.) |
| `~/.local/bin` | pip installs, local tools |
| `/snap/bin` | Snap packages |
| `~/.local/share/coffee/bin` | Coffee plugin manager CLI |
| `~/go/bin` | Go binaries |

---

## External Files Sourced at Runtime

These live in `~/bin` (outside the dotfiles repo). The shell loads them
if present but degrades gracefully if absent.

| File | Used by | Purpose |
|------|---------|---------|
| `~/bin/ColorCodes.inc` | `functions.bash` | Shared ANSI color definitions |
| `~/bin/spinner.sh` | `functions.bash` | Terminal spinner utility |
| `~/bin/email_variables.inc` | `functions.bash` | Email config variables |
| `~/.cargo/env` | `.bash_profile` | Rust/Cargo environment setup |
| `~/.config/broot/launcher/bash/br` | `.bash_profile` | broot shell function |

---

## Symlinks Created by the Installer

`run_me_first.sh` creates these. All are validated by `--check` mode.

| Symlink | Target |
|---------|--------|
| `~/.bashrc` | `~/.dotfiles/.bashrc` |
| `~/.bash_profile` | `~/.dotfiles/.bash_profile` |
| `~/.profile` | `~/.dotfiles/.profile` |
| `~/.tmux` | `~/.dotfiles/tmux/` |
| `~/.tmux.conf` | `~/.dotfiles/tmux/.tmux.conf` |
| `~/.vim` | `~/.vim/` (external vim repo) |
| `~/.vimrc` | `~/.vim/.vimrc` |
| `~/.start_tmux.sh` | `~/.dotfiles/tmux/start_tmux.sh` |

---

## Install Everything at Once (Debian/Ubuntu)

```bash
# Required
sudo apt-get install -y bash git tmux python3 python3-venv

# Installer essentials
sudo apt-get install -y curl wget vim zip unzip tree

# Tmux plugin deps
sudo apt-get install -y bc
snap install yq

# Nice to have
sudo apt-get install -y bat fd-find ripgrep most ncdu fzf \
  btop htop atop taskwarrior mc tldr entr pydf jq ghostwriter

# Modern tools not in apt (follow upstream install instructions)
# eza:       https://github.com/eza-community/eza
# broot:     https://github.com/Canop/broot
# prettyping: https://github.com/denilsonsa/prettyping
# fastfetch: https://github.com/fastfetch-cli/fastfetch
# onefetch:  https://github.com/o2sh/onefetch
# bottom:    https://github.com/ClementTsang/bottom
# lazyports: https://github.com/b0red/lazyports (private)
```
