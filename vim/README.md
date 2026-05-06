# My .vimrc Configuration

This repository contains my Vim configuration using **vim-plug** as the plugin manager.

---

## Installation

### 1. Clone the repository
```bash
cd ~
git clone git@bitbucket.org:b0red/.vim.git ~/.vim
```

### 2. Create symbolic links for vimrc
```bash
ln -s ~/.vim/vimrc ~/.vimrc
ln -s ~/.vim/gvimrc ~/.gvimrc
```

### 3. Install vim-plug
If you don't have vim-plug installed yet:
```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

### 4. Install plugins
Open Vim and run:
```vim
:PlugInstall
```

---

## Plugin Manager: vim-plug

This configuration uses [vim-plug](https://github.com/junegunn/vim-plug) instead of Pathogen. Plugins are stored in `~/.vim/plugged/` (not `~/.vim/bundle/`).

### Installing a new plugin

1. Add the plugin to your `vimrc` file inside the `call plug#begin()` and `call plug#end()` block:
   ```vim
   Plug 'author/plugin-name'
   ```

2. Reload your vimrc or restart Vim, then run:
   ```vim
   :PlugInstall
   ```

**Example:**
```vim
call plug#begin()
Plug 'tpope/vim-surround'    " Add this line
call plug#end()
```

### Updating plugins

To update all plugins to their latest versions:
```vim
:PlugUpdate
```

To update vim-plug itself:
```vim
:PlugUpgrade
```

### Removing a plugin

1. Remove or comment out the plugin line in your vimrc:
   ```vim
   " Plug 'author/plugin-name'
   ```

2. Reload vimrc and run:
   ```vim
   :PlugClean
   ```

This will remove the plugin from `~/.vim/plugged/`

### Checking plugin status

View installed plugins and their status:
```vim
:PlugStatus
```

---

## Currently Installed Plugins

| Plugin | Description | Repository |
|--------|-------------|------------|
| **vim-fugitive** | Powerful Git integration for Vim | https://github.com/tpope/vim-fugitive |
| **NERDTree** | File system explorer sidebar | https://github.com/preservim/nerdtree |
| **auto-pairs** | Auto-close brackets, quotes, parentheses | https://github.com/jiangmiao/auto-pairs |
| **nerdcommenter** | Easy code commenting/uncommenting | https://github.com/preservim/nerdcommenter |
| **vim-afterglow** | Afterglow color scheme (dark theme) | https://github.com/danilo-augusto/vim-afterglow |

---

## Key Mappings & Features

### File Navigation
- `Ctrl+F` or `Ctrl+O` - Toggle NERDTree file explorer
- `:NERDTree` - Open NERDTree manually

### Code Editing
- `F7` - Auto-indent entire file (and return to cursor position)
- `F11` - Toggle paste mode (disables auto-indent for pasting)
- `\c<space>` - Toggle comment on current line/selection (nerdcommenter)

### Search
- `Ctrl+L` - Clear search highlighting
- `/pattern` - Search (case-insensitive unless pattern has uppercase)

### Git Integration (vim-fugitive)
- `:Git status` - Show Git status
- `:Git commit` - Git commit
- `:Git push` - Git push
- `:Git blame` - Show git blame for current file
- `:Gdiff` - Show diff in split view

### Other
- `Y` - Yank (copy) to end of line (like D and C)
- Mouse support enabled in all modes

---

## Configuration Highlights

### Indentation
- **Default:** 4 spaces (no tabs)
- **YAML/Ansible files:** 2 spaces (auto-detected)

### Appearance
- Line numbers enabled
- 256-color support
- Afterglow dark color scheme
- Italic comments
- Status line always visible

### Search
- Incremental highlighting
- Case-insensitive by default
- Smart case (case-sensitive if you use capitals)

### Usability
- Mouse support enabled
- Hidden buffers (switch files without saving)
- Visual bell instead of beep
- Enhanced command-line completion

---

## Migrating from Pathogen

If you previously used Pathogen (with `~/.vim/bundle/`):

1. **Your old plugins are no longer used.** The new config uses vim-plug with `~/.vim/plugged/`
2. **Safe to delete:** You can remove `~/.vim/bundle/` after confirming your new setup works:
   ```bash
   rm -rf ~/.vim/bundle
   ```
3. **Backup first (optional):**
   ```bash
   mv ~/.vim/bundle ~/.vim/bundle.backup
   ```

---

## Troubleshooting

### Plugins not working?
Make sure you've run `:PlugInstall` after updating your vimrc.

### Color scheme not loading?
Ensure the afterglow plugin is installed and you have 256-color terminal support:
```bash
echo $TERM  # Should show something like 'xterm-256color'
```

### NERDTree not opening?
Check that the plugin installed correctly with `:PlugStatus`

---

## Additional Resources

- [vim-plug documentation](https://github.com/junegunn/vim-plug)
- [Vim documentation](https://www.vim.org/docs.php)
- [NERDTree documentation](https://github.com/preservim/nerdtree/blob/master/doc/NERDTree.txt)
- [vim-fugitive documentation](https://github.com/tpope/vim-fugitive)

---

## Notes

- Configuration file is thoroughly commented - read through `vimrc` for detailed explanations
- Plugins are version-controlled via vim-plug (no git submodules needed)
- All settings optimized for modern development workflows
