set -g fish_greeting ""

set -l shared_env_file "$HOME/.config/md4n/generated/fish/env.fish"
if test -f "$shared_env_file"
    source "$shared_env_file"
else
    set -gx PATH $HOME/.local/bin $PATH
    set -gx NIXPKGS_ALLOW_UNFREE 1
end

eval (direnv hook fish)

if test "$TERM" != "dumb"
    starship init fish | source
end

fastfetch

set -l local_conf_dir "$HOME/.config/md4n/local/fish/conf.d"
if test -d "$local_conf_dir"
    for file in $local_conf_dir/*.fish
        if test -f "$file"
            source "$file"
        end
    end
end
