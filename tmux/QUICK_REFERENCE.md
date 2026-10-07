# Tmux + Coffee — Quick Reference Card

## Installation (First Time)

Tmux configuration is bundled with the dotfiles repo. The main installer handles everything:

```bash
# Clone dotfiles (if not done)
git clone git@github.com:b0red/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the installer (handles tmux symlinks and submodules)
./run_me_first.sh

# OR install Coffee and plugins manually:
~/.dotfiles/tmux/tmux_installer.sh
```

## Coffee Plugin Manager

### CLI Commands
```bash
coffee install              # Install all plugins
coffee update               # Check for updates
coffee upgrade              # Upgrade plugins
coffee list                 # List installed plugins
coffee info <plugin>        # Plugin details
coffee remove <plugin>      # Remove plugin
coffee enable <plugin>      # Enable plugin
coffee disable <plugin>     # Disable plugin
```

### TUI Interface
- Launch: `Ctrl-a` then `C` (capital C)
- Navigate: `j/k` or arrow keys
- Select: `Space`
- Follow on-screen controls

## Tmux Key Bindings

### Prefix Key
- **Prefix**: `Ctrl-a` (not default Ctrl-b)

### Essential Commands
| Key Combo | Action |
|-----------|--------|
| `Ctrl-a` + `r` | Reload config |
| `Ctrl-a` + `C` | Open Coffee TUI |
| `Ctrl-a` + `c` | New window |
| `Ctrl-a` + `-` | Split horizontal |
| `Ctrl-a` + `\|` | Split vertical |
| `Ctrl-a` + `d` | Detach session |
| `Ctrl-a` + `\` | tmux-menus main menu (Custom items → **Tools**: htop/btop/lazyports windows, task monitor, man page, urlview, Coffee) |
| `Ctrl-a` + `\` → Custom items → Tools → `s` | Script picker for `~/bin` (Enter = dry-run, Ctrl-X = real run, Ctrl-V = source) |
| `Ctrl-a` + `\` → Custom items → Docker → `c` | Container picker: Enter logs, Ctrl-S shell, Ctrl-T stats, Ctrl-O inspect, Ctrl-R restart (local Docker, else ssh to `@docker_menu_host`) |
| `Ctrl-a` + `a` | Send a literal `Ctrl-a` (nested/remote tmux, bash start-of-line) |
| `Ctrl-a` + `h` / `b` / `l` | htop / btop / lazyports popup |
| `Ctrl-a` + `t` / `T` | Task monitor / overview |
| `Alt` + `Arrow` | Navigate panes (no prefix!) |
| `Tab` | Toggle sidebar |

### Window Management
| Key Combo | Action |
|-----------|--------|
| `Ctrl-a` + `c` | Create new window |
| `Ctrl-a` + `,` | Rename window |
| `Ctrl-a` + `X` | Kill window (with confirmation) |
| `Ctrl-a` + `0-9` | Switch to window number |
| `Ctrl-a` + `Ctrl-a` | Last window |

### Pane Management
| Key Combo | Action |
|-----------|--------|
| `Ctrl-a` + `\|` | Split vertical |
| `Ctrl-a` + `-` | Split horizontal |
| Mouse drag + release (no Shift) | Copy to Windows clipboard (via clip.exe) |
| `Ctrl-a` + `[`, Space, move, `y` | Copy in copy mode (also to Windows clipboard) |
| `Ctrl-a` + `]` | Paste tmux buffer |
| `Ctrl-a` + `\` → Panes | Toggle synchronized panes (type to all) — was `Ctrl-a e` |
| `Alt` + `←→↑↓` | Navigate panes |

## Troubleshooting

### Check Versions
```bash
tmux -V                    # Should be 3.1+
python3 --version          # Should be 3.10+
```

### Validate Config
```bash
tmux -f ~/.tmux.conf list-keys
```

### Coffee Issues
```bash
# Check Coffee installation
ls -la ~/.local/share/coffee/

# Check venv
ls -la ~/.local/share/coffee/.venv/

# Reinstall Python packages
cd ~/.local/share/coffee
.venv/bin/python -m pip install -r requirements.txt
```

### Fresh Start
```bash
# Kill all tmux sessions
tmux kill-server

# Start new session
tmux new-session

# OR start with preconfigured layout:
~/.dotfiles/tmux/start_tmux.sh
```

## File Locations
```
~/.tmux.conf                         # Symlink → ~/.dotfiles/tmux/.tmux.conf
~/.dotfiles/tmux/.tmux.conf          # Actual config file
~/.local/share/coffee/               # Coffee installation
~/.local/share/coffee/.venv/         # Python virtual environment
~/.dotfiles/tmux/coffee/plugins/     # Installed plugins
~/.dotfiles/tmux/start_tmux.sh       # Preconfigured session layout script (--help, --dry-run)
~/.dotfiles/tmux/tmux_guard.inc      # "Never tmux inside tmux" check (start_tmux.sh + .bashrc)
~/.dotfiles/tmux/menus/tools.sh      # Tools menu source (copied into tmux-menus by tmux_installer.sh)
~/.dotfiles/tmux/menus/docker.sh     # Docker menu source (same)
~/.dotfiles/tmux/script_picker.sh    # ~/bin script picker (Tools → s)
~/.dotfiles/tmux/docker_actions.sh   # Docker menu backend: picker + actions, local or over ssh
/tmp/tmux-$UID/default               # Server socket (TMUX_TMPDIR=/tmp)
```

## Migration from TPM
```bash
# If you had TPM before:
coffee migrate              # Migrate plugin config
coffee install              # Install plugins with Coffee
```

## Common Tasks

### Install New Plugin
1. Add to `.tmux.conf`:
   ```
   set -g @plugin 'author/plugin-name'
   ```
2. Reload config: `Ctrl-a` + `r`
3. Install: `coffee install`

### Update All Plugins
```bash
coffee update               # Check for updates
coffee upgrade              # Apply updates
```

### List Installed Plugins
```bash
coffee list
```

## Start tmux with Layout
```bash
~/.dotfiles/tmux/start_tmux.sh
```

This attaches to session `linux` if it exists, otherwise creates:
- Left pane (50%): shell in `~/bin`
- Top-right (60% of right side): shell in `~/docker/compose` (or `~`)
- Bottom-right: Midnight Commander (if installed, focused)
- Bottom-most: `task list` (if Taskwarrior is installed)

It refuses to run inside tmux (even when `$TMUX` was stripped by sudo/su or ssh-to-self).
Preview without changes: `~/.dotfiles/tmux/start_tmux.sh --dry-run`

## Resources
- Coffee: https://github.com/PraaneshSelvaraj/coffee.tmux
- Dotfiles repo: https://github.com/b0red/.dotfiles
- Full tmux README: `~/.dotfiles/tmux/README.md` (if present)
