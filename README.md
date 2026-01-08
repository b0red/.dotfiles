# Dotfiles Configuration

A comprehensive, cross-platform dotfiles setup with modular bash configuration, package manager abstraction, and automated installation.

## Features

- 🔧 **Modular Configuration**: Split into logical files in `.bashrc.d/`
- 📦 **Universal Package Management**: Unified `install`, `update`, `upgrade` commands across all distros
- 🎨 **Customizable**: Easy to extend and modify
- 🔄 **Automatic Backup**: Old configs saved before changes
- 🚀 **One-Command Setup**: `./RunMe.sh` does everything
- 💻 **Cross-Platform**: Supports Debian, Ubuntu, RHEL, Fedora, Arch, Gentoo, Alpine, NixOS, FreeBSD, OpenBSD, macOS

## Quick Start

```bash
# Clone the repository
cd ~
git clone git@bitbucket.org:b0red/dotfiles.git ~/dotfiles
cd dotfiles

# Run the installer
./RunMe.sh
```

The script will:
1. Backup existing dotfiles to `~/dotfiles/old-files/`
2. Create symlinks from `~/.bashrc`, `~/.profile`, etc. to repo files
3. Install essential applications (curl, htop, vim, tmux, etc.)
4. Update git submodules
5. Clone additional repos (.tmux, .vim)
6. Log everything to `~/dotfiles/install-YYYY-MM-DD.log/`

## Directory Structure

```
~/dotfiles/
├── .bashrc                 # Main bash configuration
├── .bash_profile           # Login shell config
├── .profile                # POSIX shell config
├── .inputrc                # Readline configuration
├── .bashrc.d/              # Modular bash configs
│   ├── aliases.bash        # Command aliases
│   ├── colorcodes.bash     # Color definitions
│   ├── docker.bash         # Docker shortcuts
│   ├── env.bash            # Environment setup
│   ├── exports.bash        # Environment variables
│   ├── functions.bash      # Custom functions
│   ├── git.bash            # Git aliases/functions
│   ├── pkg_aliases.bash    # Package manager functions
│   └── variables.bash      # Variable definitions
├── .profile.d/             # POSIX shell modules
│   ├── browser.sh
│   ├── pager.sh
│   └── timezone.sh
├── old-files/              # Backup directory
├── RunMe.sh                # Installation script
└── README.md               # This file
```

## Package Manager Commands

After installation, these commands work across **all supported distros**:

| Command | Description | Example |
|---------|-------------|---------|
| `install <pkg>` | Install package(s) | `install vim htop` |
| `remove <pkg>` | Remove package(s) | `remove vim` |
| `uninstall <pkg>` | Alias for remove | `uninstall vim` |
| `update` | Refresh package lists | `update` |
| `upgrade` | Install all updates | `upgrade` |
| `search <query>` | Search for packages | `search python` |
| `clean` | Remove orphans & cache | `clean` |
| `info <pkg>` | Show package details | `info vim` |
| `version` | Show system info | `version` |

### Supported Distributions

- **Debian/Ubuntu**: apt-get
- **RHEL/Fedora/CentOS/AlmaLinux**: dnf/yum
- **openSUSE**: zypper
- **Arch/Manjaro**: pacman
- **Gentoo**: emerge
- **Alpine**: apk
- **Void Linux**: xbps
- **NixOS**: nix-env
- **FreeBSD**: pkg
- **OpenBSD**: pkg_add
- **macOS**: Homebrew (if installed)

## Usage

### Installation Options

```bash
./RunMe.sh              # Normal installation
./RunMe.sh --help       # Show help
./RunMe.sh --revert     # Revert changes (see below)
./RunMe.sh --debug      # Debug mode
DEBUG=1 ./RunMe.sh      # Debug with environment variable
```

### Daily Usage

```bash
# Install packages (works on any distro)
install neofetch htop

# Update system
update && upgrade

# Search for packages
search python

# Clean up
clean

# Show system info
version
```

### Reloading Configuration

```bash
# After editing dotfiles
source ~/.bashrc
or 
reload

# Or restart your shell
exec bash
```

## Reverting Changes

### Automatic Revert

```bash
./RunMe.sh --revert
```

This will:
- Restore original dotfiles from backups
- Remove all symlinks created by the installer
- Leave installed packages in place

### Manual Revert

If `--revert` doesn't work or you need more control:

1. **Restore backups manually:**
   ```bash
   cd ~/dotfiles/old-files/
   cp *.bak-* ~/
   # Rename files (remove .bak-TIMESTAMP suffix)
   ```

2. **Remove symlinks:**
   ```bash
   cd ~
   rm -f .bashrc .bash_profile .profile .inputrc
   ```

3. **Restore from backups:**
   ```bash
   cd ~/dotfiles/old-files/
   for f in *.bak-*; do
       original=$(echo "$f" | sed 's/\.bak-.*$//')
       cp "$f" ~/"$original"
   done
   ```

4. **Delete dotfiles repo** (optional):
   ```bash
   rm -rf ~/dotfiles
   ```

## Customization

### Adding Your Own Aliases

Edit or create `~/.bashrc.d/extra_alias.bash`:

```bash
# My custom aliases
alias mycommand='echo "Hello World"'
alias ll='ls -lah'
```

### Adding Environment Variables

Edit `~/.bashrc.d/exports.bash`:

