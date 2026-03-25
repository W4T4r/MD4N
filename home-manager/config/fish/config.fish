# ~/.config/fish/config.fish
set -g fish_greeting ""
set -gx PATH $HOME/.local/bin $PATH
set -gx NIXPKGS_ALLOW_UNFREE 1
eval (direnv hook fish)
fastfetch

if test "$TERM" != "dumb"
    starship init fish | source
end
