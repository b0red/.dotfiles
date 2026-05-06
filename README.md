#  These are my tmux file and plugins
## .tmux.conf and additional plugins

### Prerequisites:
- git installed
- tmux 3.0+ installed 
- Python 3.10+ installed (for Coffee plugin manager)

## Install (if not already installed):
```bash
sudo apt install git tmux python3 python3-venv
```

**Note**: Installation commands may vary based on your Linux distribution. Please refer to your distribution's package manager documentation for accurate installation instructions.

### Clone this repo: 
```bash
git clone git@bitbucket.org:b0red/tmux.git ~/.tmux
ln -s ~/.tmux/.tmux.conf ~/.tmux.conf
```

### Automated Installation:
Run the installer script which handles symlink creation and Coffee plugin manager setup:
```bash
~/.tmux/TmuxInstaller.sh
```

The installer will:
- Create the symlink for ~/.tmux.conf
- Install Coffee Plugin Manager
- Set up Python virtual environment for Coffee
- Verify your configuration

### Start tmux:
```bash
~/.tmux/start-tmux.sh
```

**Note**: You can also start tmux by simply running `tmux` in your terminal if the configuration file is correctly linked.

**What start-tmux.sh does**:
- Checks if docker is installed and running; if so, changes to ~/docker/compose, otherwise stays in ~
- Checks if [taskwarrior](https://taskwarrior.org/) is installed; if so, creates a pane and runs `task` CLI in it
- Checks if mc (Midnight Commander) is installed; if so, runs it in a pane
- Creates a multi-pane layout with optimal workflow setup

### Reload tmux config:
In tmux, press `prefix` + `r` to reload the tmux configuration.

## Coffee Plugin Manager

This configuration uses **Coffee** - a modern tmux plugin manager with both CLI and TUI interfaces.

### Installation (if not using TmuxInstaller.sh):
Coffee requires tmux 3.0+ and Python 3.10+.

1. Clone the Coffee repository:
```bash
git clone https://github.com/PraaneshSelvaraj/coffee.tmux ~/.local/share/coffee
cd ~/.local/share/coffee
```

2. Set up Python virtual environment:
```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
```

**Note**: If you get an error about venv not being available, install it:
```bash
# For Ubuntu/Debian:
sudo apt install python3-venv
# OR for specific Python version (e.g., 3.13):
sudo apt install python3.13-venv
```

3. Add Coffee to your PATH by adding this line to your shell config (~/.bashrc, ~/.zshrc, etc.):
```bash
export PATH="$HOME/.local/share/coffee/bin:$PATH"
```

4. Reload your shell configuration:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

### CLI commands for Coffee:
```bash
coffee install                  # Install configured plugins
coffee update                   # Check for plugin updates
coffee upgrade                  # Upgrade plugins with available updates
coffee upgrade tmux-sensible    # Upgrade a specific plugin
coffee remove tmux-sensible     # Remove a plugin
coffee list                     # List installed plugins
coffee info tmux-sensible       # Show plugin details
coffee enable tmux-sensible     # Enable a plugin
coffee disable tmux-sensible    # Disable a plugin
```

### TUI Interface for Coffee:
Launch the TUI interface by pressing the keybinding `prefix` + `C` (capital C).

The TUI provides:
- Tabbed navigation for plugins, installed packages, and settings
- Visual plugin management with intuitive controls
- Real-time status updates
- Easy plugin installation/removal

Read more: [Coffee Plugin manager](https://github.com/PraaneshSelvaraj/coffee.tmux)

## Migration from TPM

If you were previously using TPM (tmux plugin manager) and want to migrate to Coffee:

1. Install Coffee using the instructions above
2. Run the migration command:
```bash
coffee migrate
```
3. Install your plugins with Coffee:
```bash
coffee install
```

Coffee will automatically detect your existing TPM plugin configuration and migrate it.

## Configuration Details

### Installed Plugins
The configuration includes these plugins (managed by Coffee):
- **tmux-menus** - Convenient menus for various tasks
- **tmux-nerd-font-window-name** - Window names with nerd font icons
- **tmux-power-zoom** - Enhanced pane zoom functionality
- **tmux-resurrect** - Save and restore tmux sessions
- **tmux-continuum** - Automatic session save/restore
- **tmux-online-status** - Display online/offline status
~~- **tmux-sidebar** - File tree sidebar~~[^1]
- **tmux-battery** - Battery status display
- **tmux-prefix-highlight** - Highlight when prefix is active
- **tmux-cpu** - CPU and memory usage display
- **tmux-weather** - Weather information in status bar

### Key Bindings
- **Prefix**: `Ctrl-a` (instead of default `Ctrl-b`)
- **Reload config**: `prefix` + `r`
- **Coffee TUI**: `prefix` + `C` (capital C)
- **Split horizontal**: `prefix` + `|`
- **Split vertical**: `prefix` + `-`
- **Navigate panes**: `Alt` + `Arrow Keys` (no prefix needed)
- **Sidebar toggle**: `prefix` + `Tab`
- **Sidebar toggle & focus**: `prefix` + `Backspace`
- **New window**: `prefix` + `c`

### Contact
Maintainer: b0red  
GitHub: [b0red](https://github.com/b0red)

For questions or support, please open an issue on GitHub.

### License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
___
[^1]: tmux-sidebar has been temporarily disabled due to compatibility issues. It may be re-enabled in future updates.