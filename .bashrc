# ~/.bashrc: executed by bash for non-login shells.

# Ensure PATH is well defined
export PATH="$HOME/bin:/usr/local/bin:$PATH"

# Prompt customization using a modern, simplified approach
export PS1='\[\033[38;2;0;255;255m\]┌──(\[\033[38;5;39m\]\u\[\033[38;2;0;255;255m\]㉿\[\033[38;5;39m\]\h\[\033[38;2;0;255;255m\])✈️ \[\033[38;2;0;255;255m\][\[\033[38;5;39m\]\w\[\033[38;2;0;255;255m\]]\n\[\033[38;2;0;255;255m\]└─\[\033[38;5;39m\]ʕ •ᴥ•ʔっ \[\033[0m\]'

# Alias definitions
if [ -f "$HOME/.alias" ]; then
    source "$HOME/.alias"
fi

# Misc Options
umask 022
set -o emacs
bind 'set bell-style visible'
bind 'set show-all-if-ambiguous on'
bind 'set visible-stats on'

# InputRC Configuration
if [ -z "$INPUTRC" ] && [ ! -f "$HOME/.inputrc" ]; then
    export INPUTRC=/etc/inputrc
fi

# Check for interactive shell
if [[ $- != *i* ]]; then return; fi

# Check window size after each command
shopt -s checkwinsize

# Enable color support of ls and add handy aliases
if [ -x "$(command -v dircolors)" ]; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

# Load Bash Completion if available
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# Custom Functions
findgrep() {
    local pattern=$1
    [ -z "$pattern" ] && echo "Usage: findgrep <pattern>" && return 1
    find . -type f -exec grep -nH "$pattern" {} +
}

extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"   ;;
            *.tar.gz)    tar xzf "$1"   ;;
            *.bz2)       bunzip2 "$1"   ;;
            *.rar)       unrar x "$1"   ;;
            *.gz)        gunzip "$1"    ;;
            *.tar)       tar xf "$1"    ;;
            *.tbz2)      tar xjf "$1"   ;;
            *.tgz)       tar xzf "$1"   ;;
            *.zip)       unzip "$1"     ;;
            *.Z)         uncompress "$1";;
            *.7z)        7z x "$1"      ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Network information
netinfo() {
    echo "Network Information:"
    /sbin/ifconfig | grep "inet " | awk '{print $2}'
}

# History Configuration
HISTSIZE=10000
HISTFILESIZE=20000

# Terminal Colors (if applicable)
if [ "$TERM" = "linux" ]; then
    # Your color settings
    echo -en "\e]P0222222" # Example for setting color 0
    clear # Clear artifacts
fi

# Return to home directory by default
cd ~
