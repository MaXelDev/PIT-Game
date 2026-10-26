#!/usr/bin/env bash
# Lanceur isolé : toutes les écritures de partie restent dans le répertoire temporaire.
set -u
PIT_SOURCE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
export PIT_SOURCE
source "$PIT_SOURCE/src/lib.sh"
PIT_DUREE=${PIT_DUREE:-3600}
[[ $PIT_DUREE =~ ^[1-9][0-9]{0,6}$ ]] || { printf 'PIT_DUREE doit être un entier de 1 à 9999999.\n'; exit 1; }
[[ -t 0 && -t 1 ]] || { printf 'Un terminal interactif est nécessaire.\n'; exit 1; }
for outil in bash stat touch tar gzip find ps setsid mkfifo od diff grep sed tr cp mv chmod id date readlink; do
    command -v "$outil" >/dev/null || { printf 'Commande requise absente : %s\n' "$outil"; exit 1; }
done
command -v vi >/dev/null || printf "Attention : vi est absent ; installez-le pour les missions d'édition.\n"
base=$(cd -- "${TMPDIR:-/tmp}" && pwd -P) || exit 1
PIT_ETAT=$base/.pit_etat_$(id -u)
PIT_PARENT=$base/pit_bombe_$(id -u)
PIT_RACINE=$PIT_PARENT/racine
export PIT_ETAT PIT_RACINE PIT_PARENT PIT_DUREE
# Un état récent sans propriétaire est une initialisation concurrente.
if ! mkdir -m 700 -- "$PIT_ETAT" 2>/dev/null; then
    [[ -d $PIT_ETAT && ! -L $PIT_ETAT && -O $PIT_ETAT ]] || { printf 'État temporaire non sûr.\n'; exit 1; }
    if pit_vivant lanceur || { [[ ! -f $PIT_ETAT/pids/lanceur ]] && (( $(date +%s) - $(stat -c %Y "$PIT_ETAT") < 5 )); }; then
        printf 'Une partie est déjà en cours.\n'; exit 1
    fi
    for ancien in "$PIT_ETAT"/pids/*; do [[ -f $ancien ]] && pit_stop "${ancien##*/}"; done
    rm -rf -- "$PIT_ETAT"
    mkdir -m 700 -- "$PIT_ETAT" || exit 1
fi
umask 077
mkdir -p "$PIT_ETAT/pids" "$PIT_ETAT/valides" "$PIT_ETAT/ref" "$PIT_ETAT/bin"
printf '%s %s\n' "$$" "$(pit_identite "$$")" > "$PIT_ETAT/pids/lanceur"
nettoyer() {
    trap '' HUP TERM
    local f issue=abandon
    : > "$PIT_ETAT/arret" 2>/dev/null
    [[ -f $PIT_ETAT/issue ]] && read -r issue < "$PIT_ETAT/issue"
    for f in "$PIT_ETAT"/pids/*; do [[ -f $f && ${f##*/} != lanceur ]] && pit_stop "${f##*/}"; done
    wait 2>/dev/null || :
    [[ -d $PIT_PARENT && ! -L $PIT_PARENT && -O $PIT_PARENT ]] && pit_effacer "$PIT_PARENT"
    pit_effacer "$PIT_ETAT"
    case $issue in victoire) printf '\nBombe désamorcée. Bravo, agent.\n';; explosion) printf '\nLa bombe a explosé.\n';; *) printf '\nPartie abandonnée.\n';; esac
    printf '\nFin de partie : %s. Aucun fichier de jeu conservé.\n' "$issue"
}
trap nettoyer EXIT
trap 'exit 129' HUP
trap 'exit 143' TERM
trap ':' INT
[[ ! -L $PIT_PARENT ]] || { printf 'Racine temporaire non sûre.\n'; exit 1; }
mkdir -m 700 "$PIT_PARENT" 2>/dev/null || :
[[ -O $PIT_PARENT ]] || exit 1
# Les dossiers privés protègent l'état ; les droits de jeu restent classiques.
umask 022
mkfifo "$PIT_ETAT/attente"
exec 9<> "$PIT_ETAT/attente"
tty > "$PIT_ETAT/tty"
cp "$PIT_SOURCE"/src/bin/* "$PIT_ETAT/bin/"
chmod 700 "$PIT_ETAT"/bin/*
source "$PIT_SOURCE/src/generate.sh"
pit_generate || exit 1
printf '\nOPÉRATION PIT — La bombe du laboratoire\n'
printf 'Huit missions, huit caractères, %s pour désamorcer la bombe.\n' "$(pit_temps "$PIT_DUREE")"
printf 'Lisez chaque instruction avec cat. Code final dans code.txt, puis bash verifier.\n'
printf 'Partout : bomb | restart | quit | reset n1 … reset n8. clear reste disponible.\n'
printf 'Mauvais code : −300 s ; émetteur tué : −60 s. Reset de niveau gratuit.\n'
printf 'Ne tuez/suspendez jamais horloge : explosion. Le terminal normal reste intact.\n\n'
pit_demarrer horloge horloge.sh
pit_processus_niveau 5
pit_processus_niveau 8
# Shell au premier plan : Ctrl-C reste fonctionnel pour les commandes du joueur.
bash --noprofile --rcfile "$PIT_SOURCE/src/rc.sh" -i
