# ⚡ 3ND3R SYSTEMS · Dotfiles v2.0

Cyberpunk-themed bash environment with dual-mode prompt, 130+ aliases, 20+ functions, and security-first secrets management.

![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-GPL--3.0-blue)

## 🎨 The Prompt

The prompt auto-detects **root vs normal user** and switches themes:

**Normal user** — Neon cyan/purple:
```
╭──[⚡ender@boston]─[~/projects/ibot]─[ main ✓]
╰──❯❯❯
```

**Root** — Red/fire:
```
╭──[🔥root@boston]─[/etc/nginx]─[✘ 1]
╰──⚡⚡⚡
```

**Full HUD** (all segments active):
```
╭──[📡 SSH]─[⚡ender@host]─[~/dir]─[ dev !?]─[🐍 venv]─[⚙ 2 jobs]─[⏱ 3s]─[✘ 127]
╰──❯❯❯
```

| Segment | Trigger |
|---|---|
| 📡 SSH | Connected via SSH |
| ⚡/🔥 user@host | Always (theme changes for root) |
| 📂 path | Always |
|  branch ✓/!?+ | Inside git repo (✓ clean, ! modified, ? untracked, + staged) |
| 🐍 venv | Python virtualenv active |
| ⚙ N jobs | Background jobs running |
| ⏱ Ns | Last command took >0 seconds |
| ✘ code | Last command failed |

## 📁 Files

```
.bashrc              # Main shell config + prompt engine
.bash_profile        # Login shell entry point
.profile             # Non-bash fallback
.alias               # 130+ aliases (git, docker, systemctl, apt, etc.)
.functions           # 20+ utility functions
.secrets             # ⛔ NOT TRACKED — API keys (chmod 600)
scripts/
├── s.sh             # SSH quick-connect menu
├── weather.sh       # Current weather (Pirate Weather API)
├── forecast.sh      # 10-day forecast (IRC-style single line)
├── forecast2.sh     # 10-day forecast (box-drawing 2-column)
├── install-root-shell.sh  # Install config to /root/
└── install-skel.sh        # Make dotfiles default for new users
```

## 🚀 Installation

```bash
git clone https://github.com/lord3nd3r/dotfiles ~/dotfiles
cd ~/dotfiles

# Symlink everything into place
ln -sf ~/dotfiles/.bashrc ~/.bashrc
ln -sf ~/dotfiles/.bash_profile ~/.bash_profile
ln -sf ~/dotfiles/.profile ~/.profile
ln -sf ~/dotfiles/.alias ~/.alias
ln -sf ~/dotfiles/.functions ~/.functions
cp -r ~/dotfiles/scripts ~/scripts

# Create your secrets file (not tracked by git)
cat > ~/.secrets << 'EOF'
export PIRATE_API_KEY="your-key-here"
export OPENAI_KEY="your-key-here"
EOF
chmod 600 ~/.secrets

# Reload
source ~/.bashrc
```

### Install for root
```bash
sudo bash ~/scripts/install-root-shell.sh
```

### Make default for all new users
Installs dotfiles into `/etc/skel/` so every `adduser` gets the full setup:
```bash
sudo bash ~/scripts/install-skel.sh
```

## 🔧 Key Features

### Aliases Highlights
| Alias | What it does |
|---|---|
| `please` | Re-run last command as `sudo` |
| `sc/scs/scr/sct/scl` | systemctl shortcuts |
| `dk/dkps/dkx/dkcu/dkcd` | Docker shortcuts |
| `gs/gd/gds/glog/gpf` | Git power aliases |
| `reload` | Source .bashrc |

### Functions Highlights
| Function | Usage |
|---|---|
| `extract <file>` | Universal archive extractor (17 formats) |
| `mkcd <dir>` | mkdir + cd |
| `psgrep <name>` | Find processes |
| `port <num>` | What's using this port? |
| `mark/jump/marks` | Directory bookmarks |
| `serve [port]` | Quick HTTP server |
| `sysinfo` | System summary |
| `calc "expr"` | Calculator |

### Performance
- **NVM lazy-loaded** — shell starts ~300ms faster
- **Git status** — only runs inside git repos, uses `--porcelain`
- **Welcome banner** — runs once, then unloads from memory

## 🔒 Security

API keys live in `~/.secrets` (chmod 600), which is `.gitignore`'d and never committed. The file is sourced by `.bashrc` at startup.

## 📜 History

- **v2.0** (2026-05-16) — Complete rewrite. Cyberpunk prompt, security hardening, lazy NVM, functions split out, skel installer for system-wide defaults.
- **v1.0** (2012-05-26) — Original `.bashrc` by 3nd3r. Still lives on as `.bashrc.old`.
