# Default refresh interval (set to 5s if not already set)
# Use tmux format conditional to provide a safe default when the option is empty
set -g status-interval '#{?@ip_toggle_interval,#{@ip_toggle_interval},5}'

# Use your dotfiles path
set -g status-right "#(~/.dotfiles/tmux/coffee/plugins/tmux-ip-toggle/tmux-ip_toggle.sh)"
set -g status-right "#(~/.dotfiles/tmux/coffee/plugins/tmux-ip-toggle/tmux-ip_toggle.sh)"
