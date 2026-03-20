# Login-shell environment.

[ -r "$HOME/.profile" ] && . "$HOME/.profile"

typeset -U path PATH
path=(${path:#\~/.dotnet/tools})
[[ -d "$HOME/.dotnet/tools" ]] && path=("$HOME/.dotnet/tools" $path)

export PATH
