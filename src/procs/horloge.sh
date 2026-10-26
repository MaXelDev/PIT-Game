#!/usr/bin/env bash
# Horloge : décompte, pénalités, surveillance de l'émetteur et du lanceur.
source "$PIT_SOURCE/src/lib.sh"
pit_init_variables
arret_legitime() { [[ ! -d $PIT_ETAT || -e $PIT_ETAT/arret || -d $PIT_ETAT/maintenance || -d $PIT_ETAT/termine ]]; }
# Un signal hors arrêt prévu est un sabotage.
sabotage() { arret_legitime || pit_fin explosion 'horloge neutralisée'; exit 0; }
trap sabotage HUP TERM INT
orphelin() {
    # Lanceur disparu (kill -9) : extinction et nettoyage complets.
    local f
    : > "$PIT_ETAT/arret"
    for f in "$PIT_ETAT"/pids/*; do [[ ${f##*/} == horloge ]] || pit_stop "${f##*/}"; done
    pit_effacer "$PIT_PARENT"; pit_effacer "$PIT_ETAT"; exit 0
}
tic() {
    local n perte=1 valeur
    n=$(pit_minuteur) || { pit_fin explosion 'minuteur supprimé ou invalide'; return 1; }
    pit_verrou || return 1
    mv -- "$PIT_ETAT/penalites" "$PIT_ETAT/consommees"
    : > "$PIT_ETAT/penalites"
    pit_deverrou
    while read -r valeur; do ((perte+=valeur)); done < "$PIT_ETAT/consommees"
    n=$((n-perte)); ((n<0)) && n=0
    printf '%s\n' "$n" > "$PIT_ETAT/minuteur.tmp"
    mv -f -- "$PIT_ETAT/minuteur.tmp" "$PIT_RACINE/minuteur"
    ((n>0)) || { pit_fin explosion 'temps écoulé'; return 1; }
}
surveiller() {
    pit_vivant lanceur || orphelin
    [[ ! -d $PIT_ETAT/maintenance ]] || return 0
    [[ -f $PIT_SOURCE/src/procs/emetteur.sh ]] || return 0
    if ! pit_vivant emetteur && [[ ! -d $PIT_ETAT/maintenance ]]; then
        pit_penalite 60 'émetteur tué'
        pit_demarrer emetteur emetteur.sh
    fi
}
while [[ -d $PIT_ETAT && ! -d $PIT_ETAT/termine ]]; do
    pit_pause 1
    [[ -d $PIT_ETAT && ! -d $PIT_ETAT/termine && ! -e $PIT_ETAT/arret ]] || break
    surveiller
    [[ -d $PIT_ETAT/maintenance ]] && continue
    tic || break
done
