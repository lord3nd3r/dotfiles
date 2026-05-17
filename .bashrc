# ╔═══════════════════════════════════════════════════════════════╗
# ║  ~/.bashrc — 3ND3R SYSTEMS · v2.0                           ║
# ║  Rewritten: 2026-05-16 · Original: 2012-05-26               ║
# ╚═══════════════════════════════════════════════════════════════╝

# === INTERACTIVE GUARD ================================================
case $- in *i*) ;; *) return;; esac

# === GLOBAL DEFS ======================================================
[ -f /etc/bash.bashrc ] && . /etc/bash.bashrc

# === SHELL OPTIONS ====================================================
shopt -s histappend      # Append to history, don't overwrite
shopt -s checkwinsize    # Update LINES/COLUMNS after each command
shopt -s autocd          # Type dir name to cd into it
shopt -s cdspell         # Autocorrect minor cd typos
shopt -s dirspell        # Autocorrect dir name typos in completion
shopt -s globstar        # ** matches recursively
shopt -s nocaseglob      # Case-insensitive globbing

# === HISTORY ==========================================================
HISTCONTROL=ignoreboth:erasedups   # No dupes, no leading-space cmds
HISTSIZE=50000
HISTFILESIZE=100000
HISTTIMEFORMAT="%F %T  "           # Timestamp every command
HISTIGNORE="ls:ll:la:cd:pwd:exit:clear:cls:h:q"  # Skip boring cmds

# === COMPLETION =======================================================
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# === COLOR SUPPORT ====================================================
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi
export TERM=xterm-256color

# === EDITOR & PAGER ===================================================
export EDITOR=nano
export VISUAL=nano
export PAGER='less -R'
export LESS='-R -F -X'
export MANPAGER='less -R'

# === PATH =============================================================
[ -d "$HOME/bin" ]            && PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ]     && PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.lmstudio/bin" ]  && PATH="$HOME/.lmstudio/bin:$PATH"

# === SECRETS (chmod 600) ==============================================
[ -f ~/.secrets ] && . ~/.secrets

# === ALIASES & FUNCTIONS ==============================================
[ -f ~/.alias ]     && . ~/.alias
[ -f ~/.functions ] && . ~/.functions

# === DISABLE VENV AUTO-PROMPT (we handle it in our prompt) ============
export VIRTUAL_ENV_DISABLE_PROMPT=1

# ======================================================================
#  ⚡ THE PROMPT — CYBERPUNK HUD
# ======================================================================
# Adapts for root (red/fire theme) vs normal user (cyan/neon theme)
# Features: git branch+status, command timer, exit codes, venv, jobs, SSH

# --- Timer via DEBUG trap ---
__prompt_timer_start() {
    __prompt_timer=${__prompt_timer:-$SECONDS}
}
trap '__prompt_timer_start' DEBUG

