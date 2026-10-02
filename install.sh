#!/usr/bin/env bash
# install.sh — prepara il Cato Motion Studio su un Mac, da zero, con un solo comando:
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/AppaltiGPT/cato-motion-studio-install/main/install.sh)"
#
# Deve stare in un posto pubblico, perché serve PRIMA di avere accesso al repo privato. Per questo fa
# solo il minimo per arrivarci: Homebrew, la CLI di GitHub con il login, Claude Code, il clone. Poi
# apre Claude Code nella cartella con /setup-studio, che fa tutto il resto (Node, FFmpeg, plugin, test).
# Rilanciarlo è sicuro: rifà solo quello che manca e aggiorna la cartella.
set -euo pipefail
REPO="AppaltiGPT/cato-motion-studio"
DEST="${CATO_MOTION_DIR:-$HOME/Desktop/cato-motion-studio}"

# In prova non si tocca ~/.zprofile della persona che lancia la prova.
profilo() { [ "${CATO_INSTALL_PROVA:-0}" = 1 ] && return 0; grep -qsF "$1" "$HOME/.zprofile" || printf '\n%s\n' "$1" >> "$HOME/.zprofile"; }
say() { printf '\n▸ %s\n' "$*"; }
ok()  { printf '  ✔ %s\n' "$*"; }
die() { printf '\n  ✗ %s\n' "$*" >&2; exit 1; }

# `CATO_INSTALL_PROVA=1` salta i controlli sull'ambiente e l'apertura finale di Claude Code: serve alle
# prove automatiche. `CATO_MOTION_SRC` clona da un'altra sorgente (una cartella locale), sempre per le prove.
PROVA="${CATO_INSTALL_PROVA:-0}"
if [ "$PROVA" != 1 ]; then
  [ "$(uname -s)" = Darwin ] || die "questo installer è per macOS"
  # Con `curl … | bash` lo stdin è lo script stesso: Homebrew e i login non potrebbero chiedere niente.
  [ -t 0 ] || die "lancialo così, non con una pipe:
    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/AppaltiGPT/cato-motion-studio-install/main/install.sh)\""
fi

say "Homebrew"
if ! command -v brew > /dev/null 2>&1; then
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }; done
fi
if ! command -v brew > /dev/null 2>&1; then
  echo "  lo installo: il Mac ti chiede la password una volta"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }; done
  command -v brew > /dev/null 2>&1 || die "Homebrew non risulta installato: rilancia questo comando"
fi
# Senza questa riga, nel prossimo Terminale `brew` e quello che installa non ci sarebbero.
riga="eval \"\$($(command -v brew) shellenv)\""
profilo "$riga"
ok "$(brew --version | head -1)"

say "GitHub"
command -v gh > /dev/null 2>&1 || brew install gh > /dev/null
if ! gh auth status -h github.com > /dev/null 2>&1; then
  echo "  si apre il browser: entra con il tuo utente GitHub"
  gh auth login -h github.com -p https -w
fi
gh auth setup-git > /dev/null 2>&1 || true
utente="$(gh api user -q .login 2> /dev/null || echo "?")"
ok "sei $utente"

say "Node e FFmpeg"
command -v node > /dev/null 2>&1 || brew install node > /dev/null
command -v ffmpeg > /dev/null 2>&1 || brew install ffmpeg > /dev/null
ok "node $(node -v), $(ffmpeg -version | head -1 | cut -d' ' -f1-3)"

say "Claude Code"
if ! command -v claude > /dev/null 2>&1; then
  echo "  lo installo con l'installer ufficiale"
  curl -fsSL https://claude.ai/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
  riga='export PATH="$HOME/.local/bin:$PATH"'
  profilo "$riga"
  command -v claude > /dev/null 2>&1 || die "Claude Code non risulta installato: rilancia questo comando"
fi
ok "$(claude --version 2> /dev/null | head -1)"

say "Lo studio"
if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only -q || die "non riesco ad aggiornare $DEST: ci sono modifiche locali. Guarda 'git -C \"$DEST\" status'"
  ok "aggiornato in $DEST"
elif [ -n "${CATO_MOTION_SRC:-}" ]; then
  git clone -q "$CATO_MOTION_SRC" "$DEST"
  ok "clonato in $DEST (sorgente di prova)"
elif gh repo clone "$REPO" "$DEST" -- -q 2> /dev/null; then
  ok "clonato in $DEST"
else
  die "il tuo utente GitHub ($utente) non vede il repo $REPO. Chiedi l'accesso, poi rilancia questo comando."
fi

if [ "$PROVA" = 1 ]; then ok "prova: fermo qui, senza aprire Claude Code"; exit 0; fi
say "Apro Claude Code nello studio"
echo "  la prima volta ti chiede di entrare con il tuo account Claude di Cato,"
echo "  poi se ti fidi della cartella e se installare il plugin HyperFrames: rispondi sì."
cd "$DEST"
exec claude "/setup-studio"
