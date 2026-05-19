#!/usr/bin/env bash
# =============================================================================
# NANOORBIT — ORCHESTRATEUR D'INITIALISATION
# Module BDOE633 — Administration et Optimisation des Bases de Données
# =============================================================================
# Ce script est execute automatiquement par le conteneur Oracle au premier
# demarrage (il est monte dans /opt/oracle/scripts/startup). Il enchaine les
# scripts SQL d'initialisation dans le bon ordre.
#
# Il peut aussi etre lance manuellement pour reinitialiser la base :
#   ./init-nanoorbit.sh
#
# Variables d'environnement attendues :
#   ORACLE_PWD   mot de passe SYSTEM (defini dans docker-compose.yml)
# =============================================================================

set -euo pipefail

# Encodage UTF-8 obligatoire : les donnees NanoOrbit sont accentuees
export NLS_LANG=".AL32UTF8"

# Repertoire des scripts SQL (ce script et les .sql sont dans le meme dossier)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_DIR="${SCRIPT_DIR}/init"

# Parametres de connexion
PDB="FREEPDB1"
SYS_CONN="system/${ORACLE_PWD:-NanoOrbit_Sys2026}@//localhost:1521/${PDB}"
APP_CONN="NANOORBIT_ADMIN/NanoOrbit_2026@//localhost:1521/${PDB}"

echo "============================================================"
echo "  INITIALISATION DE LA BASE NANOORBIT"
echo "============================================================"

# --- Etape 0 : creation du schema (connecte en SYSTEM) -----------------------
echo "[1/6] Creation du schema NANOORBIT_ADMIN..."
sqlplus -S -L "${SYS_CONN}" @"${INIT_DIR}/00-create-schema.sql"

# --- Etape 1 : creation des tables (connecte en NANOORBIT_ADMIN) -------------
echo "[2/6] Creation des 11 tables..."
sqlplus -S -L "${APP_CONN}" @"${INIT_DIR}/01-ddl-tables.sql"

# --- Etape 2 : chargement des donnees ----------------------------------------
echo "[3/6] Chargement du jeu de donnees (43 lignes)..."
sqlplus -S -L "${APP_CONN}" @"${INIT_DIR}/02-dml-donnees.sql"

# --- Etape 3 : creation des triggers -----------------------------------------
echo "[4/6] Creation des 5 triggers metier..."
sqlplus -S -L "${APP_CONN}" @"${INIT_DIR}/03-triggers.sql"

# --- Etape 4 : creation du package -------------------------------------------
echo "[5/6] Creation du package pkg_nanoOrbit..."
sqlplus -S -L "${APP_CONN}" @"${INIT_DIR}/04-package.sql"

# --- Etape 5 : verification --------------------------------------------------
echo "[6/6] Verification de l'environnement..."
sqlplus -S -L "${APP_CONN}" @"${SCRIPT_DIR}/verification.sql"

echo "============================================================"
echo "  INITIALISATION NANOORBIT TERMINEE"
echo "  Connexion : NANOORBIT_ADMIN / NanoOrbit_2026 @ ${PDB}"
echo "============================================================"
