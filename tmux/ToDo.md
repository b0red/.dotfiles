# Things to do / fix for .tmux.conf

## Completed (May 8, 2026)
 - [x] Fix keybindings for htop/btop (prefix h/H/o/O) — correct popup vs newwindow modes
 - [x] Fix task-monitor script argument passing (exit code 2 error) — was unquoted ARGS variable
 - [x] Remove broken weather display (wttr.in API curl errors) — removed #{forecast} from status-right
 - [x] Update window/pane numbering in start_tmux.sh to match base-index 1 configuration

## TODO
 - [ ] If all apps installed, from the is_it_installed(), then it should just report "All apps installed; (<appname(s)>)" instead of listing them all again.
 - [ ] Check for variable set from ~/.dotfiles/run_me_first.sh. If it's then skip this script and exit gracefully.
 - [ ] Set this check in run_me_first.sh so it runs before anything else.

## tmux-menus
1) Create a meny for different scripts (from ~/bash) that can easily be exeecuted from the meny
    2 olika, en för Docker containers och en för "vanliga script"
    
