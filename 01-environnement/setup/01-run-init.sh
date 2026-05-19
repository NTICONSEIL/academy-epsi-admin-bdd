#!/usr/bin/env bash
# =============================================================================
# NANOORBIT — LANCEUR D'INITIALISATION (conteneur)
# =============================================================================
# Ce script est place dans /opt/oracle/scripts/setup : le conteneur Oracle Free
# l'execute UNE SEULE FOIS, juste apres la creation de la base de donnees.
# Aux redemarrages suivants, la base persiste dans le volume Docker et ce
# script n'est PAS rejoue — le travail des apprenants est ainsi conserve.
#
# Il delegue tout le travail a l'orchestrateur init-nanoorbit.sh, monte dans
# le conteneur sous /nanoorbit.
# =============================================================================

set -euo pipefail
echo "[setup] Lancement de l'initialisation NanoOrbit..."
bash /nanoorbit/init-nanoorbit.sh
echo "[setup] Initialisation NanoOrbit achevee."