```bash
export MY_VAR="my_value"
export PATH="$HOME/bin:$PATH"
```

### Adding Custom Functions

Edit `~/.bashrc.d/functions.bash`:

Adding the tree "`###`" under the function name makes so it shows if you run the command `function`, it lists all the functions and a short description.

```bash
function my_function() {
    ### short informatiove description
    echo "This is my function"
    # Your code here
}
```

### Modifying Package Manager Behavior

Edit `~/.bashrc.d/pkg_aliases.bash` to customize package commands or add new distros.

## Troubleshooting

### Aliases Not Working

```bash
# Check if pkg_aliases.bash is sourced
type install

# If "not found", manually source:
source ~/dotfiles/.bashrc.d/pkg_aliases.bash
set_package_aliases

# Then reload bashrc
source ~/.bashrc
```

### Symlinks Not Created

```bash
# Check if files exist in repo
ls -la ~/dotfiles/.bashrc

# Manually create symlink
ln -sf ~/dotfiles/.bashrc ~/.bashrc
```

### Permission Denied Errors

The installer needs sudo for package installation. Run:
```bash
sudo -v  # Verify sudo access
./RunMe.sh
```

### Package Installation Fails

1. Check your internet connection
2. Update package lists manually:
   ```bash
   sudo apt-get update  # Debian/Ubuntu
   sudo dnf check-update  # Fedora/RHEL
   ```
3. Try installing packages manually:
   ```bash
   sudo apt-get install -y curl htop vim
   ```

### "Unknown OS" Error

Your distribution isn't detected. Edit `pkg_aliases.bash` and add your distro to the case statement:

```bash
case "$DISTRO_BASE_LOCAL" in
    yourdistro*)
        install() { sudo your-pkg-manager install "$@"; }
        # ... add other functions
        ;;
```

### Colors Not Working

Check if color definitions exist:
```bash
grep -r "GREEN=" ~/dotfiles/.bashrc.d/
```

If missing, add to `colorcodes.bash`:
```bash
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export NC='\033[0m'
```

## Advanced Configuration

### WSL-Specific Setup

The installer automatically configures `.bash_profile` to load `.bashrc` for WSL compatibility.

### Tmux Integration

If you use tmux, additional setup:
```bash
# Install tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Inside tmux, press: prefix + I (capital i) to install plugins
```

### SSH Key Management

The `.bashrc` includes keychain integration for SSH keys. Install keychain:
```bash
install keychain
```

Then add your SSH keys:
```bash
ssh-add ~/.ssh/id_ed25519
```

## Maintenance

### Updating Dotfiles

```bash
cd ~/dotfiles
git pull origin main
source ~/.bashrc  # Reload configuration
```

### Backing (push to repo, you need to fork it first) Up Current Config

```bash
cd ~/dotfiles
git add -A
git commit -m "Update configuration"
git push
```

### Cleaning Old Backups

```bash
# Remove old backup files (older than 30 days)
find ~/dotfiles/old-files -name "*.bak-*" -mtime +30 -delete
find ~/dotfiles/install-*.log -type d -mtime +30 -exec rm -rf {} +
```

## Files Modified by Installer

The installer creates/modifies these files in your home directory:

- `~/.bashrc` → symlink to `~/dotfiles/.bashrc`
- `~/.bash_profile` → symlink to `~/dotfiles/.bash_profile`
- `~/.profile` → symlink to `~/dotfiles/.profile`
- `~/.inputrc` → symlink to `~/dotfiles/.inputrc`

Original files are backed up to `~/dotfiles/old-files/` with timestamps.

## Security Notes

- 🔒 The installer never modifies system files (only user home directory)
- 🔐 Sudo is only used for package installation
- 💾 All changes are logged to `install-YYYY-MM-DD.log/`
- 🔄 Original files are backed up before any changes
- ⚠️ Review `RunMe.sh` before running if you're security-conscious

## Getting Help

1. **Check logs**: `~/dotfiles/install-YYYY-MM-DD.log/`
2. **Review this README**: Most issues are covered above
3. **Check bash syntax**: `bash -n ~/.bashrc`
4. **Test in debug mode**: `DEBUG=1 ./RunMe.sh`
5. **Open an issue**: [Your repo's issue tracker]

## License

[Your license here]

### Some links to where I've ~~stolen~~ borrowed stuff & inspiration from
* [https://sanctum.geek.nz/arabesque/shell-config-subfiles/](https://sanctum.geek.nz/arabesque/shell-config-subfiles/)
* [https://remysharp.com/2018/08/23/cli-improved](https://remysharp.com/2018/08/23/cli-improved)
* [https://github.com/kenorb/dotfiles/blob/master/.bash_functions](https://github.com/kenorb/dotfiles/blob/master/.bash_functions)
* [https://github.com/kenorb/dotfiles/blob/master/.bash_aliases](https://github.com/kenorb/dotfiles/blob/master/.bash_aliases)
* [https://github.com/sharkdp/bat/](https://github.com/sharkdp/bat/)
* [https://github.com/denilsonsa/prettyping.git](https://github.com/denilsonsa/prettyping.git) ~/dotfiles/extras/prettyping


## Credits

Created and maintained by Patrick Österlund. If you feel like it, send a dime:
[[PayPal](https://paypal.me/fotosbypatrick)] 

---

**Last Updated**: January 2026