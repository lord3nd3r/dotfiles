#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════╗
# ║  install-skel.sh — Make 3ND3R dotfiles the default for all   ║
# ║  new user accounts by installing them into /etc/skel/        ║
# ╚═══════════════════════════════════════════════════════════════╝
# Usage: sudo bash ~/scripts/install-skel.sh
#
# /etc/skel/ is the "skeleton" directory — its contents are copied
# into every new user's home directory when created via useradd or
# adduser. After running this, any `sudo adduser newguy` will get
# the full 3ND3R shell experience out of the box.

set -euo pipefail

# --- Require root ---
if [ "$EUID" -ne 0 ]; then
    echo "⚠  Run as root: sudo bash $0"
    exit 1
fi

# --- Locate source dotfiles ---
# Try the calling user's home first, fall back to /home/ender
CALLER_HOME=$(eval echo "~${SUDO_USER:-ender}")
SRC="${CALLER_HOME}"

for f in .bashrc .alias .functions; do
    if [ ! -f "${SRC}/${f}" ]; then
        echo "✘ Missing ${SRC}/${f} — are the dotfiles installed for ${SUDO_USER:-ender}?"
        exit 1
    fi
done

SKEL="/etc/skel"
BACKUP="${SKEL}.bak.$(date +%s)"

# --- Backup existing skel ---
echo "📦 Backing up ${SKEL} → ${BACKUP}"
cp -a "$SKEL" "$BACKUP"

# --- Install dotfiles ---
echo "📋 Installing dotfiles to ${SKEL}/"

install -m 644 "${SRC}/.bashrc"       "${SKEL}/.bashrc"
install -m 644 "${SRC}/.bash_profile" "${SKEL}/.bash_profile"
install -m 644 "${SRC}/.profile"      "${SKEL}/.profile"
install -m 644 "${SRC}/.alias"        "${SKEL}/.alias"
install -m 644 "${SRC}/.functions"    "${SKEL}/.functions"

# --- Create a stub .secrets file (empty, locked down) ---
# New users get the file structure but no actual keys
cat > "${SKEL}/.secrets" << 'SECRETS_EOF'
# ~/.secrets — Store API keys and sensitive env vars here
# This file is chmod 600 and excluded from version control.
#
# Example:
#   export PIRATE_API_KEY="your-key-here"
#   export OPENAI_KEY="your-key-here"
SECRETS_EOF
chmod 600 "${SKEL}/.secrets"

# --- Install scripts ---
echo "📋 Installing scripts to ${SKEL}/scripts/"
mkdir -p "${SKEL}/scripts"

for script in s.sh weather.sh forecast.sh forecast2.sh install-root-shell.sh; do
    if [ -f "${SRC}/scripts/${script}" ]; then
        install -m 755 "${SRC}/scripts/${script}" "${SKEL}/scripts/${script}"
    fi
done

# --- Create a stub .bash_logout ---
cat > "${SKEL}/.bash_logout" << 'LOGOUT_EOF'
# ~/.bash_logout — Executed on logout
# Clear sensitive env vars from memory
unset PIRATE_API_KEY OPENAI_KEY 2>/dev/null
LOGOUT_EOF
chmod 644 "${SKEL}/.bash_logout"

# --- Summary ---
echo ""
echo "✅ Skeleton directory updated. New users will get:"
echo ""
ls -la "${SKEL}/" | grep -v '^\(total\|d\)' | awk '{printf "   %-6s %s\n", $5, $NF}'
echo ""
ls -la "${SKEL}/scripts/" 2>/dev/null | grep -v '^\(total\|d\)' | awk '{printf "   %-6s scripts/%s\n", $5, $NF}'
echo ""
echo "   Test it:  sudo adduser testuser"
echo "   Backup:   ${BACKUP}"
