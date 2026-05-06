" ============================================================================
" VIMRC CONFIGURATION FILE
" ============================================================================
" Based on vim.wikia.com/wiki/Example_vimrc and custom configurations
" Last updated: January 2026
"
" This file configures Vim with modern features, plugins, and sensible defaults
" for a productive development environment.
" ============================================================================


" ============================================================================
" BASIC VIM SETUP
" ============================================================================

" Disable Vi compatibility mode - enables modern Vim features
set nocompatible

" Temporarily disable filetype detection (required before loading plugins)
filetype off


" ============================================================================
" PLUGIN MANAGER (vim-plug)
" ============================================================================
" vim-plug is a minimalist plugin manager for Vim
" Install plugins by running :PlugInstall in Vim

call plug#begin()

" Git integration - adds Git commands directly in Vim (:Git, :Gblame, etc.)
Plug 'tpope/vim-fugitive'

" File explorer sidebar - browse your project files
Plug 'preservim/nerdtree'

" Auto-close brackets, quotes, and parentheses as you type
Plug 'jiangmiao/auto-pairs'

" Easy commenting/uncommenting of code blocks
Plug 'preservim/nerdcommenter'

" Afterglow color scheme - a dark, vibrant theme
Plug 'danilo-augusto/vim-afterglow'

" Vim sensible defaults - sets up sensible defaults for Vim
Plug 'tpope/vim-sensible'

" Status line enhancement - light and configurable status line
Plug 'itchyny/lightline.vim'

call plug#end()

" Re-enable filetype detection, plugins, and intelligent indentation
filetype plugin indent on


" ============================================================================
" APPEARANCE & COLOR SCHEME
" ============================================================================

" Enable 256-color support in terminal
set t_Co=256

" Enable syntax highlighting
syntax on

" Set dark background (helps with color scheme rendering)
set background=dark

" Activate the Afterglow color scheme
colorscheme afterglow

" Make comments display in italics for better readability
let g:afterglow_italic_comments=1

" Display line numbers on the left side
set number

" Always show status line at the bottom (even with single window)
set laststatus=2

" Hide the mode indicator (-- INSERT --, etc.) since status line shows it
set noshowmode

" Show the cursor position (line, column) in the status line
set ruler

" Show partial commands in the last line of the screen (e.g., "d" when deleting)
set showcmd


" ============================================================================
" INDENTATION & TAB SETTINGS
" ============================================================================

" Use spaces instead of tab characters (recommended for most coding)
set expandtab

" Width of a TAB character when displayed (keep at 8, standard)
set tabstop=8

" Number of spaces to use for auto-indentation
set shiftwidth=4

" Number of spaces a TAB counts for while editing (0 = use tabstop value)
set softtabstop=4

" Smart tabbing - intelligently insert spaces at line beginnings
set smarttab

" Smart indentation - auto-indent after opening braces, etc.
set smartindent

" Keep same indentation when starting a new line (useful for plain text)
set autoindent

" Special indentation for YAML/Ansible files (2 spaces instead of 4)
autocmd FileType yaml setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab


" ============================================================================
" SEARCH SETTINGS
" ============================================================================

" Highlight search results as you type
set hlsearch

" Case-insensitive search by default
set ignorecase

" Override ignorecase if search contains uppercase letters (smart searching)
set smartcase


" ============================================================================
" USABILITY ENHANCEMENTS
" ============================================================================

" Allow switching buffers without saving (keeps undo history per buffer)
set hidden

" Enhanced command-line completion with menu
set wildmenu

" Allow backspace to delete over line breaks, auto-indent, and insert start point
set backspace=indent,eol,start

" Keep cursor in same column when moving between lines (when possible)
set nostartofline

" Ask to save changes instead of failing commands due to unsaved files
set confirm

" Use visual flash instead of beeping on errors
set visualbell

" Disable the visual bell flash completely (no flash, no beep)
set t_vb=

" Enable mouse support in all modes (normal, visual, insert, command-line)
set mouse=a

" Set command window height to 2 lines (reduces "Press ENTER" prompts)
set cmdheight=2

" Reduce timeout for key codes (faster <Esc> response, but keep mapping timeout)
set notimeout ttimeout ttimeoutlen=200

" Toggle paste mode with F11 (disables auto-indent when pasting from clipboard)
set pastetoggle=<F11>


" ============================================================================
" KEY MAPPINGS
" ============================================================================

" CTRL+F: Toggle NERDTree file explorer on/off
nnoremap <C-f> :NERDTreeToggle<CR>

" CTRL+O: Alternative mapping for NERDTree (kept for compatibility)
map <C-o> :NERDTreeToggle<CR>

" F7: Auto-indent entire file and return to original cursor position
" (mz = mark position, gg=G = indent from top to bottom, `z = return to mark)
map <F7> mzgg=G`z

" Y: Make Y behave like D and C (yank to end of line, not whole line)
map Y y$

" CTRL+L: Clear search highlighting (in addition to redrawing screen)
nnoremap <C-L> :nohl<CR><C-L>


" ============================================================================
" NOTES & REMINDERS
" ============================================================================
"
" Common commands to remember:
" - :PlugInstall        Install/update plugins
" - :NERDTree           Open file explorer
" - <C-f> or <C-o>      Toggle file explorer
" - <F7>                Auto-indent entire file
" - <F11>               Toggle paste mode
" - :nohl               Clear search highlighting
" - :set paste          Temporarily disable auto-indent for pasting
"
" Plugin-specific commands:
" - :Git status         Show Git status (vim-fugitive)
" - :Git commit         Git commit (vim-fugitive)
" - <leader>c<space>    Toggle comment (nerdcommenter, default leader is \)
"
" ============================================================================
