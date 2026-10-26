# Solutions — PIT-Game

Document réservé au créateur. Les noms, tailles, valeurs et emplacements changent à chaque partie ; les commandes ci-dessous restent valables.

## Niveau I — `cd`, `ls`, `cat`

```bash
cd niveau_I
cat instruction
ls -lS alpha bravo charlie delta      # ou : ls -lSR
cd <dossier_du_plus_gros_fichier>
ls -a
cat .cle
cd ..
bash verifier.sh                     # saisir le fragment 1
```

Pièges : un dossier contient beaucoup de fichiers moyens (le plus lourd au total, mais pas le bon) et un petit fichier nommé `le_plus_gros.dat`. Chaque mauvais dossier possède aussi un `.cle` de leurre.

## Niveau II — `mkdir`, `cp`, `mv`, `rm`, `rmdir`, `vi`

```bash
cd ../niveau_II
mkdir archive tri
cp rapport.txt archive/
mv rapport.txt rapport_old.txt
mv rapport_old.txt tri/
rm poubelle/*.tmp
rmdir poubelle
vi config.txt                        # /INVALIDE, puis dd, puis :wq
bash verifier.sh
```

Pièges : `rmdir` échoue tant que `poubelle` n'est pas vide. `MODE_VALIDE`, `COMMENTAIRE=valide` et le commentaire « VALIDES » doivent rester.

## Niveau III — `|`, `grep`, `>`, `>>`

```bash
cd ../niveau_III
cat journal.log | grep ALERTE > reponse.txt
grep ROUGE journal.log               # lire NN dans CAPTEUR_NN
echo CAPTEUR=NN >> reponse.txt
bash verifier.sh
```

Pièges : `grep -i` récupère 8 lignes `alerte` en minuscules. Un second `>` écrase les lignes déjà enregistrées.

## Niveau IV — `find`, `mv`, `vi`

```bash
cd ../niveau_IV
find . -name '*.cfg' -size +2k -mtime -2
mv ./zone_X/sec_Y/rack_Z/noyau_XXXX.cfg labo/
vi labo/noyau_XXXX.cfg               # :%s/MODE=veille/MODE=actif/ puis /ERREUR=1, dd, :wq
bash verifier.sh
cat code_niveau4.txt
```

Pièges : vieux `.cfg` lourds, `.cfg` récents légers, `.txt` lourds et récents, `.cfg.bak`. Une copie (`cp`) laisse le fichier d'origine et échoue.

## Niveau V — processus et signaux

```bash
cd ../niveau_V
ps aux | grep brouilleur
kill PID_A
kill -STOP PID_B                     # suspendre est aussi accepté
kill PID_C
cat signal.txt
bash verifier.sh                     # état des brouilleurs
```

Pièges : tuer `emetteur` coûte 60 s et il est relancé. Le suspendre fige `signal.txt` : `kill -CONT PID_EMETTEUR`. Tuer ou suspendre `horloge` déclenche l'explosion. Un zombie compte comme mort.

## Niveau VI — droits et variables

```bash
cd ../niveau_VI
cat instruction
ls -l coffre.sh
chmod 540 coffre.sh                  # exemple : traduire la règle de l'instruction
echo $CODE_AGENT
export CLE=$CODE_AGENT
./coffre.sh
```

Correspondance : lire = 4, écrire = 2, exécuter = 1. Pièges : sans `export`, la variable reste invisible pour le script. Le propriétaire est normalement déjà le joueur (`chown` serait nécessaire seulement sinon).

## Niveau VII — `tar`, `find`, `vi`

```bash
cd ../niveau_VII
tar -xzvf mission.tar.gz -C extraction
find extraction -name ouverture.conf
vi extraction/mission/systeme/portes/<nord|sud>/ouverture.conf   # :s/ACTIF=non/ACTIF=oui/, :wq
tar -czvf retour.tar.gz -C extraction mission
bash verifier.sh
```

Pièges : `ouverture_old.conf`, `ouverture.conf.bak` et `ouverture_notes.txt` contiennent aussi des mots proches. L'archive peut contenir `mission/` ou `extraction/mission/`. Tout fichier ajouté ou modifié en plus fait échouer la vérification.

## Niveau VIII — boss final

```bash
cd ../niveau_VIII
ls -a
cd .QG
ls -lR
mv "$(find archives -name rapport_final.txt)" .
rmdir vide
mkdir sortie
cp rapport_final.txt sortie/
grep '^CLE_MAITRE=' rapport_final.txt > sortie/cle.txt
vi activation.sh                     # MODE=OFF devient MODE=ON
chmod 700 activation.sh
export CLE_MAITRE=$(cut -d= -f2 sortie/cle.txt)
./activation.sh
rm sortie/brouillon.tmp
tar -czvf ../livraison.tar.gz sortie
ps aux | grep perturbateur
kill PID_PERTURBATEUR                # ou kill -STOP
cd ..
bash verifier.sh
```

Pièges : `rapport_brouillon.txt` et `rapport_final.txt.bak` sont des leurres. `grep CLE_MAITRE` renvoie aussi `CLE_MAITRE_OLD`. Si le perturbateur est encore actif, le fragment affiché est brouillé.

## Fin de partie

```bash
cd "${TMPDIR:-/tmp}/pit_bombe_$(id -u)/racine"
echo CODE8CAR > code.txt
bash verifier
```

Le code s'obtient dans l'ordre des niveaux I à VIII. Une erreur retire 300 s.
