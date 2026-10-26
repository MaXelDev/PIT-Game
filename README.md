# PIT-Game — Désamorce la bombe

Jeu de révision des commandes Bash du module PIT (Passeport Informatique Télécom), Département Réseaux et Télécommunications, INSA Lyon. Il se joue entièrement dans un terminal Linux.

Une bombe est cachée dans le laboratoire. Vous avez une heure pour trouver son code de 8 caractères, un caractère par niveau, sur 8 missions de difficulté croissante. Écrivez ensuite le code dans `code.txt` et lancez `verifier`.

## Prérequis

- Linux avec `bash` 4 ou plus récent ;
- GNU coreutils (`stat`, `touch -d`, `mv`, `cp`, `cksum`…), `find`, `grep`, `sed`, `tar`, `gzip`, `ps` (procps) et `setsid` (util-linux) ;
- un éditeur `vi` (ou `vim`) ;
- aucun droit administrateur : le jeu n'utilise jamais `sudo`.

## Installation et lancement

```bash
git clone https://github.com/MaXelDev/PIT-Game.git
cd PIT-Game
bash play.sh
```

Le jeu ne dépend pas du bit exécutable des fichiers du dépôt et ne modifie jamais le dépôt :

| Élément | Emplacement |
|---|---|
| Dossier de jeu visible | `${TMPDIR:-/tmp}/pit_bombe_$(id -u)/racine` |
| État interne (code, pénalités, PIDs, références) | `${TMPDIR:-/tmp}/.pit_etat_$(id -u)` |

Le jeu s'ouvre dans un shell dédié, appelé « environnement virtuel ». Les changements de `PATH`, les fonctions et les commandes masquées n'existent que dans ce shell. Votre terminal normal n'est jamais modifié. Une seule partie peut tourner à la fois ; un état abandonné est détecté puis nettoyé au lancement suivant.

## Règles du jeu

1. Lisez `instruction` dans chaque dossier `niveau_I` à `niveau_VIII` avec `cat`.
2. Chaque mission donne un fragment du code. Le fragment N est seulement accessible au niveau N.
3. Le code contient 8 caractères alphanumériques, sans caractères ambigus (`0`, `O`, `1`, `l`, `I`).
4. Écrivez le code dans `racine/code.txt`, puis lancez `bash verifier` ou `./verifier`.
5. Le fichier `minuteur` contient les secondes restantes. Le supprimer, le rendre invalide ou neutraliser l'horloge déclenche l'explosion.

Le prompt affiche le temps restant : `[💣 MM:SS] racine/niveau_I $`.

## Commandes spéciales

Elles fonctionnent depuis n'importe quel dossier du shell de jeu.

| Commande | Effet |
|---|---|
| `bomb` | Temps restant, barre colorée, numéro de série, niveaux validés, erreurs, tentatives, voyants et position |
| `restart` | Nouvelle partie : nouveau code, nouvelles énigmes, minuteur et compteurs remis à zéro, retour à la racine |
| `quit` | Quitte la partie et supprime tous les fichiers temporaires et processus du jeu |
| `reset nN` | Régénère gratuitement le niveau N (1 à 8), avec le même fragment, puis entre dans ce niveau |

La commande système `reset` est masquée dans le jeu : `reset` seul affiche l'aide. Pour rétablir un terminal brouillé, utilisez `tput reset` ou `stty sane`. `clear` reste disponible.

## Pénalités

| Action | Pénalité |
|---|---|
| Mauvais code final | −5 min (300 s) |
| Tuer l'émetteur du niveau V | −1 min (60 s), puis relance automatique |
| Tuer ou suspendre l'horloge, supprimer le minuteur | Explosion immédiate |
| `reset nN` | Aucune |

Un code vide, resté à `________` ou au mauvais format n'est pas pénalisé.

## Niveaux

| Niveau | Thème | Commandes travaillées |
|---|---|---|
| I | Exploration | `cd`, `ls -l`, `ls -lh`, `ls -lS`, `ls -a`, `ls -R`, `cat` |
| II | Rangement | `mkdir`, `cp`, `mv`, `rm`, `rmdir`, `vi` |
| III | Journal des capteurs | `cat`, pipe `\|`, `grep`, `>`, `>>` |
| IV | Recherche dans l'arborescence | `find -name -size -mtime`, `mv`, `vi` |
| V | Processus | `ps aux`, `grep`, `kill`, `kill -STOP`, `kill -CONT`, `kill -l` |
| VI | Coffre | `ls -l`, `chmod`, `chown`, `echo $VAR`, `export` |
| VII | Archive | `tar -xzvf -C`, `find`, `vi`, `tar -czvf` |
| VIII | Boss final | Toutes les commandes précédentes |

Chaque niveau contient un vérificateur qui affiche une liste ✔/✘. Le fragment apparaît seulement lorsque tout est correct.

## Structure du dépôt

```text
PIT-Game/
├── README.md
├── .gitignore
├── play.sh                 # lanceur, isolement, nettoyage
├── src/
│   ├── lib.sh              # utilitaires communs
│   ├── generate.sh         # pit_generate et gen_I … gen_VIII
│   ├── rc.sh               # environnement virtuel du shell de jeu
│   ├── bin/                # bomb, reset, pit_restart, pit_reset_niveau, pit_verif
│   └── procs/              # horloge, brouilleurs, émetteur, perturbateur
└── docs/SOLUTIONS.md       # solutions détaillées
```

## Mode test

`PIT_DUREE` définit la durée en secondes (3600 par défaut) :

```bash
PIT_DUREE=120 bash play.sh
```

## Conseils

- Lisez toute l'instruction avant d'agir : les leurres sont volontaires.
- Utilisez `pwd`, `ls -la` et `bomb` pour vous repérer.
- Dans `vi` : `i` pour insérer, `Échap` pour revenir au mode normal, `dd` pour supprimer une ligne, `:wq` pour enregistrer et quitter.
- Ne remplacez jamais `PATH` sans conserver `$PATH`. `bomb`, `restart`, `quit` et `reset nN` restent utilisables même dans ce cas.

## Dépannage

| Problème | Solution |
|---|---|
| « Une partie est déjà en cours » | Fermez l'autre partie. Si elle a été tuée, relancez quelques secondes plus tard : l'état périmé est nettoyé. |
| Processus orphelin | Dans un terminal normal : `ps aux \| grep PIT-Game/src/procs`, puis `kill PID`. Le prochain lancement nettoie aussi l'ancien état. |
| Terminal brouillé après un `cat` sur un fichier binaire | `tput reset` ou `stty sane` (`reset` est masqué dans le jeu). |
| `vi` absent | Installez `vim` ou `vi` avec le gestionnaire de paquets de votre distribution. |

## Triche

Il est possible de tricher en lisant le code du dépôt, `docs/SOLUTIONS.md` ou les fichiers temporaires de `${TMPDIR:-/tmp}`. Le jeu sert à s'entraîner : vous apprendrez davantage en jouant honnêtement.

## Licence

Projet pédagogique distribué sous licence MIT. Vous pouvez l'utiliser, le modifier et le partager en conservant la mention de l'auteur.
