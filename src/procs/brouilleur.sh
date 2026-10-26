#!/usr/bin/env bash
# Le nom et l'identifiant A/B/C restent visibles dans ps aux.
source "$PIT_SOURCE/src/lib.sh"
trap 'exit' HUP TERM INT
while [[ -d $PIT_ETAT ]]; do pit_pause 1; done
