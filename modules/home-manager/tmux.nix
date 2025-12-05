{ pkgs, ... }:
let
  tmux-super-fingers = pkgs.tmuxPlugins.mkTmuxPlugin
    {
      pluginName = "tmux-super-fingers";
      version = "unstable-2023-01-06";
      src = pkgs.fetchFromGitHub {
        owner = "artemave";
        repo = "tmux_super_fingers";
        rev = "2c12044984124e74e21a5a87d00f844083e4bdf7";
        sha256 = "sha256-cPZCV8xk9QpU49/7H8iGhQYK6JwWjviL29eWabuqruc=";
      };
    };
in
{
  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 50000;
    mouse = true;
    keyMode = "vi";

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      better-mouse-mode
      vim-tmux-navigator
    ];

    extraConfig = ''
      # Terminal and color settings
      set -g default-terminal "xterm-256color"
      set -ga terminal-overrides ",*256col*:Tc"
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
      set-environment -g COLORTERM "truecolor"

      # Window management
      set -g renumber-windows on

      # Vi mode key bindings for copy mode
      bind-key -T copy-mode-vi v send -X begin-selection
      bind-key -T copy-mode-vi V send -X select-line
      set -s copy-command 'xclip -in -selection clipboard'
      bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

      # Yazi image preview support
      set -g allow-passthrough on
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM

      # Dotbar-style status bar configuration with prefix highlighting
      set -g status-position bottom
      set -g status-justify centre
      set -g status-style 'bg=#303446 fg=#626880'

      # Status left with prefix highlighting - exact tmux-dotbar implementation
      set -g status-left '#[bg=#303446,fg=#9399b2]#{?client_prefix,, #S }#[bg=#cba6f7,fg=#303446,bold]#{?client_prefix, #S ,}#[default]'
      set -g status-left-length 20

      # Status right with prefix highlighting
      set -g status-right '#[bg=#303446,fg=#9399b2]#{?client_prefix,, %H:%M }#[bg=#cba6f7,fg=#303446,bold]#{?client_prefix, %H:%M ,}#[default]'
      set -g status-right-length 20

      set -g window-status-current-style 'bg=#303446 fg=#c6d0f5'
      set -g window-status-style 'bg=#303446 fg=#626880'
      set -g window-status-format ' #W '
      set -g window-status-current-format ' #W '
      set -g window-status-separator ' • '

      # Pane borders
      set -g pane-border-style 'fg=#626880'
      set -g pane-active-border-style 'fg=#c6d0f5'

      # Message styling
      set -g message-style 'bg=#303446 fg=#c6d0f5'
      set -g message-command-style 'bg=#303446 fg=#c6d0f5'
    '';
  };
}
