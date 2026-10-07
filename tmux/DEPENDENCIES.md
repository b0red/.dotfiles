# Tmux Plugin Dependencies

## This Config
- **tmux 3.1+** — `start_tmux.sh` uses `split-window -l N%`; `.tmux.conf` uses `{ }` command blocks (3.0+)
- **`clip.exe`** (WSL, built into Windows) — tmux `copy-command`, so copies reach the Windows clipboard in any terminal (classic conhost has no OSC 52). Guarded: ignored where absent
- **Optional** for the Tools menu / popup keys: `htop`, `btop`, `lazyports`, `urlview`
- **`fzf`** — script picker (Tools → `s`)
- **Docker menu** (Docker host only): `docker` CLI with the user in the `docker` group; optional `lazydocker`

## Plugin Manager
- **Coffee**: https://github.com/PraaneshSelvaraj/coffee.tmux
  - Requires tmux 3.0+
  - Requires Python 3.10+
  - Requires `git`
  - Requires `python3-venv`

## Plugins

### [tmux-nerd-font-window-name](https://github.com/joshmedeski/tmux-nerd-font-window-name)
- tmux 3.0+
- A Nerd Font installed and configured in your terminal
- `yq` (>= 4)

### [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum)
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)

### [tmux-menus](https://github.com/jaclu/tmux-menus)
- `bc`
- Custom menus (our `menus/tools.sh`) need the plugin's cache enabled (default) and must be
  regular files in `custom_items/` — symlinks are ignored, so `tmux_installer.sh` copies them

## Install All Dependencies (Debian/Ubuntu)
```bash
sudo apt-get install -y bc yq python3-venv
```
