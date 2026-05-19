-- =============================================================================
-- NANOORBIT — SCRIPT DML (chargement du jeu de données)
-- Module BDOE633 — Administration et Optimisation des Bases de Données
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- =============================================================================
-- Ce script charge le jeu de données de reference (43 lignes) dans les
-- 10 tables peuplees. HISTORIQUE_STATUT n'est pas peuplee : elle est alimentee
-- exclusivement par le trigger T5.
--
-- ORDRE D'EXECUTION : ce script s'execute APRES 01-ddl-tables.sql et AVANT
-- 03-triggers.sql.
--
--   Pourquoi avant les triggers ? La table PARTICIPATION contient des lignes
--   rattachees a la mission MSN-DEF-2022, dont le statut est 'Terminée'. Ces
--   participations sont historiquement valides (les satellites y participaient
--   lorsque la mission etait active). Le trigger T4 bloquant tout ajout sur une
--   mission terminee, le chargement initial doit avoir lieu avant sa creation.
--
-- Ordre d'insertion respectant les dependances de cles etrangeres :
--   1. ORBITE   2. SATELLITE   3. INSTRUMENT   4. EMBARQUEMENT
--   5. CENTRE_CONTROLE   6. STATION_SOL   7. AFFECTATION_STATION
--   8. MISSION   9. FENETRE_COM   10. PARTICIPATION
-- =============================================================================

SET SERVEROUTPUT ON;
SET DEFINE OFF;

PROMPT ============================================================
PROMPT  NanoOrbit — Chargement du jeu de donnees de reference
PROMPT ============================================================


-- ---------------------------------------------------------------------------
-- TABLE 1 — ORBITE (3 lignes)
-- ---------------------------------------------------------------------------
PROMPT > Insertion ORBITE...

INSERT INTO ORBITE (type_orbite, altitude, inclinaison, periode_orbitale, excentricite, zone_couverture)
VALUES ('SSO', 550, 97.60, 95.50, 0.0010, 'Polaire globale — Europe / Arctique');

INSERT INTO ORBITE (type_orbite, altitude, inclinaison, periode_orbitale, excentricite, zone_couverture)
VALUES ('SSO', 700, 98.20, 98.80, 0.0008, 'Polaire globale — haute latitude');

INSERT INTO ORBITE (type_orbite, altitude, inclinaison, periode_orbitale, excentricite, zone_couverture)
VALUES ('LEO', 400, 51.60, 92.60, 0.0020, 'Équatoriale — zone tropicale');

PROMPT    -> 3 orbites (ORB id 1 SSO 550km, id 2 SSO 700km, id 3 LEO 400km)


-- ---------------------------------------------------------------------------
-- TABLE 2 — SATELLITE (5 lignes)
-- SAT-005 est Désorbité ; SAT-004 est En veille.
-- ---------------------------------------------------------------------------
PROMPT > Insertion SATELLITE...

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-001', 'NanoOrbit-Alpha',   TO_DATE('2022-03-15','YYYY-MM-DD'), 1.30, '3U',  'Opérationnel', 60, 20, 1);

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-002', 'NanoOrbit-Beta',    TO_DATE('2022-03-15','YYYY-MM-DD'), 1.30, '3U',  'Opérationnel', 60, 20, 1);

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-003', 'NanoOrbit-Gamma',   TO_DATE('2023-06-10','YYYY-MM-DD'), 2.00, '6U',  'Opérationnel', 84, 40, 2);

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-004', 'NanoOrbit-Delta',   TO_DATE('2023-06-10','YYYY-MM-DD'), 2.00, '6U',  'En veille',    84, 40, 2);

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-005', 'NanoOrbit-Epsilon', TO_DATE('2021-11-20','YYYY-MM-DD'), 4.50, '12U', 'Désorbité',    36, 80, 3);

PROMPT    -> 5 satellites (3 Operationnels, 1 En veille, 1 Desorbite)


