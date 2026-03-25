set -g fish_greeting ""
set -gx PATH $HOME/.local/bin $PATH
set -gx NIXPKGS_ALLOW_UNFREE 1

eval (direnv hook fish)

if test "$TERM" != "dumb"
    starship init fish | source
end

fastfetch

set -l local_conf_dir "$HOME/.config/fish/conf.d/local"
if test -d "$local_conf_dir"
    for file in $local_conf_dir/*.fish
        if test -f "$file"
            source "$file"
        end
    end
end
