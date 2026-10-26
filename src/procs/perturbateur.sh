#!/usr/bin/env bash
source "$PIT_SOURCE/src/lib.sh"
trap 'exit' HUP TERM INT
while [[ -d $PIT_ETAT ]]; do pit_pause 1; done
