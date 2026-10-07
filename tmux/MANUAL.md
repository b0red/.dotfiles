# tmux — my manual

*For when I forget. Last checked against the live config: 2026-10-08.*
Open it from tmux: **`Ctrl-a \` → Custom items → Tools → `?`** · From a shell: **`tmux-manual`**

---

## 0. The three things to remember

| Key | What |
|-----|------|
| **`Ctrl-a`** | The **prefix**. Press it, let go, then press the key. Written `C-a` below. |
| **`C-a \`** | **The menu** — almost everything is in there (also `C-a Enter`). |
| **`C-a r`** | Reload the config after editing `.tmux.conf`. |

Lost? `C-a ?` lists every key · `C-a /` then a key = what does that key do?

---

## 1. Starting, sessions, leaving

A **session** is a workspace that keeps running when you close the terminal. A **client** is a terminal attached to one.

| I want to… | Do this |
|------------|---------|
| Start tmux | Opens by itself in a new terminal (prompt: **C**ustom layout or **P**lain, custom after 3 s) |
| Start the 4-pane layout by hand | `~/.start_tmux.sh` (`--dry-run` to preview, `--help`) |
| Leave tmux but keep everything running | `C-a d` (detach) |
| Get back in | open a new terminal, or `~/.start_tmux.sh` |
| See all sessions | `C-a s` (tree with preview) · or menu → Custom items → **Sessions** |
| Switch session | `C-a s`, or `C-a (` / `C-a )` prev/next, `C-a L` last one |
| Rename session | `C-a $` |
| Kick another terminal off a session | menu → **Sessions** → pick session → *Detach its clients* · or `C-a D`, highlight, `d` |

The custom layout (session `linux`): left = `~/bin`, top-right = `~/docker/compose` (or `~`), bottom-right = **mc** (focused), bottom = `task list`.
tmux never starts inside tmux (even after `sudo -i`/`su -`/ssh to this machine) — see `tmux/tmux_guard.inc`.

---

## 2. Windows (tabs along the bottom)

| I want to… | Keys |
|------------|------|
| New window (same folder) | `C-a c` |
| Next / previous | `C-a n` / `C-a p` |
| Jump to window 1–9 | `C-a 1` … `C-a 9` (numbering starts at 1) |
| Back to the last window | **`C-a C-a`** |
| Rename | `C-a ,` |
| Pick from a list | `C-a w` |
| Find by text | `C-a f` |
| Close (asks first) | `C-a X` (or `C-a &`) |

---

## 3. Panes (splits)

| I want to… | Keys |
|------------|------|
| Split side by side (same folder) | `C-a \|` |
| Split top/bottom (same folder) | `C-a -` |
| Move between panes | **`Alt` + arrow** (no prefix!) · or `C-a o` |
| Back to the last pane | `C-a ;` |
| Zoom one pane full-screen (toggle) | `C-a z` |
| Zoom into its own window, unzoom back | `C-a Z` (power-zoom) |
| Show pane numbers | `C-a q` |
| Swap panes | `C-a {` / `C-a }` |
| Move pane to its own window | `C-a !` |
| Cycle layouts | `C-a Space` · fixed layouts `C-a Alt-1` … `Alt-7` |
| Close pane (asks first) | `C-a x` |
| Resize | drag the border with the mouse |

---

## 4. Copy & paste

Copies go to the **Windows clipboard** (via `clip.exe`), so `Ctrl-V` works anywhere in Windows.

| I want to… | Do this |
|------------|---------|
| Copy with the mouse | **drag with the left button, let go** (no Shift) — stays inside the pane |
| Copy with the keyboard | `C-a [` → move → `Space` to start → move → **`y`** (or `Enter`) |
| Scroll back | mouse wheel, or `C-a [` then arrows / `PgUp` (`q` to leave) |
| Paste inside tmux | `C-a ]` |
| Old way: Shift + drag | only works in **Windows Terminal** (not the plain Ubuntu console window) |

---

## 5. The menu — `C-a \`

The main menu has Panes, Windows, Sessions, Paste buffers, Search, Layouts, Reload, Detach… — the letters shown next to each entry are its shortcut. **Custom items** (`+`) holds mine:

### Tools (`T`)
| Key | What |
|-----|------|
| `h` / `H` | htop — popup / window |
| `b` / `B` | btop — popup / window |
| `l` / `L` | lazyports — popup / window |
| `t` / `T` | task monitor / overview |
| **`s`** | **run a `~/bin` script** (picker, see below) |
| `m` | open a man page |
| `u` | URLs in this pane (only shown if `urlview` is installed) |
| `c` | Coffee plugin manager |
| `?` | **this manual** |

**Script picker** (`s`): type to filter. **Enter** = dry-run in a new window (scripts without `--dry-run` open their source instead) · **Ctrl-X** = really run it (asks for arguments, then y/N) · **Ctrl-V** = read the source · `Esc` = close.

### Sessions (`S`)
Every session with window count, attached terminals and `<- current`. Pick one → **Switch to it** / **Detach its clients** (asks; the session keeps running). Also: detach this terminal (`d`), clients list (`c`, press `d` on one), detach all *other* clients (`o`), session tree (`t`).

### Docker (`D`)
Runs on **dellubuntu over ssh** (from this WSL), or the local Docker on a machine that has one — the menu shows which.
`c` **Containers…** → type to filter → **Enter** logs · **Ctrl-S** shell · **Ctrl-T** stats · **Ctrl-O** inspect · **Ctrl-R** restart (asks y/N).
`a` all containers (`docker ps -a`) · `l` lazydocker (if installed on the Docker host).

---

## 6. Quick popups (no menu needed)

| Keys | What |
|------|------|
| `C-a h` | htop |
| `C-a b` | btop |
| `C-a l` | lazyports |
| `C-a t` / `C-a T` | task monitor / overview |
| `C-a Tab` | file tree sidebar (`C-a Backspace` = open and jump into it) |
| `C-a C` | Coffee plugin manager (install / update / remove plugins) |

---

## 7. Saving & restoring sessions

| What | How |
|------|-----|
| Automatic save | every **15 min** (tmux-continuum) — nothing to do |
| Automatic restore | when tmux starts fresh (e.g. after a reboot) |
| Save **now** | **`C-a C-s`** |
| Restore last save | `C-a C-r` |

Saves live in `~/.tmux/resurrect/`.

---

## 8. The status bar

**Left:** `Online: Yes/No` (internet reachable) · date and time.
**Right:** `^A` when the prefix is pressed · weather (Stockholm) · Claude usage · date · CPU and RAM (colour = load) · user · host · IP (switches between WAN and LAN every 5 min).
Window tabs show an icon for the program running (nerd-font plugin — needs a Nerd Font in the terminal).

---

## 9. Plugins — what each one is for

| Plugin | Gives me | How I use it |
|--------|----------|--------------|
| tmux-menus | the menu | `C-a \` or `C-a Enter` |
| tmux-resurrect | save/restore sessions | `C-a C-s` / `C-a C-r` |
| tmux-continuum | auto-save every 15 min + restore at start | automatic |
| tmux-sidebar | file tree on the left | `C-a Tab` |
| tmux-power-zoom | zoom a pane into its own window | `C-a Z` |
| tmux-task-monitor | process/resource popups | `C-a t` / `C-a T` |
| tmux-prefix-highlight | `^A` in the status bar while the prefix is active | automatic |
| tmux-cpu | CPU / RAM in the status bar | automatic |
| tmux-online-status | `Online: Yes/No` | automatic |
| tmux-weather | weather in the status bar (wttr.in) | automatic |
| tmux-claude-usage | Claude usage in the status bar | automatic |
| tmux-nerd-font-window-name | icons in window names | automatic |
| tmux-mullvad | Mullvad VPN status variables (not shown in the bar right now) | — |
| tmux-ip-toggle *(mine)* | WAN/LAN IP in the status bar | automatic |

Plugins are managed by **Coffee**: `C-a C` (or `coffee list` / `coffee install` / `coffee update` in a shell). Each plugin is a `.yaml` file in `~/.dotfiles/tmux/coffee/plugins/`. Add a YAML → `coffee install`. Remove: delete the YAML **and** `coffee remove <name>`.

---

## 10. When something is off

| Problem | Try |
|---------|-----|
| A key does nothing | Did you press `Ctrl-a` first, and let go? `C-a /` + the key shows what it's bound to |
| Edited the config | `C-a r` · errors: `C-a ~` (messages) |
| Two status bars | a tmux inside tmux — usually an ssh session to a machine that starts its own tmux |
| Copy doesn't reach Windows | drag **without** Shift, or `C-a [` … `y` |
| Menu doesn't show my new menu | `~/.dotfiles/tmux/tmux_installer.sh` (copies `tmux/menus/*.sh`), then `C-a r` |
| Docker menu says "cannot run docker" | `ssh dellubuntu docker ps` must work without a password |
| New shells feel slow | they shouldn't (~0.7 s); `BASHRC_SHOW_LOADING=1 bash` shows what loads |
| Start over | `tmux kill-server` (closes **everything**), then a new terminal |

---

## 11. Where things are

| File | What |
|------|------|
| `~/.dotfiles/tmux/.tmux.conf` | the config (`~/.tmux.conf` points here) |
| `~/.dotfiles/tmux/MANUAL.md` | this manual |
| `~/.dotfiles/tmux/menus/` | my menus (tools, sessions, docker) |
| `~/.dotfiles/tmux/start_tmux.sh` | the 4-pane layout (`~/.start_tmux.sh`) |
| `~/.dotfiles/tmux/script_picker.sh` | the `~/bin` script picker |
| `~/.dotfiles/tmux/docker_actions.sh` | what the Docker menu runs |
| `~/.dotfiles/tmux/tmux_installer.sh` | (re)install: links, Coffee, menus |
| `~/.dotfiles/tmux/QUICK_REFERENCE.md` | install & troubleshooting notes |
