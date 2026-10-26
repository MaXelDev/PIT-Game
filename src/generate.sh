# shellcheck shell=bash
# Générateurs : chaque niveau peut être reconstruit seul avec le même fragment.
PIT_CHIFFRES=23456789
PIT_MINUSCULES=abcdefghjkmnpqrstuvwxyz
PIT_MAJUSCULES=ABCDEFGHJKLMNPQRSTUVWXYZ

pit_rappel() { printf '\nEn cas de blocage : reset n%s régénère gratuitement ce niveau.\n' "$1"; }
pit_remplir() { yes "$2" 2>/dev/null | head -c "$1"; }
pit_dossier() { printf '%s/niveau_%s' "$PIT_RACINE" "${PIT_ROMAINS[$1-1]}"; }

pit_nouveau_code() {
    PIT_CODE=$(pit_aleatoire "$PIT_CHIFFRES")$(pit_aleatoire "$PIT_MINUSCULES")$(pit_aleatoire "$PIT_CHIFFRES")$(pit_aleatoire "$PIT_MAJUSCULES")$(pit_aleatoire "$PIT_MINUSCULES")$(pit_aleatoire "$PIT_CHIFFRES")$(pit_aleatoire "$PIT_MAJUSCULES")$(pit_aleatoire "$PIT_CHIFFRES$PIT_MINUSCULES$PIT_MAJUSCULES")
    printf '%s\n' "$PIT_CODE" > "$PIT_ETAT/code"
}

pit_voyants() {
    local v etat
    for v in CAR FRK SND MSA; do
        etat=éteint; ((RANDOM % 2)) && etat=allumé
        printf 'Voyant %s : %s\n' "$v" "$etat"
    done > "$PIT_ETAT/voyants"
}

pit_generate() {
    local n
    pit_effacer "$PIT_RACINE"
    rm -rf -- "$PIT_ETAT/ref" "$PIT_ETAT/valides" "$PIT_ETAT/termine"
    rm -f -- "$PIT_ETAT/issue" "$PIT_ETAT/consommees"
    mkdir -p "$PIT_RACINE" "$PIT_ETAT/ref" "$PIT_ETAT/valides"
    : > "$PIT_ETAT/penalites"; : > "$PIT_ETAT/erreurs"; : > "$PIT_ETAT/tentatives"
    printf '%s\n' "$PIT_DUREE" > "$PIT_ETAT/duree"
    date +%s > "$PIT_ETAT/debut"
    pit_nouveau_code
    printf '%s%s-%s-%s\n' "$(pit_aleatoire "$PIT_MAJUSCULES")" "$(pit_aleatoire "$PIT_MAJUSCULES")" "$(pit_chaine 4 "$PIT_CHIFFRES")" "$(pit_aleatoire "$PIT_MAJUSCULES")" > "$PIT_ETAT/serie"
    pit_voyants
    printf '%s\n' "$PIT_DUREE" > "$PIT_RACINE/minuteur"
    printf '________\n' > "$PIT_RACINE/code.txt"
    # shellcheck disable=SC2016 # $BASH doit être évalué par le script généré.
    printf '#!/bin/bash\n# Contrôle du code final.\nexec "$BASH" "%s/bin/pit_verif" final\n' "$PIT_ETAT" > "$PIT_RACINE/verifier"
    chmod 755 "$PIT_RACINE/verifier"
    for n in 1 2 3 4 5 6 7 8; do
        # Un générateur absent est ignoré : utile pendant le développement par niveau.
        declare -F "gen_${PIT_ROMAINS[n-1]}" >/dev/null || continue
        mkdir -p "$(pit_dossier "$n")" "$PIT_ETAT/ref/$n"
        "gen_${PIT_ROMAINS[n-1]}" || return 1
    done
}

