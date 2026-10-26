#!/usr/bin/env bash
source "$PIT_SOURCE/src/lib.sh"
pit_init_variables
trap 'exit' HUP TERM INT
for nom in A B C; do
    while [[ ! -f $PIT_ETAT/pids/brouilleur_$nom ]]; do pit_pause 0.05; done
done
while [[ -d $PIT_ETAT && ! -d $PIT_ETAT/termine ]]; do
    brouille=0
    for nom in A B C; do pit_actif "brouilleur_$nom" && brouille=1; done
    fichier=$PIT_RACINE/niveau_V/signal.txt
    if ((brouille)); then
        printf 'Signal brouillé : %s\n' "$(pit_chaine 16 '#@%&?$*~')" > "$fichier.tmp"
    else
        printf 'Signal propre - Fragment 5 : %s\n' "${PIT_CODE:4:1}" > "$fichier.tmp"
        : > "$PIT_ETAT/valides/5"
    fi
    mv -f -- "$fichier.tmp" "$fichier"
    pit_pause 1
done
