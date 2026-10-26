# Bibliothèque commune : aucun changement du terminal appelant.
# shellcheck shell=bash
PIT_ROMAINS=(I II III IV V VI VII VIII)
PIT_PATH_SYSTEME=${PIT_PATH_SYSTEME:-$PATH}
export PIT_PATH_SYSTEME
# La FIFO évite des processus sleep visibles ; sleep reste un repli sûr.
pit_pause() { local r; read -r -t "${1:-1}" -u 9 _pit_attente 2>/dev/null; r=$?; ((r > 128)) || sleep "${1:-1}"; }
pit_temps() { local n=${1:-0}; (( n < 0 )) && n=0; printf '%02d:%02d' "$((n/60))" "$((n%60))"; }
pit_aleatoire() { local alphabet=$1; printf '%s' "${alphabet:RANDOM%${#alphabet}:1}"; }
pit_chaine() { local i; for ((i=0;i<$1;i++)); do pit_aleatoire "${2:-abcdefghjkmnpqrstuvwxyz23456789}"; done; }
# L'identité de naissance évite de tuer un PID réattribué.
pit_identite() { local ligne; [[ -r /proc/$1/stat ]] || return 1; read -r ligne < "/proc/$1/stat" || return 1; ligne=${ligne##*) }; read -r -a _pit_champs <<< "$ligne"; printf '%s' "${_pit_champs[19]}"; }
pit_etat_proc() { local ligne; [[ -r /proc/$1/stat ]] || return 1; read -r ligne < "/proc/$1/stat" || return 1; ligne=${ligne##*) }; printf '%s' "${ligne%% *}"; }
pit_pid() { local p b; [[ -f $PIT_ETAT/pids/$1 ]] || return 1; read -r p b < "$PIT_ETAT/pids/$1"; [[ $(pit_identite "$p") == "$b" ]] || return 1; printf '%s' "$p"; }
pit_actif() { local p s; p=$(pit_pid "$1") || return 1; s=$(pit_etat_proc "$p") || return 1; [[ $s != Z && $s != X && $s != T && $s != t ]]; }
pit_vivant() { local p s; p=$(pit_pid "$1") || return 1; s=$(pit_etat_proc "$p") || return 1; [[ $s != Z && $s != X ]]; }
pit_stop() {
    local p i; p=$(pit_pid "$1") || { rm -f -- "$PIT_ETAT/pids/$1"; return 0; }
    kill -HUP "$p" 2>/dev/null || :; kill -TERM "$p" 2>/dev/null || :; kill -CONT "$p" 2>/dev/null || :
    for ((i=0;i<50;i++)); do pit_vivant "$1" || break; pit_pause 0.02; done
    pit_vivant "$1" && kill -KILL "$p" 2>/dev/null
    rm -f -- "$PIT_ETAT/pids/$1"
}
pit_demarrer() {
    local nom=$1 script=$2; shift 2
    [[ -f $PIT_SOURCE/src/procs/$script ]] || return 0
    # Le sous-shell parent disparaît : pas de messages de jobs ni de zombie durable.
    (
        setsid "$BASH" "$PIT_SOURCE/src/procs/$script" "$@" </dev/null >/dev/null 2>&1 &
        p=$!; b=$(pit_identite "$p")
        printf '%s %s\n' "$p" "$b" > "$PIT_ETAT/pids/$nom.tmp"
        mv -f -- "$PIT_ETAT/pids/$nom.tmp" "$PIT_ETAT/pids/$nom"
    )
}
pit_arreter_niveau() { local n=$1 x; case $n in 5) for x in emetteur brouilleur_A brouilleur_B brouilleur_C; do pit_stop "$x"; done;; 8) pit_stop perturbateur;; esac; }
pit_processus_niveau() {
    case $1 in
        5) local x; for x in A B C; do pit_demarrer "brouilleur_$x" brouilleur.sh "$x"; done; pit_demarrer emetteur emetteur.sh;;
        8) pit_demarrer perturbateur perturbateur.sh;;
    esac
}
# Les pénalités et leur consommation sont sérialisées autour du renommage.
pit_verrou() { while ! mkdir "$PIT_ETAT/verrou" 2>/dev/null; do [[ -d $PIT_ETAT ]] || return 1; pit_pause 0.02; done; }
pit_deverrou() { rmdir "$PIT_ETAT/verrou" 2>/dev/null || :; }
pit_penalite() {
    pit_verrou || return 1
    printf '%s\n' "$1" >> "$PIT_ETAT/penalites"
    printf '%s %s\n' "$1" "$2" >> "$PIT_ETAT/erreurs"
    pit_deverrou
}
pit_minuteur() { local n; [[ -f $PIT_RACINE/minuteur && ! -L $PIT_RACINE/minuteur ]] || return 1; read -r n < "$PIT_RACINE/minuteur" || return 1; [[ $n =~ ^[0-9]{1,8}$ ]] || return 1; ((10#$n <= PIT_DUREE)) || return 1; printf '%s' "$((10#$n))"; }
pit_fin() {
    # mkdir est un arbitrage atomique entre victoire et explosion.
    mkdir "$PIT_ETAT/termine" 2>/dev/null || return 0
    printf '%s\n' "$1" > "$PIT_ETAT/issue"
    if [[ $1 == explosion ]]; then
        local tty; IFS= read -r tty < "$PIT_ETAT/tty"
        if [[ $tty == /dev/pts/* || $tty == /dev/tty* ]]; then
            printf '\033[31m'  > "$tty" 2>/dev/null || :
            printf '\n  BBBB   OOO   OOO  M   M\n  B   B O   O O   O MM MM\n  BBBB  O   O O   O M M M\n  B   B O   O O   O M   M\n  BBBB   OOO   OOO  M   M\nEXPLOSION : %s\033[0m\n' "${2:-temps écoulé}" > "$tty" 2>/dev/null || :
        fi
    fi
    [[ $1 == explosion ]] || return 0
    local p; p=$(pit_pid shell) && kill -HUP "$p" 2>/dev/null || :
}
pit_copie_verificateur() { printf 'pit_verif %s\n' "$1" > "$2/verifier.sh"; }
pit_valider() { : > "$PIT_ETAT/valides/$1"; printf 'Niveau %s validé — Fragment %s : %s\n' "${PIT_ROMAINS[$1-1]}" "$1" "${PIT_CODE:$1-1:1}"; }
pit_effacer() { [[ -e $1 ]] || return 0; chmod -R u+rwx -- "$1" 2>/dev/null; rm -rf -- "$1"; }
pit_init_variables() { IFS= read -r PIT_CODE < "$PIT_ETAT/code"; IFS= read -r PIT_DUREE < "$PIT_ETAT/duree"; export PIT_DUREE; }
