# Corrigé — Cartographie du stockage NanoOrbit

> **Livrable L1-B — Corrigé instructeur.**
> Document à usage interne EPSI. Ne pas distribuer aux apprenants avant évaluation.

---

## Partie 1 — État initial du stockage

*Relevé à partir des vues `USER_SEGMENTS` et `DBA_DATA_FILES` avant toute réorganisation.*

### 1.1 Fichiers de données existants

| Tablespace | Fichier | Taille |
|---|---|---|
| `SYSTEM` | `/opt/oracle/oradata/FREE/FREEPDB1/system01.dbf` | 290 MB |
| `SYSAUX` | `/opt/oracle/oradata/FREE/FREEPDB1/sysaux01.dbf` | 440 MB |
| `UNDOTBS1` | `/opt/oracle/oradata/FREE/FREEPDB1/undotbs01.dbf` | 100 MB |
| `USERS` | `/opt/oracle/oradata/FREE/FREEPDB1/users01.dbf` | 72 MB |

> Les tablespaces `SYSTEM`, `SYSAUX` et `UNDOTBS1` sont des tablespaces Oracle internes. On ne les touche pas.

### 1.2 Répartition des tables NanoOrbit (état initial)

| Table | Tablespace actuel | Taille allouée | Famille de données |
|---|---|---|---|
| `ORBITE` | `USERS` | 0,06 MB | Référentiel |
| `INSTRUMENT` | `USERS` | 0,06 MB | Référentiel |
| `CENTRE_CONTROLE` | `USERS` | 0,06 MB | Référentiel |
| `STATION_SOL` | `USERS` | 0,06 MB | Référentiel |
| `MISSION` | `USERS` | 0,06 MB | Référentiel |
| `SATELLITE` | `USERS` | 0,06 MB | Opérationnel |
| `EMBARQUEMENT` | `USERS` | 0,06 MB | Opérationnel |
| `AFFECTATION_STATION` | `USERS` | 0,06 MB | Opérationnel |
| `PARTICIPATION` | `USERS` | 0,06 MB | Opérationnel |
| `FENETRE_COM` | `USERS` | 0,06 MB | Opérationnel |

**Total tables :** 10 segments · 0,60 MB
**Total index :** 10 segments · 0,63 MB
**Tablespace unique :** `USERS`

> `HISTORIQUE_STATUT` n'existe pas encore à ce stade — elle sera créée directement dans `TBS_HISTORIQUE` lors de la réorganisation (voir Partie 3).

### 1.3 Constat sur l'organisation initiale

- **Toutes les tables sont dans un tablespace unique `USERS`** — aucune ségrégation par famille de données.
- Il est impossible de sauvegarder ou restaurer une famille indépendamment des autres.
- Un incident sur `USERS` affecte simultanément les données référentiel, opérationnelles et historiques.
- **Aucun tablespace dédié** n'existe pour isoler les données les plus critiques (Opérationnel, RPO 15 min).
- La table `HISTORIQUE_STATUT` (traçabilité des changements de statut via trigger T5) n'est pas encore créée — si elle l'était dans `USERS` par défaut, sa croissance continue se mélangerait aux données stables.

---

## Partie 2 — Organisation cible

### 2.1 Les trois tablespaces cibles

| Tablespace cible | Famille | Tables concernées |
|---|---|---|
| `TBS_REFERENTIEL` | Référentiel | `ORBITE`, `INSTRUMENT`, `CENTRE_CONTROLE`, `STATION_SOL`, `MISSION` |
| `TBS_OPERATION` | Opérationnel | `SATELLITE`, `EMBARQUEMENT`, `AFFECTATION_STATION`, `PARTICIPATION`, `FENETRE_COM` |
| `TBS_HISTORIQUE` | Historique | `HISTORIQUE_STATUT` |

### 2.2 Justification par tablespace

#### `TBS_REFERENTIEL` — Données stables

Les 5 tables référentiel (`ORBITE`, `INSTRUMENT`, `CENTRE_CONTROLE`, `STATION_SOL`, `MISSION`) évoluent très rarement — une mise à jour de référentiel est une opération planifiée, rare, et nécessite une validation métier. Les isoler dans un tablespace dédié permet :
- Une **sauvegarde moins fréquente** (RPO 24 h suffisant selon le contrat) sans pénaliser les autres familles.
- Un **RTO de 1 heure** acceptable — restauration depuis sauvegarde complète.
- De **dimensionner le tablespace précisément** : la taille du référentiel est prévisible et quasi-stable.

#### `TBS_OPERATION` — Données vivantes

`FENETRE_COM` reçoit des insertions à chaque passage satellite (toutes les 90 min). `SATELLITE` et `PARTICIPATION` sont modifiées lors d'opérations métier critiques. Isoler ces 5 tables permet :
- D'appliquer une **stratégie de sauvegarde renforcée** sur ce seul tablespace (archive logs + sauvegarde incrémentale toutes les 4 h) pour respecter le RPO de **15 minutes**.
- De garantir un **RTO de 30 minutes** avec des procédures de restauration ciblées sur ce seul tablespace.
- D'isoler les **performances d'écriture** : les opérations intensives sur `FENETRE_COM` n'impactent pas les lectures du référentiel.

#### `TBS_HISTORIQUE` — Croissance continue

`HISTORIQUE_STATUT` sera créée **directement dans ce tablespace** lors de la réorganisation. Elle sera ensuite alimentée exclusivement par le trigger T5 à chaque changement de statut satellite. Elle ne fait que croître — jamais de suppressions. Lui dédier un tablespace dès sa création permet :
- De **monitorer sa croissance** indépendamment (alerte à +10 %/semaine selon le contrat).
- D'appliquer une **politique de rétention/archivage** spécifique sans affecter les autres tablespaces.
- D'éviter qu'une saturation de l'historique **bloque les écritures opérationnelles**.
- D'illustrer le principe : **créer un objet dans le bon tablespace dès sa naissance**, plutôt que de devoir le déplacer ensuite.