# --- Main prompt builder (runs as PROMPT_COMMAND) ---
__build_prompt() {
    local EXIT=$?                    # MUST be first line
    # Timer
    local elapsed=$(( SECONDS - ${__prompt_timer:-$SECONDS} ))
    unset __prompt_timer

    # --- Color Palette (adapts to root) ---
    local RST='\[\e[0m\]'
    local BOLD='\[\e[1m\]'
    local DIM='\[\e[2m\]'

    if [ "$EUID" -eq 0 ]; then
        # ROOT — Red/fire theme
        local C_USER='\[\e[38;5;196m\]'     # Bright red
        local C_HOST='\[\e[38;5;208m\]'     # Orange
        local C_DIR='\[\e[38;5;214m\]'      # Gold
        local C_LINE='\[\e[38;5;52m\]'      # Dark red
        local C_BRACKET='\[\e[38;5;88m\]'   # Dim red
        local C_OK='\[\e[38;5;208m\]'       # Orange
        local C_FAIL='\[\e[38;5;196m\]'     # Bright red
        local C_ACCENT='\[\e[38;5;160m\]'   # Red accent
        local ICON="🔥"
        local PROMPT_SYM="⚡"
    else
        # NORMAL USER — Cyan/neon theme
        local C_USER='\[\e[38;5;141m\]'     # Neon purple
        local C_HOST='\[\e[38;5;51m\]'      # Neon cyan
        local C_DIR='\[\e[38;5;33m\]'       # Bright blue
        local C_LINE='\[\e[38;5;237m\]'     # Dim gray
        local C_BRACKET='\[\e[38;5;240m\]'  # Gray
        local C_OK='\[\e[38;5;82m\]'        # Neon green
        local C_FAIL='\[\e[38;5;196m\]'     # Bright red
        local C_ACCENT='\[\e[38;5;37m\]'    # Teal
        local ICON="⚡"
        local PROMPT_SYM="❯"
    fi

    local C_GIT_CLEAN='\[\e[38;5;82m\]'     # Green
    local C_GIT_DIRTY='\[\e[38;5;226m\]'    # Yellow
    local C_GIT_DETACH='\[\e[38;5;196m\]'   # Red
    local C_TIMER='\[\e[38;5;245m\]'        # Dim white
    local C_VENV='\[\e[38;5;208m\]'         # Orange
    local C_JOBS='\[\e[38;5;141m\]'         # Purple
    local C_SSH='\[\e[38;5;226m\]'          # Yellow

    # --- Shorthand helpers ---
    local L="${C_LINE}─${RST}"
    local LB="${C_BRACKET}[${RST}"
    local RB="${C_BRACKET}]${RST}"

    # --- Segments ---
    # SSH indicator
    local ssh_seg=""
    [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] && \
        ssh_seg="${L}${LB}${C_SSH}${BOLD}📡 SSH${RST}${RB}"

    # User@Host
    local user_seg="${LB}${C_USER}${BOLD}${ICON} \\u${RST}${C_BRACKET}@${RST}${C_HOST}${BOLD}\\h${RST}${RB}"

    # Directory
    local dir_seg="${L}${LB}${C_DIR}${BOLD}\\w${RST}${RB}"

    # Git
    local git_seg=""
    if command -v git &>/dev/null; then
        local branch
        branch=$(git symbolic-ref --short HEAD 2>/dev/null) || \
        branch=$(git describe --tags --exact-match 2>/dev/null) || \
        branch=$(git rev-parse --short HEAD 2>/dev/null)
        if [ -n "$branch" ]; then
            local flags=""
            local gs
            gs=$(git status --porcelain=v1 2>/dev/null)
            [ -n "$(echo "$gs" | grep '^[MADRC]')" ]  && flags+="+"
            [ -n "$(echo "$gs" | grep '^ [MD]')" ]    && flags+="!"
            [ -n "$(echo "$gs" | grep '^\?\?')" ]     && flags+="?"
            if [ -z "$flags" ]; then
                git_seg="${L}${LB}${C_GIT_CLEAN} ${branch} ✓${RST}${RB}"
            else
                git_seg="${L}${LB}${C_GIT_DIRTY} ${branch} ${flags}${RST}${RB}"
            fi
        fi
    fi

    # Python venv
    local venv_seg=""
    [ -n "$VIRTUAL_ENV" ] && \
        venv_seg="${L}${LB}${C_VENV}🐍 $(basename "$VIRTUAL_ENV")${RST}${RB}"

    # Background jobs
    local job_count
    job_count=$(jobs -rp 2>/dev/null | wc -l)
    local jobs_seg=""
    (( job_count > 0 )) && \
        jobs_seg="${L}${LB}${C_JOBS}⚙ ${job_count} job$( (( job_count > 1 )) && echo s)${RST}${RB}"

    # Command timer (only show if > 0s)
    local timer_seg=""
    if (( elapsed > 0 )); then
        local t_str
        if (( elapsed >= 3600 )); then
            t_str="$(( elapsed / 3600 ))h$(( (elapsed % 3600) / 60 ))m"
        elif (( elapsed >= 60 )); then
            t_str="$(( elapsed / 60 ))m$(( elapsed % 60 ))s"
        else
            t_str="${elapsed}s"
        fi
        timer_seg="${L}${LB}${C_TIMER}⏱ ${t_str}${RST}${RB}"
    fi

    # Exit code (only show on failure)
    local exit_seg=""
    (( EXIT != 0 )) && \
        exit_seg="${L}${LB}${C_FAIL}${BOLD}✘ ${EXIT}${RST}${RB}"

    # --- Prompt symbol ---
    local sym
    if (( EXIT == 0 )); then
        sym="${C_OK}${BOLD}${PROMPT_SYM}${PROMPT_SYM}${PROMPT_SYM}${RST}"
    else
        sym="${C_FAIL}${BOLD}${PROMPT_SYM}${PROMPT_SYM}${PROMPT_SYM}${RST}"
    fi

    # --- Assemble ---
    PS1="\n${C_ACCENT}╭${RST}${L}${ssh_seg}${user_seg}${dir_seg}${git_seg}${venv_seg}${jobs_seg}${timer_seg}${exit_seg}"
    PS1+="\n${C_ACCENT}╰${RST}${L}${sym} "
}