gen_I() {
    local d noms=(alpha bravo charlie delta) bon leurre i x max
    d=$(pit_dossier 1); bon=${noms[RANDOM%4]}
    for i in 0 1 2 3; do [[ ${noms[i]} == "$bon" ]] && leurre=${noms[(i + 1 + RANDOM % 3) % 4]}; done
    max=$((12000 + RANDOM % 6000))
    for x in "${noms[@]}"; do
        mkdir -p "$d/$x"
        for ((i=1;i<=3;i++)); do pit_remplir "$((500 + RANDOM % 4000))" "relevé $x $i" > "$d/$x/donnees_$i.dat"; done
        printf "Ce n'est pas le bon dossier : cherchez encore.\n" > "$d/$x/.cle"
    done
    for ((i=4;i<=8;i++)); do pit_remplir "$((7000 + RANDOM % 2500))" "relevé $leurre $i" > "$d/$leurre/donnees_$i.dat"; done
    pit_remplir 2000 "faux indice" > "$d/$leurre/le_plus_gros.dat"
    pit_remplir "$max" "relevé lourd" > "$d/$bon/archive.bin"
    printf 'Fragment 1 : %s\n' "${PIT_CODE:0:1}" > "$d/$bon/.cle"
    cat > "$d/instruction" <<'TXT'
MISSION I — Le fichier le plus lourd
1. Quatre dossiers sont présents : alpha, bravo, charlie et delta.
2. Entrez dans le dossier qui contient LE fichier individuel le plus lourd.
3. Attention : un dossier avec beaucoup de fichiers n'est pas forcément le bon.
4. Outils utiles : ls -l, ls -lh, ls -lS, ls -R, cd et cat.
5. Le bon dossier contient un fichier caché .cle (pensez à ls -a).
6. Revenez ici et lancez : bash verifier.sh, puis saisissez le fragment.
TXT
    pit_rappel 1 >> "$d/instruction"
    pit_copie_verificateur 1 "$d"
}

gen_II() {
    local d ref=$PIT_ETAT/ref/2 lignes=() i pos; d=$(pit_dossier 2)
    mkdir -p "$d/poubelle"
    printf 'Rapport de sécurité %s\nVérification des capteurs : %s\nSignature : %s\n' "$(pit_chaine 6)" "$(pit_chaine 10)" "$(pit_chaine 8)" > "$d/rapport.txt"
    lignes=("SERVEUR=labo-$(pit_chaine 3)" "PORT=$((2000 + RANDOM % 6000))" "MODE_VALIDE=oui" "# Toutes les lignes sont VALIDES sauf une" "COMMENTAIRE=valide" "TIMEOUT=$((10 + RANDOM % 50))")
    pos=$((RANDOM % (${#lignes[@]} + 1)))
    : > "$d/config.txt"; : > "$ref/config.attendu"
    for ((i=0;i<=${#lignes[@]};i++)); do
        if ((i == pos)); then printf 'CLE_INVALIDE=%s\n' "$(pit_chaine 5)" >> "$d/config.txt"; fi
        if ((i < ${#lignes[@]})); then printf '%s\n' "${lignes[i]}" | tee -a "$d/config.txt" >> "$ref/config.attendu"; fi
    done
    pit_remplir 200 tmp > "$d/poubelle/cache_1.tmp"; pit_remplir 300 tmp > "$d/poubelle/cache_2.tmp"
    cp "$d/rapport.txt" "$ref/rapport.txt"
    cat > "$d/instruction" <<'TXT'
MISSION II — Rangement du laboratoire
1. Créez les dossiers archive et tri.
2. Copiez rapport.txt dans archive.
3. Renommez l'original en rapport_old.txt puis déplacez-le dans tri.
4. Videz le dossier poubelle avec rm, puis supprimez-le avec rmdir.
5. Avec vi, supprimez uniquement la ligne contenant INVALIDE.
   Attention : VALIDE et VALIDES ne sont pas INVALIDE.
   Dans vi : placez le curseur sur la ligne, tapez dd, puis :wq.
6. Lancez bash verifier.sh.
TXT
    pit_rappel 2 >> "$d/instruction"
    pit_copie_verificateur 2 "$d"
}