---

## Partie 3 — Mise en œuvre de la réorganisation

### 3.1 Séquence complète

La réorganisation se déroule en quatre étapes :

**Étape 1 — Créer les trois tablespaces**
```sql
CREATE TABLESPACE TBS_REFERENTIEL ...;
CREATE TABLESPACE TBS_OPERATION ...;
CREATE TABLESPACE TBS_HISTORIQUE ...;
```

**Étape 2 — Déplacer les 10 tables existantes**
```sql
ALTER TABLE ORBITE MOVE TABLESPACE TBS_REFERENTIEL;
-- ... (5 tables référentiel + 5 tables opérationnel)
```

**Étape 3 — Créer HISTORIQUE_STATUT dans TBS_HISTORIQUE**
```sql
CREATE TABLE HISTORIQUE_STATUT (
  id_historique   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_satellite    VARCHAR2(10)  NOT NULL,
  ancien_statut   VARCHAR2(20)  NOT NULL,
  nouveau_statut  VARCHAR2(20)  NOT NULL,
  date_changement TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
  motif           VARCHAR2(200),
  CONSTRAINT fk_hist_satellite FOREIGN KEY (id_satellite)
    REFERENCES SATELLITE(id_satellite)
) TABLESPACE TBS_HISTORIQUE;
```

> **Point pédagogique clé** : `HISTORIQUE_STATUT` n'est pas déplacée — elle est **née** dans le bon tablespace. C'est la bonne pratique : spécifier `TABLESPACE` dès le `CREATE TABLE` plutôt que d'avoir à corriger plus tard.

**Étape 4 — Reconstruire tous les index**
```sql
ALTER INDEX <index_name> REBUILD;
-- Obligatoire après tout ALTER TABLE ... MOVE
```

### 3.2 Vérification post-réorganisation
```sql
SELECT table_name, tablespace_name
FROM user_tables
ORDER BY tablespace_name, table_name;
-- Attendu : 11 tables réparties sur TBS_REFERENTIEL, TBS_OPERATION, TBS_HISTORIQUE
```

---

## Partie 4 — Candidats à l'indexation

*Les clés primaires sont déjà indexées automatiquement par Oracle. On se concentre sur les clés étrangères (jointures) et les colonnes de filtre (WHERE).*

### 4.1 Colonnes de jointure (clés étrangères non indexées)

| Table | Colonne | Référence | Justification |
|---|---|---|---|
| `SATELLITE` | `id_orbite` | `ORBITE.id_orbite` | Jointure fréquente pour connaître l'orbite d'un satellite |
| `EMBARQUEMENT` | `id_satellite` | `SATELLITE.id_satellite` | Jointure pour lister les instruments d'un satellite |
| `EMBARQUEMENT` | `ref_instrument` | `INSTRUMENT.ref_instrument` | Jointure pour lister les satellites portant un instrument |
| `AFFECTATION_STATION` | `id_centre` | `CENTRE_CONTROLE.id_centre` | Jointure centre ↔ station |
| `AFFECTATION_STATION` | `code_station` | `STATION_SOL.code_station` | Jointure station ↔ centre |
| `FENETRE_COM` | `id_satellite` | `SATELLITE.id_satellite` | **Jointure critique** — requête la plus fréquente du système |
| `FENETRE_COM` | `code_station` | `STATION_SOL.code_station` | Jointure pour les fenêtres d'une station donnée |
| `PARTICIPATION` | `id_satellite` | `SATELLITE.id_satellite` | Jointure pour les missions d'un satellite |
| `PARTICIPATION` | `id_mission` | `MISSION.id_mission` | Jointure pour les satellites d'une mission |
| `HISTORIQUE_STATUT` | `id_satellite` | `SATELLITE.id_satellite` | Jointure pour l'historique d'un satellite |

### 4.2 Colonnes de filtre (clauses WHERE fréquentes)

| Table | Colonne | Valeurs | Justification |
|---|---|---|---|
| `SATELLITE` | `statut` | `Opérationnel`, `En veille`, `Désorbité` | Filtre systématique — les triggers T1 et T5 testent cette colonne à chaque opération |
| `FENETRE_COM` | `statut` | `Planifiée`, `Réalisée`, `Annulée` | Filtre le plus fréquent — séparer les fenêtres planifiées des réalisées |
| `FENETRE_COM` | `datetime_debut` | — | Filtre temporel pour les fenêtres à venir ou sur une période |
| `MISSION` | `statut_mission` | `Active`, `Terminée` | Le trigger T4 teste ce statut à chaque INSERT sur PARTICIPATION |
| `STATION_SOL` | `statut` | `Active`, `Maintenance` | Le trigger T1 teste ce statut avant chaque fenêtre de communication |

### 4.3 Priorité d'indexation recommandée

Les index les plus prioritaires, à créer en séance 6 :

1. `IDX_FENETRE_SATELLITE` — `FENETRE_COM(id_satellite)` — jointure + volume élevé
2. `IDX_FENETRE_STATUT` — `FENETRE_COM(statut)` — filtre opérationnel permanent
3. `IDX_SATELLITE_STATUT` — `SATELLITE(statut)` — testé par T1 et T5 à chaque écriture
4. `IDX_PARTICIPATION_SAT` — `PARTICIPATION(id_satellite)` — jointure fréquente
5. `IDX_HISTORIQUE_SAT` — `HISTORIQUE_STATUT(id_satellite)` — croissance continue, requêtes d'audit


---

*Corrigé L1-B — Séance 3 — Module BDOE633 — Usage instructeur uniquement*
