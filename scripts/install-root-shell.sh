#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════╗
# ║  install-root-shell.sh — Install 3ND3R shell config to root  ║
# ╚═══════════════════════════════════════════════════════════════╝
# Usage: sudo bash ~/scripts/install-root-shell.sh

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Run this as root: sudo bash $0"
    exit 1
fi

ENDER_HOME="/home/ender"

echo "📦 Backing up existing root configs..."
[ -f /root/.bashrc ]   && cp /root/.bashrc /root/.bashrc.bak.$(date +%s)
[ -f /root/.alias ]    && cp /root/.alias /root/.alias.bak.$(date +%s)

echo "📋 Installing .bashrc..."
cp "${ENDER_HOME}/.bashrc" /root/.bashrc

echo "📋 Installing .alias..."
cp "${ENDER_HOME}/.alias" /root/.alias

echo "📋 Installing .functions..."
cp "${ENDER_HOME}/.functions" /root/.functions

echo "📋 Installing .bash_profile..."
cat > /root/.bash_profile << 'EOF'
[ -f ~/.bashrc ] && . ~/.bashrc
EOF

echo "🔒 Setting permissions..."
chmod 644 /root/.bashrc /root/.alias /root/.functions /root/.bash_profile

# Root doesn't get the secrets file (no API keys needed for root)
# But create a stub so sourcing doesn't error
touch /root/.secrets
chmod 600 /root/.secrets

echo ""
echo "✅ Root shell installed! The prompt auto-detects root and uses"
echo "   the 🔥 fire theme. Open a new root shell to see it."
echo ""
echo "   Try: sudo -i"
