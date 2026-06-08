-- =============================================================================
-- NANOORBIT — RÉORGANISATION DES TABLESPACES
-- Module BDOE633 — Séance 3 — Organisation et optimisation du stockage
-- Livrable L1-C
-- =============================================================================
-- Ce script réorganise le stockage de la base NanoOrbit en trois tablespaces
-- alignés sur les familles de données du contrat de services.
--
-- INSTRUCTIONS : complétez chaque zone [ À COMPLÉTER ] puis exécutez le script
-- connecté en tant que SYSTEM (droits DBA requis pour CREATE TABLESPACE).
--
-- ORDRE D'EXÉCUTION :
--   1. Créer les 3 tablespaces
--   2. Déplacer les tables (ALTER TABLE … MOVE)
--   3. Reconstruire les index (ALTER INDEX … REBUILD)
--   4. Vérifier le résultat
--
-- ⚠️  RAPPEL : tout ALTER TABLE … MOVE invalide les index de la table.
--     Un REBUILD est OBLIGATOIRE après chaque MOVE.
-- =============================================================================

-- Connexion requise : SYSTEM / NanoOrbit_Sys2026 sur FREE (CDB)
-- ou SYSTEM sur FREEPDB1 pour avoir les droits CREATE TABLESPACE


-- ===========================================================================
-- ÉTAPE 1 — CRÉATION DES TABLESPACES
-- ===========================================================================
-- Créez trois tablespaces permanents avec extension automatique activée.
-- Taille initiale : 10 MB — Extension : 10 MB — Taille max : 500 MB

-- Tablespace pour les données RÉFÉRENTIEL (stables, RPO 24h)
CREATE TABLESPACE [ À COMPLÉTER ]
  DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/[ À COMPLÉTER ].dbf'
  SIZE 10M
  AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

-- Tablespace pour les données OPÉRATIONNELLES (vivantes, RPO 15 min)
CREATE TABLESPACE [ À COMPLÉTER ]
  DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/[ À COMPLÉTER ].dbf'
  SIZE 10M
  AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

-- Tablespace pour les données HISTORIQUES (croissance continue, RPO 24h)
CREATE TABLESPACE [ À COMPLÉTER ]
  DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/[ À COMPLÉTER ].dbf'
  SIZE 10M
  AUTOEXTEND ON NEXT 10M MAXSIZE 500M;


-- ===========================================================================
-- ÉTAPE 2 — DÉPLACEMENT DES TABLES
-- ===========================================================================
-- Famille RÉFÉRENTIEL → TBS_REFERENTIEL
ALTER TABLE NANOORBIT_ADMIN.ORBITE            MOVE TABLESPACE [ À COMPLÉTER ];
ALTER TABLE NANOORBIT_ADMIN.INSTRUMENT        MOVE TABLESPACE [ À COMPLÉTER ];
ALTER TABLE NANOORBIT_ADMIN.CENTRE_CONTROLE   MOVE TABLESPACE [ À COMPLÉTER ];
ALTER TABLE NANOORBIT_ADMIN.STATION_SOL       MOVE TABLESPACE [ À COMPLÉTER ];
ALTER TABLE NANOORBIT_ADMIN.MISSION           MOVE TABLESPACE [ À COMPLÉTER ];

-- Famille OPÉRATIONNELLE → TBS_OPERATION
ALTER TABLE NANOORBIT_ADMIN.SATELLITE           MOVE TABLESPACE [ À COMPLÉTER ];
ALTER TABLE NANOORBIT_ADMIN.EMBARQUEMENT        MOVE TABLESPACE [ À COMPLÉTER ];
ALTER TABLE NANOORBIT_ADMIN.AFFECTATION_STATION MOVE TABLESPACE [ À COMPLÉTER ];
ALTER TABLE NANOORBIT_ADMIN.PARTICIPATION       MOVE TABLESPACE [ À COMPLÉTER ];
ALTER TABLE NANOORBIT_ADMIN.FENETRE_COM         MOVE TABLESPACE [ À COMPLÉTER ];

-- Famille HISTORIQUE → TBS_HISTORIQUE
ALTER TABLE NANOORBIT_ADMIN.HISTORIQUE_STATUT MOVE TABLESPACE [ À COMPLÉTER ];


-- ===========================================================================
-- ÉTAPE 3 — RECONSTRUCTION DES INDEX
-- ===========================================================================
-- ⚠️  Après chaque MOVE, les ROWID changent → les index passent UNUSABLE.
--     Reconstruire TOUS les index dans leur nouveau tablespace.

-- Index de ORBITE
ALTER INDEX NANOORBIT_ADMIN.PK_ORBITE         REBUILD TABLESPACE [ À COMPLÉTER ];
ALTER INDEX NANOORBIT_ADMIN.UQ_ORBITE_ALT_INC REBUILD TABLESPACE [ À COMPLÉTER ];

-- Index de INSTRUMENT
ALTER INDEX NANOORBIT_ADMIN.PK_INSTRUMENT     REBUILD TABLESPACE [ À COMPLÉTER ];

-- Index de CENTRE_CONTROLE
ALTER INDEX NANOORBIT_ADMIN.PK_CENTRE         REBUILD TABLESPACE [ À COMPLÉTER ];

-- Index de STATION_SOL
ALTER INDEX NANOORBIT_ADMIN.PK_STATION        REBUILD TABLESPACE [ À COMPLÉTER ];

-- Index de MISSION
ALTER INDEX NANOORBIT_ADMIN.PK_MISSION        REBUILD TABLESPACE [ À COMPLÉTER ];

-- Index de SATELLITE
ALTER INDEX NANOORBIT_ADMIN.PK_SATELLITE      REBUILD TABLESPACE [ À COMPLÉTER ];

-- Index de EMBARQUEMENT
ALTER INDEX NANOORBIT_ADMIN.PK_EMBARQUEMENT   REBUILD TABLESPACE [ À COMPLÉTER ];

-- Index de AFFECTATION_STATION
ALTER INDEX NANOORBIT_ADMIN.PK_AFFECTATION    REBUILD TABLESPACE [ À COMPLÉTER ];

-- Index de PARTICIPATION
ALTER INDEX NANOORBIT_ADMIN.PK_PARTICIPATION  REBUILD TABLESPACE [ À COMPLÉTER ];

-- Index de FENETRE_COM
ALTER INDEX NANOORBIT_ADMIN.PK_FENETRE        REBUILD TABLESPACE [ À COMPLÉTER ];

-- Index de HISTORIQUE_STATUT
ALTER INDEX NANOORBIT_ADMIN.PK_HISTORIQUE     REBUILD TABLESPACE [ À COMPLÉTER ];


-- ===========================================================================
-- ÉTAPE 4 — VÉRIFICATION
-- ===========================================================================
-- Contrôle 1 : répartition des tables par tablespace (résultat attendu : 5/5/1)
SELECT t.tablespace_name, COUNT(*) AS nb_tables
FROM dba_tables t
WHERE t.owner = 'NANOORBIT_ADMIN'
AND t.tablespace_name IN ('TBS_REFERENTIEL','TBS_OPERATION','TBS_HISTORIQUE')
GROUP BY t.tablespace_name
ORDER BY t.tablespace_name;

-- Contrôle 2 : aucun index ne doit être UNUSABLE
SELECT index_name, status
FROM dba_indexes
WHERE owner = 'NANOORBIT_ADMIN'
AND status = 'UNUSABLE';
-- Résultat attendu : aucune ligne

-- =============================================================================
-- FIN DU SCRIPT — Le script complété et exécuté constitue le livrable L1-C.
-- =============================================================================