-- ---------------------------------------------------------------------------
-- TABLE 3 — INSTRUMENT (4 lignes)
-- INS-AIS-01 a une resolution NULL (recepteur de signaux, pas un imageur).
-- ---------------------------------------------------------------------------
PROMPT > Insertion INSTRUMENT...

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution, consommation, masse)
VALUES ('INS-CAM-01',  'Caméra optique', 'PlanetScope-Mini', 3,    2.5, 0.400);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution, consommation, masse)
VALUES ('INS-IR-01',   'Infrarouge',     'FLIR-Lepton-3',    160,  1.2, 0.150);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution, consommation, masse)
VALUES ('INS-AIS-01',  'Récepteur AIS',  'ShipTrack-V2',     NULL, 0.8, 0.120);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution, consommation, masse)
VALUES ('INS-SPEC-01', 'Spectromètre',   'HyperSpec-Nano',   30,   3.1, 0.600);

PROMPT    -> 4 instruments (CAM, IR, AIS [resolution NULL], Spectrometre)


-- ---------------------------------------------------------------------------
-- TABLE 4 — EMBARQUEMENT (7 lignes)
-- ---------------------------------------------------------------------------
PROMPT > Insertion EMBARQUEMENT...

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-001', 'INS-CAM-01',  TO_DATE('2022-03-15','YYYY-MM-DD'), 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-001', 'INS-IR-01',   TO_DATE('2022-03-15','YYYY-MM-DD'), 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-002', 'INS-CAM-01',  TO_DATE('2022-03-15','YYYY-MM-DD'), 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-003', 'INS-CAM-01',  TO_DATE('2023-06-10','YYYY-MM-DD'), 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-003', 'INS-SPEC-01', TO_DATE('2023-06-10','YYYY-MM-DD'), 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-004', 'INS-IR-01',   TO_DATE('2023-06-10','YYYY-MM-DD'), 'Dégradé');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-005', 'INS-AIS-01',  TO_DATE('2021-11-20','YYYY-MM-DD'), 'Hors service');

PROMPT    -> 7 embarquements (5 Nominal, 1 Degrade, 1 Hors service)


-- ---------------------------------------------------------------------------
-- TABLE 5 — CENTRE_CONTROLE (3 lignes)
-- ---------------------------------------------------------------------------
PROMPT > Insertion CENTRE_CONTROLE...

INSERT INTO CENTRE_CONTROLE (nom_centre, ville, region_geo, fuseau_horaire, statut)
VALUES ('NanoOrbit Paris HQ',  'Paris',     'Europe',         'Europe/Paris',    'Actif');

INSERT INTO CENTRE_CONTROLE (nom_centre, ville, region_geo, fuseau_horaire, statut)
VALUES ('NanoOrbit Houston',   'Houston',   'Amériques',      'America/Chicago', 'Actif');

INSERT INTO CENTRE_CONTROLE (nom_centre, ville, region_geo, fuseau_horaire, statut)
VALUES ('NanoOrbit Singapore', 'Singapour', 'Asie-Pacifique', 'Asia/Singapore',  'Actif');

PROMPT    -> 3 centres (id 1 Paris, id 2 Houston, id 3 Singapour)


-- ---------------------------------------------------------------------------
-- TABLE 6 — STATION_SOL (3 lignes)
-- GS-SGP-01 est en Maintenance.
-- ---------------------------------------------------------------------------
PROMPT > Insertion STATION_SOL...

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne, bande_frequence, debit_max, statut)
VALUES ('GS-TLS-01', 'Toulouse Ground Station', 43.604700,   1.444200, 3.5, 'S', 150, 'Active');

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne, bande_frequence, debit_max, statut)
VALUES ('GS-KIR-01', 'Kiruna Arctic Station',   67.855700,  20.225300, 5.4, 'X', 400, 'Active');

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne, bande_frequence, debit_max, statut)
VALUES ('GS-SGP-01', 'Singapore Station',        1.352100, 103.819800, 3.0, 'S', 120, 'Maintenance');

PROMPT    -> 3 stations (GS-TLS-01 Active, GS-KIR-01 Active, GS-SGP-01 Maintenance)


-- ---------------------------------------------------------------------------
-- TABLE 7 — AFFECTATION_STATION (3 lignes)
-- ---------------------------------------------------------------------------
PROMPT > Insertion AFFECTATION_STATION...

INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation)
VALUES (1, 'GS-TLS-01', TO_DATE('2022-01-10','YYYY-MM-DD'));

INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation)
VALUES (1, 'GS-KIR-01', TO_DATE('2022-01-10','YYYY-MM-DD'));

INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation)
VALUES (3, 'GS-SGP-01', TO_DATE('2022-01-10','YYYY-MM-DD'));

PROMPT    -> 3 affectations (Paris: TLS+KIR, Singapour: SGP ; Houston sans station)


-- ---------------------------------------------------------------------------
-- TABLE 8 — MISSION (3 lignes)
-- MSN-DEF-2022 est Terminée.
-- ---------------------------------------------------------------------------
PROMPT > Insertion MISSION...

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_geo_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-ARC-2023', 'ArcticWatch 2023',
        'Surveillance de la fonte des glaces et dynamique des banquises arctiques',
        'Arctique / Groenland', TO_DATE('2023-01-01','YYYY-MM-DD'), NULL, 'Active');

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_geo_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-DEF-2022', 'DeforestAlert',
        'Détection et cartographie de la déforestation en temps quasi-réel',
        'Amazonie / Congo', TO_DATE('2022-06-01','YYYY-MM-DD'), TO_DATE('2023-05-31','YYYY-MM-DD'), 'Terminée');

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_geo_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-COAST-2024', 'CoastGuard 2024',
        'Surveillance de l''évolution du trait de côte et détection d''érosion côtière',
        'Méditerranée / Atlantique', TO_DATE('2024-03-01','YYYY-MM-DD'), NULL, 'Active');

PROMPT    -> 3 missions (MSN-ARC-2023 Active, MSN-DEF-2022 Terminee, MSN-COAST-2024 Active)


-- ---------------------------------------------------------------------------
-- TABLE 9 — FENETRE_COM (5 lignes)
-- Fenetres 1-3 Réalisées (volume renseigne), 4-5 Planifiées (volume NULL).
-- Plages horaires non-chevauchantes pour un meme satellite / une meme station.
-- ---------------------------------------------------------------------------
PROMPT > Insertion FENETRE_COM...

INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES (TO_TIMESTAMP('2024-01-15 09:14:00','YYYY-MM-DD HH24:MI:SS'), 420, 82.30, 1250, 'Réalisée', 'SAT-001', 'GS-KIR-01');

INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES (TO_TIMESTAMP('2024-01-15 11:52:00','YYYY-MM-DD HH24:MI:SS'), 310, 67.10, 890,  'Réalisée', 'SAT-002', 'GS-TLS-01');

INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES (TO_TIMESTAMP('2024-01-16 08:30:00','YYYY-MM-DD HH24:MI:SS'), 540, 88.90, 1680, 'Réalisée', 'SAT-003', 'GS-KIR-01');

INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES (TO_TIMESTAMP('2024-01-20 14:22:00','YYYY-MM-DD HH24:MI:SS'), 380, 71.40, NULL, 'Planifiée', 'SAT-001', 'GS-TLS-01');

INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES (TO_TIMESTAMP('2024-01-21 07:45:00','YYYY-MM-DD HH24:MI:SS'), 290, 59.80, NULL, 'Planifiée', 'SAT-003', 'GS-TLS-01');

PROMPT    -> 5 fenetres (3 Realisees avec volume, 2 Planifiees volume NULL)


-- ---------------------------------------------------------------------------
-- TABLE 10 — PARTICIPATION (7 lignes)
-- Les 2 participations a MSN-DEF-2022 (Terminée) sont historiquement valides :
-- elles sont chargees ici, avant la creation du trigger T4.
-- ---------------------------------------------------------------------------
PROMPT > Insertion PARTICIPATION...

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-001', 'MSN-ARC-2023', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-002', 'MSN-ARC-2023', 'Imageur secondaire');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-003', 'MSN-ARC-2023', 'Satellite de relais');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-001', 'MSN-DEF-2022', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-005', 'MSN-DEF-2022', 'Imageur secondaire');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-003', 'MSN-COAST-2024', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-004', 'MSN-COAST-2024', 'Satellite de secours');

PROMPT    -> 7 participations


-- ---------------------------------------------------------------------------
-- VALIDATION
-- ---------------------------------------------------------------------------
COMMIT;

PROMPT
PROMPT ============================================================
PROMPT  Chargement termine (43 lignes) — COMMIT effectue.
PROMPT  Etape suivante : 03-triggers.sql
PROMPT ============================================================
