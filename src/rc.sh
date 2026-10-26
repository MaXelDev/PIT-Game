# shellcheck shell=bash disable=SC2030,SC2031 # PATH est volontairement local aux sous-shells.
source "$PIT_SOURCE/src/lib.sh"
# L'environnement hérité ne doit pas réinjecter une configuration utilisateur.
unalias -a
unset HISTFILE BASH_ENV ENV
export PATH="$PIT_ETAT/bin:$PIT_PATH_SYSTEME"
IFS= read -r CODE_AGENT < "$PIT_ETAT/agent"
export -n CODE_AGENT
cd -- "$PIT_RACINE" || exit
printf '%s %s\n' "$$" "$(pit_identite "$$")" > "$PIT_ETAT/pids/shell"
bomb() { PATH="$PIT_ETAT/bin:$PIT_PATH_SYSTEME" "$BASH" "$PIT_ETAT/bin/bomb"; }
restart() {
    ( export PATH="$PIT_ETAT/bin:$PIT_PATH_SYSTEME"; "$BASH" "$PIT_ETAT/bin/pit_restart" ) || return
    IFS= read -r CODE_AGENT < "$PIT_ETAT/agent"
    unset CLE CLE_MAITRE
    cd -- "$PIT_RACINE" || return
}
quit() { exit; }
reset() {
    if [[ $# != 1 || ! $1 =~ ^n[1-8]$ ]]; then printf 'Usage : reset n1 … reset n8\n'; return 0; fi
    ( export PATH="$PIT_ETAT/bin:$PIT_PATH_SYSTEME"; "$BASH" "$PIT_ETAT/bin/pit_reset_niveau" "${1#n}" ) || return
    [[ $1 != n6 ]] || { IFS= read -r CODE_AGENT < "$PIT_ETAT/agent"; unset CLE; }
    cd -- "$PIT_RACINE/niveau_${PIT_ROMAINS[${1#n}-1]}" || return
}
pit_prompt() {
    local n rel
    # Restauration locale des outils même si le joueur a remplacé PATH.
    local PATH="$PIT_ETAT/bin:$PIT_PATH_SYSTEME"
    [[ ! -d $PIT_ETAT/termine ]] || { exit; }
    if [[ ! -d $PIT_ETAT/maintenance ]]; then
        pit_actif horloge || { pit_fin explosion 'horloge neutralisée'; exit; }
        n=$(pit_minuteur) || { pit_fin explosion 'minuteur invalide'; exit; }
        (( n > 0 )) || { pit_fin explosion; exit; }
    else n=0
    fi
    case $PWD in "$PIT_RACINE"*) rel="racine${PWD#"$PIT_RACINE"}";; *) rel=$PWD;; esac
    # PS1 référence une variable : un nom de dossier n'est jamais réinterprété.
    printf -v PIT_PS1 '[💣 %s] %s $ ' "$(pit_temps "$n")" "$rel"
}
PS1='${PIT_PS1}'
PROMPT_COMMAND=pit_prompt
# Sortie propre sur explosion ou fermeture du terminal.
trap 'exit 129' HUP
