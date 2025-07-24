# Oh-my-zsh installation path
ZSH=/usr/share/oh-my-zsh/


# Powerlevel10k theme path
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme


# List of plugins used
plugins=( git sudo zsh-256color zsh-autosuggestions zsh-syntax-highlighting )
source $ZSH/oh-my-zsh.sh

# In case a command is not found, try to find the package that has it
function command_not_found_handler {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf 'zsh: command not found: %s\n' "$1"
    local entries=( ${(f)"$(/usr/bin/pacman -F --machinereadable -- "/usr/bin/$1")"} )
    if (( ${#entries[@]} )) ; then
        printf "${bright}$1${reset} may be found in the following packages:\n"
        local pkg
        for entry in "${entries[@]}" ; do
            local fields=( ${(0)entry} )
            if [[ "$pkg" != "${fields[2]}" ]]; then
                printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
            fi
            printf '    /%s\n' "${fields[4]}"
            pkg="${fields[2]}"
        done
    fi
    return 127
}

# Detect AUR wrapper
if pacman -Qi yay &>/dev/null; then
   aurhelper="yay"
elif pacman -Qi paru &>/dev/null; then
   aurhelper="paru"
fi

function in {
    local -a inPkg=("$@")
    local -a arch=()
    local -a aur=()

    for pkg in "${inPkg[@]}"; do
        if pacman -Si "${pkg}" &>/dev/null; then
            arch+=("${pkg}")
        else
            aur+=("${pkg}")
        fi
    done

    if [[ ${#arch[@]} -gt 0 ]]; then
        sudo pacman -S "${arch[@]}"
    fi

    if [[ ${#aur[@]} -gt 0 ]]; then
        ${aurhelper} -S "${aur[@]}"
    fi
}

# Helpful aliases
alias vim='nvim'
alias c='clear' # clear terminal
alias l='eza -lh --icons=auto' # long list
alias ls='eza -1 --icons=auto' # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto' # long list dirs
alias lt='eza --icons=auto --tree' # list folder as tree
alias un='$aurhelper -Rns' # uninstall package
alias up='$aurhelper -Syu' # update system/package/aur
alias pl='$aurhelper -Qs' # list installed package
alias pa='$aurhelper -Ss' # list available package
alias pc='$aurhelper -Sc' # remove unused cache
alias po='$aurhelper -Qtdq | $aurhelper -Rns -' # remove unused packages, also try > $aurhelper -Qqd | $aurhelper -Rsu --print -
alias vc='code' # gui code editor
alias cds='cd ~/.backups/scripts'
alias cdi='cd ~/.backups/scripts/install_scripts'
alias cdc='cd ~/.backups/scripts/config_scripts'
alias cde='cd ~/.backups/scripts/execution_scripts'
alias cdb='cd ~/.backups/scripts/backup-scripts'
alias vz='vim ~/.zshrc'
alias vh='vim ~/.config/hypr/keybindings.conf'
alias pr='~/.backups/scripts/execution_scripts/terminal_prayer_times.sh'
alias sp='spotdl download'
alias spl='~/.backups/scripts/execution_scripts/spotdl_listsongs.sh'
alias gitbare='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias gitbare-addlist='while IFS= read -r file; do git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME add -f "$HOME/$file"; done < ~/.dotfiles-include.txt'
alias gitbare-status='gitbare status -s'
alias gitbare-sync='gitbare commit -am "update dotfiles" && gitbare push'




# Directory navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'
alias cdh='cd ~/.config/hypr'
alias cda='cd ~/troubleshoots_backups/archlinux_troubleshoots'
alias cdi='cd ~/.backups/scripts/install_scripts'
alias cdt='cd ~/.backups/scripts/troubleshoots_scripts'
alias cdc='cd ~/.backups/scripts/config_scripts'


alias mkdir='mkdir -p'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Display Pokemon
#pokemon-colorscripts --no-title -r 1,3,6
#

chx() {
  [[ $1 ]] || { echo "Usage: mkshx <file.sh>"; return 1; }
  install -m755 /dev/stdin "$1" <<EOF
#!/usr/bin/env bash
set -euo pipefail

echo "Hello from \$0"
EOF
  ${EDITOR:-nvim} "$1"
}


lfcd () {
  tmp="$(mktemp)"
  lf -last-dir-path="$tmp" "$@"
  if [ -f "$tmp" ]; then
    dir="$(cat "$tmp")"
    [ -d "$dir" ] && cd "$dir"
    rm -f "$tmp"
  fi
}


bindkey -v

bindkey -v
bindkey '^[m' backward-char
bindkey '^[n' down-line-or-history
bindkey '^[e' up-line-or-history
bindkey '^[i' forward-char

export QT_QPA_PLATFORMTHEME=gtk3

# Created by `pipx` on 2025-06-26 17:27:07
export PATH="$PATH:/home/ibrahim/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
export KICAD_SYMBOL_DIR=/usr/share/kicad/symbols
export KICAD_FOOTPRINT_DIR=/usr/share/kicad/footprints
export KICAD_3DMODEL_DIR=/usr/share/kicad/3dmodels
export KICAD_SYMBOL_DIR=/usr/share/kicad/symbols
export KICAD_FOOTPRINT_DIR=/usr/share/kicad/footprints
export KICAD_3DMODEL_DIR=/usr/share/kicad/3dmodels
export EDITOR=vim
export VISUAL=vim



#if ! pgrep -f "pypr" > /dev/null; then
#    pypr &
#fi
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
# Backup management aliases
alias backup-status="sudo /usr/local/bin/backup-scripts/backup-status"
alias backup-snapshot="sudo /usr/local/bin/backup-scripts/btrfs-snapshot"
alias backup-cleanup="sudo /usr/local/bin/backup-scripts/btrfs-cleanup"
alias backup-borg="sudo /usr/local/bin/backup-scripts/borg-backup"
alias backup-list="sudo borg list /mnt/backup/borg-repo"




# Rsync backup management aliases
alias rsync-dotfiles="sudo /usr/local/bin/backup-scripts/rsync-backup dotfiles"
alias rsync-home="sudo /usr/local/bin/backup-scripts/rsync-backup home"
alias rsync-system="sudo /usr/local/bin/backup-scripts/rsync-backup system"
alias rsync-all="sudo /usr/local/bin/backup-scripts/rsync-backup all"
alias combined-backup="sudo /usr/local/bin/backup-scripts/combined-backup"
alias backup-browse="ls -la /mnt/backup/ && echo && cat /mnt/backup/rsync-backup-info.txt"
