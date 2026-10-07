# Things to do / fix for .tmux.conf

## Completed (May 8, 2026)
 - [x] Fix keybindings for htop/btop (prefix h/H/o/O) — correct popup vs newwindow modes
 - [x] Fix task-monitor script argument passing (exit code 2 error) — was unquoted ARGS variable
 - [x] Remove broken weather display (wttr.in API curl errors) — removed #{forecast} from status-right
 - [x] Update window/pane numbering in start_tmux.sh to match base-index 1 configuration

## TODO
 - [x] If all apps installed, from the is_it_installed(), then it should just report "All apps installed; (<appname(s)>)" instead of listing them all again. @done (2026-10-08, tmux_installer.sh v2.5.0 check_dependencies())
 - [ ] Check for variable set from ~/.dotfiles/run_me_first.sh. If it's then skip this script and exit gracefully.
       (2026-10-08: ON HOLD, needs a decision — run_me_first.sh never calls this script and doesn't install
       Coffee/~/.config/tmux links/custom menus, so skipping the whole script would leave those missing.
       The original pain — re-doing/clobbering links — is gone: v2.4.1 leaves correct links alone.
       Better option: run_me_first.sh calls tmux_installer.sh as its tmux step.)
 - [ ] Set this check in run_me_first.sh so it runs before anything else.

## Completed (June 20, 2026)
 - [x] Auto-start ~/.start_tmux.sh from .bashrc on first interactive login (guarded: PS1 set, BASHRC_SOURCED=1, not already in tmux)

## Completed (October 7, 2026)
 - [x] Never start tmux inside tmux: shared tmux_guard.inc (process ancestry, root/sudo, ssh-to-self)
 - [x] start_tmux.sh v1.0.0 on the Vibecoding template (flags, --dry-run, pane ids)
 - [x] Continuum autosave wired into status-right; leftover tmux.service removed; @continuum-boot off
 - [x] Tools menu (menus/tools.sh) — launchers moved out of one-off keys; C-a double bind fixed
 - [x] Copy to Windows clipboard via clip.exe (works in conhost too); copy-mode `y`
 - [x] tmux_installer.sh v2.4.1: copies custom menus, stops re-creating correct links

## tmux-menus
1) Create a meny for different scripts (from ~/bash) that can easily be exeecuted from the meny
    2 olika, en för Docker containers och en för "vanliga script"
    (Status 2026-10-07: the menu framework is in place — add new menus as tmux/menus/*.sh
    next to tools.sh and re-run tmux_installer.sh. Docker + scripts menus not built yet.)
    
