# Tmux + Coffee - Quick Reference Card

## Installation (First Time)
```bash
# 1. Clone repo (if not done)
git clone git@bitbucket.org:b0red/tmux.git ~/.tmux

# 2. Run automated installer
~/.tmux/tmux_installer.sh

# 3. Add Coffee to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.local/share/coffee/bin:$PATH"

# 4. Reload shell
source ~/.bashrc

# 5. Start tmux
tmux
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
| `Ctrl-a` + `I` | Install plugins (alternative to coffee install) |
| `Ctrl-a` + `c` | New window |
| `Ctrl-a` + `\|` | Split horizontal |
| `Ctrl-a` + `-` | Split vertical |
| `Ctrl-a` + `d` | Detach session |
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
| `Ctrl-a` + `e` | Synchronize panes (type to all) |
| `Alt` + `←→↑↓` | Navigate panes |

## Troubleshooting

### Check Versions
```bash
tmux -V                    # Should be 3.0+
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
```

## File Locations
```
~/.tmux.conf                        # Symlink to config
~/.tmux/.tmux.conf                  # Actual config file
~/.local/share/coffee/              # Coffee installation
~/.local/share/coffee/.venv/        # Python virtual environment
~/.tmux/plugins/                    # Installed plugins
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
3. Install: `coffee install` OR `Ctrl-a` + `I`

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
~/.tmux/start-tmux.sh
```

This creates:
- Left pane (50%): Terminal
- Top-right (60%): Docker/compose directory
- Middle-right: Midnight Commander (if installed)
- Bottom-right: Taskwarrior (if installed)

## Resources
- Coffee: https://github.com/PraaneshSelvaraj/coffee.tmux
- Your config: https://github.com/b0red (or bitbucket)
- Full README: ~/.tmux/README.md
