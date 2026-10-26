# cato-motion-studio-install

Il primo passo per installare il Cato Motion Studio (spot video con Claude Code e HyperFrames) su un Mac. Apri il Terminale e incolla:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/AppaltiGPT/cato-motion-studio-install/main/install.sh)"
```

Installa quello che manca (Homebrew, la CLI di GitHub con il login, Node, FFmpeg, Claude Code, il plugin HyperFrames), scarica lo studio privato sulla Scrivania e apre Claude Code con `/setup-studio`. Rilanciarlo è sicuro: rifà solo quello che manca e aggiorna lo studio.

Dopo la prima volta non serve più: ogni volta che apri Claude Code nello studio, lo studio si aggiorna da solo.

Se ti dice che il tuo utente non vede il repository, chiedi l'accesso a `cato-motion-studio` e rilancia lo stesso comando.

Questo repository è pubblico perché serve **prima** di avere accesso a qualcosa. Per questo contiene solo `install.sh`, che non porta segreti: lo studio vero resta privato.
