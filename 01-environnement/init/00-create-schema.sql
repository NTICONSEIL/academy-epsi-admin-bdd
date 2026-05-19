-- =============================================================================
-- NANOORBIT — CREATION DU SCHEMA ET DE L'UTILISATEUR
-- Module BDOE633 — Administration et Optimisation des Bases de Données
-- SGBD : Oracle 23ai — Pluggable Database : FREEPDB1
-- =============================================================================
-- Ce script cree l'utilisateur (schema) NANOORBIT_ADMIN et lui accorde les
-- privileges necessaires aux travaux du module.
--
-- A executer EN PREMIER, connecte en tant que SYSTEM sur FREEPDB1.
--
-- NOTE : le mot de passe ci-dessous est un mot de passe pedagogique par defaut.
-- En contexte reel, il doit etre modifie. Pour le module BDOE633, ce compte
-- est volontairement dote de privileges larges afin de permettre les travaux
-- d'administration (tablespaces, sauvegarde, supervision).
-- =============================================================================

SET DEFINE OFF;
SET SERVEROUTPUT ON;

PROMPT ============================================================
PROMPT  NanoOrbit — Creation du schema NANOORBIT_ADMIN
PROMPT ============================================================

-- Suppression prealable si le schema existe deja (reinitialisation propre)
BEGIN
    EXECUTE IMMEDIATE 'DROP USER NANOORBIT_ADMIN CASCADE';
    DBMS_OUTPUT.PUT_LINE('Schema NANOORBIT_ADMIN existant supprime.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1918 THEN
            DBMS_OUTPUT.PUT_LINE('Schema NANOORBIT_ADMIN inexistant : creation directe.');
        ELSE
            RAISE;
        END IF;
END;
/

-- Creation de l'utilisateur / schema
CREATE USER NANOORBIT_ADMIN IDENTIFIED BY "NanoOrbit_2026"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON USERS;

-- Privileges de connexion et de developpement courant
GRANT CREATE SESSION        TO NANOORBIT_ADMIN;
GRANT CREATE TABLE          TO NANOORBIT_ADMIN;
GRANT CREATE VIEW           TO NANOORBIT_ADMIN;
GRANT CREATE PROCEDURE      TO NANOORBIT_ADMIN;
GRANT CREATE TRIGGER        TO NANOORBIT_ADMIN;
GRANT CREATE SEQUENCE       TO NANOORBIT_ADMIN;
GRANT CREATE TYPE           TO NANOORBIT_ADMIN;
GRANT CREATE SYNONYM        TO NANOORBIT_ADMIN;
GRANT CREATE JOB            TO NANOORBIT_ADMIN;

-- Privileges d'administration necessaires aux travaux du module
-- (gestion du stockage, supervision via les vues du dictionnaire)
GRANT CREATE TABLESPACE     TO NANOORBIT_ADMIN;
GRANT ALTER TABLESPACE      TO NANOORBIT_ADMIN;
GRANT DROP TABLESPACE       TO NANOORBIT_ADMIN;
GRANT UNLIMITED TABLESPACE  TO NANOORBIT_ADMIN;
GRANT SELECT ANY DICTIONARY TO NANOORBIT_ADMIN;
GRANT SELECT_CATALOG_ROLE   TO NANOORBIT_ADMIN;

PROMPT
PROMPT ============================================================
PROMPT  Schema NANOORBIT_ADMIN cree.
PROMPT  Connexion : NANOORBIT_ADMIN / NanoOrbit_2026 @ FREEPDB1
PROMPT  Etape suivante : 01-ddl-tables.sql
PROMPT ============================================================
