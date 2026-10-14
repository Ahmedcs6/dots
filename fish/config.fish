# aliases
alias u='sudo -E pacman -Syu'
alias i='sudo -E pacman -S'
alias r='sudo -E pacman -Rns'
alias s='sudo -E pacman -Ss'
alias ll="ls -lah"
alias la="ls -A"
alias l='ls -CF'
alias c='clear'
# alias mm='sudo mkdir /run/media/data; sudo mount /dev/nvme0n1p4 /run/media/data'
alias svu='sudo ip link set wlan0 down;sudo macchanger wlan0 -m, --mac=<Your MAC>;sudo ip link set wlan0 up'
alias graph='git log --oneline --graph --decorate --all'
alias nice='bat -l conf'
# [[ -z $DISPLAY ]] &&
if test (tty) = /dev/tty1
    exec start-hyprland
end

# Hide the fish greeting
set fish_greeting ""

# Use legacy fzf keybindings
set -g FZF_LEGACY_KEYBINDINGS 1

# Fish syntax highlighting
set -g fish_color_autosuggestion 555 brblack
set -g fish_color_cancel -r
set -g fish_color_command --bold
set -g fish_color_comment red
set -g fish_color_cwd green
set -g fish_color_cwd_root red
set -g fish_color_end brmagenta
set -g fish_color_error brred
set -g fish_color_escape bryellow --bold
set -g fish_color_history_current --bold
set -g fish_color_host normal
set -g fish_color_match --background=brblue
set -g fish_color_normal normal
set -g fish_color_operator bryellow
set -g fish_color_param cyan
set -g fish_color_quote yellow
set -g fish_color_redirection brblue
set -g fish_color_search_match bryellow '--background=brblack'
set -g fish_color_selection white --bold '--background=brblack'
set -g fish_color_user brgreen
set -g fish_color_valid_path --underline
set -Ux PATH $PATH ~/.dotnet/tools ~/bin
set -Ux PATH $PATH $HOME/.dotnet/tools
set -Ux PATH $PATH ~/.local/bin ~/bin
set -Ux SSL_CERT_DIR "$HOME/.aspnet/dev-certs/trust:/etc/ssl/certs"
set -Ux EDITOR neovide
set -U fish_greeting ""
set -x TERM kitty
# Kvantum theme for Qt apps
set -Ux QT_QPA_PLATFORMTHEME qt6ct
# Initialize Starship
starship init fish | source

# opencode
fish_add_path /home/ahmed/.opencode/bin
