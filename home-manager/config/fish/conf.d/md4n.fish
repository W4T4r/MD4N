set -g fish_greeting ""

set -l generated_env_file "$HOME/.config/fish/md4n.generated.fish"
if test -f "$generated_env_file"
    source "$generated_env_file"
else
    set -gx PATH $HOME/.local/bin $PATH
    set -gx NIXPKGS_ALLOW_UNFREE 1
end

set -l local_files \
    "$HOME/.config/fish/local.env.fish" \
    "$HOME/.config/fish/local.aliases.fish" \
    "$HOME/.config/fish/local.functions.fish"

for file in $local_files
    if test -f "$file"
        source "$file"
    end
end

eval (direnv hook fish)

if test "$TERM" != "dumb"
    starship init fish | source
end

fastfetch