PROMPT_COMMAND='__build_prompt'

# ======================================================================
#  WELCOME BANNER
# ======================================================================
__show_welcome() {
    local C='\e[38;5;51m'   P='\e[38;5;141m'   D='\e[2m'
    local B='\e[1m'         R='\e[0m'           G='\e[38;5;82m'
    local RD='\e[38;5;196m' O='\e[38;5;208m'

    local kern; kern=$(uname -r | cut -d- -f1)
    local up;   up=$(uptime -p 2>/dev/null | sed 's/up //' || echo "?")
    local mem;  mem=$(free -h 2>/dev/null | awk '/^Mem:/{printf "%s/%s", $3, $2}')
    local load; load=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)

    if [ "$EUID" -eq 0 ]; then
        echo -e ""
        echo -e "  ${RD}${B}┌──────────────────────────────────────────┐${R}"
        echo -e "  ${RD}${B}│${R}  ${O}${B}🔥 ROOT ACCESS · 3ND3R SYSTEMS${R}          ${RD}${B}│${R}"
        echo -e "  ${RD}${B}│${R}  ${D}Linux ${kern} · up ${up}${R}"
        echo -e "  ${RD}${B}│${R}  ${D}Mem: ${mem} · Load: ${load}${R}"
        echo -e "  ${RD}${B}│${R}  ${RD}${B}⚠  YOU ARE ROOT. TREAD CAREFULLY.${R}        ${RD}${B}│${R}"
        echo -e "  ${RD}${B}└──────────────────────────────────────────┘${R}"
    else
        echo -e ""
        echo -e "  ${C}${B}┌──────────────────────────────────────────┐${R}"
        echo -e "  ${C}${B}│${R}  ${P}${B}⚡ 3ND3R SYSTEMS${R} ${D}· Terminal v2.0${R}        ${C}${B}│${R}"
        echo -e "  ${C}${B}│${R}  ${D}Linux ${kern} · up ${up}${R}"
        echo -e "  ${C}${B}│${R}  ${D}Mem: ${mem} · Load: ${load}${R}"
        echo -e "  ${C}${B}└──────────────────────────────────────────┘${R}"
    fi
    echo ""
}
__show_welcome
unset -f __show_welcome

# === NVM (lazy-loaded for fast shell startup) =========================
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    __lazy_nvm() {
        unset -f nvm node npm npx __lazy_nvm
        \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    }
    nvm()  { __lazy_nvm; nvm "$@"; }
    node() { __lazy_nvm; node "$@"; }
    npm()  { __lazy_nvm; npm "$@"; }
    npx()  { __lazy_nvm; npx "$@"; }
fi

# === CARGO ============================================================
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
