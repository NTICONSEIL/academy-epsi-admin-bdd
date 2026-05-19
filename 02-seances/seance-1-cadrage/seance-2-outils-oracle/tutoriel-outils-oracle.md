# Tutoriel — Les outils Oracle d'administration

> **Séance 2, bloc 3.** Ce tutoriel vous apprend à lancer et à utiliser les outils d'administration d'Oracle sur l'environnement NanoOrbit. Suivez-le les mains sur le clavier.

---

## La boîte à outils de l'administrateur

L'administrateur Oracle ne travaille pas avec un seul outil mais avec une petite panoplie. Ce tutoriel couvre les quatre que vous utiliserez tout au long du module :

| Outil | Nature | À quoi il sert |
|---|---|---|
| **SQL\*Plus** | Ligne de commande | L'outil de travail principal : exécuter scripts et requêtes |
| **lsnrctl** | Ligne de commande | Piloter le listener — la porte d'entrée réseau de la base |
| **EM Express** | Console web | Visualiser l'état de la base dans un navigateur |
| **Dictionnaire de données** | Vues système | La source d'information de l'administrateur sur la base |

> ℹ️ **Édition Free.** Votre conteneur fait tourner Oracle Database 23ai **Free**. Vous disposez de SQL\*Plus, du listener et d'**EM Express** (la console web légère). La grande console *Oracle Enterprise Manager Cloud Control* est un produit séparé, non inclus — ce n'est pas un manque pour ce module.

## Avant de commencer

L'environnement doit être démarré. Vérifiez :

```bash
docker compose ps
```

Le conteneur `nanoorbit-oracle` doit être `healthy`. Sinon, voir le [guide de démarrage](../../../01-environnement/DEMARRAGE.md).

> 🪟 **Windows / Git Bash.** Tapez une fois cette commande au début de votre session pour éviter la réécriture des chemins :
> ```bash
> export MSYS_NO_PATHCONV=1
> ```
> Toutes les commandes du tutoriel fonctionneront alors telles quelles.

---

# Outil 1 — SQL\*Plus

SQL\*Plus est le client en ligne de commande historique d'Oracle. C'est l'outil que vous utiliserez le plus : exécuter des requêtes, lancer des scripts, administrer la base.

## 1.1 Lancer SQL\*Plus

SQL\*Plus est installé **dans le conteneur**. On le lance via `docker exec` :

```bash
docker exec -it nanoorbit-oracle sqlplus NANOORBIT_ADMIN/NanoOrbit_2026@//localhost:1521/FREEPDB1
```

Vous obtenez l'invite :

```
SQL>
```

Décomposons la chaîne de connexion `NANOORBIT_ADMIN/NanoOrbit_2026@//localhost:1521/FREEPDB1` :

| Élément | Signification |
|---|---|
| `NANOORBIT_ADMIN` | L'utilisateur (le schéma) |
| `NanoOrbit_2026` | Son mot de passe |
| `localhost:1521` | L'hôte et le port d'écoute du listener |
| `FREEPDB1` | Le nom du service — la *pluggable database* |

## 1.2 Les deux modes de connexion

**Connexion applicative** (la précédente) — pour le travail courant sur le schéma NanoOrbit.

**Connexion administrateur** (`SYSDBA`) — pour les opérations de haut niveau (arrêt/démarrage de la base, mode archivelog…). Elle se fait avec le compte `SYSTEM` ou `SYS` :

```bash
docker exec -it nanoorbit-oracle sqlplus sys/NanoOrbit_Sys2026@//localhost:1521/FREEPDB1 as sysdba
```

> ⚠️ Réservez `SYSDBA` aux opérations qui l'exigent. Le travail quotidien se fait avec `NANOORBIT_ADMIN`.

## 1.3 Premières commandes : se situer

Une fois connecté, sachez toujours qui vous êtes et où vous êtes :

```sql
SHOW USER
```
Affiche l'utilisateur courant — `USER is "NANOORBIT_ADMIN"`.

```sql
SHOW CON_NAME
```
Affiche la *pluggable database* courante — `CON_NAME : FREEPDB1`.

> 💡 Les commandes SQL\*Plus (`SHOW`, `SET`, `DESCRIBE`…) ne prennent **pas** de point-virgule. Les ordres SQL (`SELECT`, `UPDATE`…) en prennent un.

## 1.4 Explorer la structure d'une table

`DESCRIBE` (abrégé `DESC`) affiche les colonnes d'une table, leur type et leur obligation :

```sql
DESCRIBE satellite
```

Résultat :

```
Name              Null?    Type
----------------- -------- ----------------
ID_SATELLITE      NOT NULL VARCHAR2(10)
NOM_SATELLITE     NOT NULL VARCHAR2(40)
...
```

C'est le premier réflexe avant d'interroger une table inconnue.

## 1.5 Régler l'affichage

Par défaut, SQL\*Plus affiche mal les résultats larges. Trois réglages essentiels :

```sql
SET LINESIZE 150
SET PAGESIZE 50
SET SQLBLANKLINES ON
```

- `LINESIZE` — largeur d'une ligne en caractères ; augmentez-la pour les tables larges.
- `PAGESIZE` — nombre de lignes avant réaffichage des en-têtes ; `0` supprime les en-têtes.
- `SQLBLANKLINES ON` — autorise les lignes vides dans une instruction SQL.

Pour ajuster la largeur d'une colonne précise :

```sql
COLUMN nom_station FORMAT A30
COLUMN debit_max   FORMAT 999999
```

`A30` = 30 caractères pour une colonne texte ; `999999` = format numérique.

## 1.6 Exécuter un script SQL

L'arobase `@` exécute un fichier de commandes. C'est ainsi que vous lancerez les scripts du module :

```sql
@/nanoorbit/verification.sql
```

Le chemin est celui **vu depuis le conteneur**. Le dossier `01-environnement/` du dépôt y est monté sous `/nanoorbit`.

## 1.7 Capturer une sortie dans un fichier

`SPOOL` enregistre tout ce qui s'affiche dans un fichier — utile pour conserver une trace ou alimenter un livrable :

```sql
SPOOL /nanoorbit/ma-cartographie.txt
SELECT table_name, tablespace_name FROM user_tables;
SPOOL OFF
```

Le fichier `ma-cartographie.txt` apparaît dans votre dossier `01-environnement/` sur le poste, car ce dossier est monté dans le conteneur.

## 1.8 Autres commandes utiles

| Commande | Effet |
|---|---|
| `/` | Réexécute la dernière instruction SQL |
| `SET SERVEROUTPUT ON` | Affiche les sorties de `DBMS_OUTPUT` (blocs PL/SQL) |
| `SET TIMING ON` | Affiche la durée d'exécution de chaque ordre |
| `SHOW PARAMETER memory` | Affiche les paramètres d'instance contenant « memory » |
| `CLEAR SCREEN` | Efface l'écran |
| `COLUMN col CLEAR` | Annule un formatage de colonne |

## 1.9 Quitter SQL\*Plus

```sql
EXIT
```

(ou `QUIT`). Vous revenez à l'invite du terminal.

---

# Outil 2 — Oracle Net et le listener

## 2.1 À quoi sert le listener

Le **listener** est le processus réseau qui reçoit les demandes de connexion des clients et les aiguille vers la bonne base. Sans listener en écoute, aucune connexion distante n'est possible. C'est la « porte d'entrée » de l'instance Oracle.

L'outil pour le piloter est `lsnrctl`.

## 2.2 Vérifier l'état du listener

```bash
docker exec -it nanoorbit-oracle lsnrctl status
```

Lisez dans la sortie :

- **STATUS of the LISTENER** — l'état général, la date de démarrage, le fichier de log.
- **Listening Endpoints Summary** — les points d'écoute ; vous devez voir le port `1521`.
- **Services Summary** — les services disponibles ; vous devez voir `FREEPDB1` (votre base) et `FREE` (le conteneur racine).

Si `FREEPDB1` apparaît avec `status READY`, la base est joignable.

## 2.3 Lister les services en détail

```bash
docker exec -it nanoorbit-oracle lsnrctl services
```

Affiche, pour chaque service, les processus (« handlers ») prêts à traiter les connexions. Utile pour diagnostiquer un problème de connexion.

## 2.4 Le lien avec la chaîne de connexion

Quand vous écrivez `@//localhost:1521/FREEPDB1` dans SQL\*Plus, vous demandez au listener du port `1521` de vous connecter au service `FREEPDB1`. Si `lsnrctl status` ne montre pas ce service, la connexion échouera — c'est le premier endroit où regarder en cas de problème réseau.

---

# Outil 3 — EM Express, la console web

EM Express (*Enterprise Manager Database Express*) est une console **web légère**, intégrée à la base. Elle offre une vue graphique de l'état de l'instance, sans rien installer.

## 3.1 Lancer EM Express

EM Express est déjà actif — le `docker-compose.yml` expose son port `5500`. Ouvrez simplement un navigateur sur le poste :

```
https://localhost:5500/em
```

> ⚠️ L'adresse est en **HTTPS** avec un certificat auto-signé. Le navigateur affichera un avertissement de sécurité : acceptez l'exception pour continuer. C'est normal en environnement de formation.

## 3.2 Se connecter

Sur la page de connexion :

| Champ | Valeur |
|---|---|
| Username | `system` |
| Password | `NanoOrbit_Sys2026` |
| Container Name | `FREEPDB1` |

## 3.3 Ce que vous pouvez y observer

EM Express donne une vue synthétique et graphique :

- **Storage** — l'occupation des tablespaces, vue d'ensemble du stockage.
- **Performance** — l'activité de la base, les sessions actives.
- **Sessions** — qui est connecté, ce que chaque session exécute.
- **Configuration** — les paramètres d'initialisation de l'instance.

C'est un bon complément visuel à SQL\*Plus : SQL\*Plus pour agir, EM Express pour observer d'un coup d'œil.

> ℹ️ **Limite à connaître.** EM Express est une console **mono-base**, sans historique de performance approfondi. Les analyses avancées (rapports AWR) relèvent d'une option payante absente de l'édition Free. La supervision détaillée du module s'appuiera sur les vues du dictionnaire — voir la séance 6.

## 3.4 Si EM Express ne répond pas

Vérifiez que le port HTTPS est bien configuré. Connecté en SQL\*Plus sur `FREEPDB1` :

```sql
SELECT DBMS_XDB_CONFIG.GETHTTPSPORT FROM DUAL;
```

- Le résultat est `5500` → le port est actif, le problème vient du navigateur.
- Le résultat est `0` → activez le port :

```sql
EXEC DBMS_XDB_CONFIG.SETHTTPSPORT(5500);
```

---

# Outil 4 — Le dictionnaire de données

Ce n'est pas un logiciel, mais c'est **l'outil le plus important** de l'administrateur. Oracle décrit sa propre structure dans un ensemble de vues système : c'est le *dictionnaire de données*. Pour connaître une base, on l'interroge.

## 4.1 Le principe

Trois familles de vues, reconnaissables à leur préfixe :

| Préfixe | Portée | Exemple |
|---|---|---|
| `USER_` | Les objets de **votre** schéma | `USER_TABLES` |
| `ALL_` | Tout ce à quoi vous avez accès | `ALL_TABLES` |
| `DBA_` | **Toute** la base (vue administrateur) | `DBA_DATA_FILES` |

S'y ajoutent les vues dynamiques **`V$`**, qui reflètent l'activité en temps réel de l'instance.

## 4.2 Les vues clés du module

| Vue | Ce qu'elle révèle |
|---|---|
| `USER_TABLES` | Les tables du schéma et leur volumétrie |
| `USER_SEGMENTS` | L'occupation disque réelle des objets |
| `USER_CONSTRAINTS` | Les contraintes : PK, FK, CHECK |
| `USER_INDEXES` | Les index et leur statut |
| `USER_TRIGGERS` | Les triggers métier |
| `DBA_DATA_FILES` | Les fichiers de données et tablespaces |
| `V$SESSION` | Les sessions actives sur l'instance |
| `V$DATABASE` | L'état de la base (mode d'archivage, mode d'ouverture) |

Exemple — lister les tables et leur nombre de lignes estimé :

```sql
SELECT table_name, num_rows, tablespace_name
FROM   user_tables
ORDER  BY table_name;
```

## 4.3 Le script d'exploration fourni

Vous n'avez pas à retenir toutes ces requêtes : le script `exploration-dictionnaire.sql` les rassemble, organisées par question d'administrateur. Lancez-le :

```sql
@/depot/02-seances/seance-2-outils-oracle/ressources/exploration-dictionnaire.sql
```

> ℹ️ Adaptez le chemin à l'emplacement du script vu depuis le conteneur. S'il n'est pas accessible, copiez-le d'abord avec `docker cp`, ou placez-le dans le dossier `01-environnement/` monté sous `/nanoorbit`.

---

# Pour aller plus loin — SQLcl et SQL Developer

Deux outils plus modernes existent, mais ne sont **pas inclus** dans l'édition Free : ils se téléchargent séparément.

- **SQLcl** — un client en ligne de commande modernisé : même usage que SQL\*Plus, avec l'auto-complétion, l'historique et un meilleur formatage. Recommandé si vous voulez plus de confort.
- **SQL Developer** — un environnement graphique de bureau pour requêter et explorer la base à la souris.

Pour ce module, **SQL\*Plus suffit** : il est partout, toujours disponible, et c'est l'outil de référence de l'administrateur.

---

# Aide-mémoire

### Lancer les outils (depuis le terminal)

```bash
# SQL*Plus — connexion applicative
docker exec -it nanoorbit-oracle sqlplus NANOORBIT_ADMIN/NanoOrbit_2026@//localhost:1521/FREEPDB1

# SQL*Plus — connexion administrateur
docker exec -it nanoorbit-oracle sqlplus sys/NanoOrbit_Sys2026@//localhost:1521/FREEPDB1 as sysdba

# Listener
docker exec -it nanoorbit-oracle lsnrctl status

# EM Express : navigateur → https://localhost:5500/em
```

### Commandes SQL\*Plus essentielles

```sql
SHOW USER                  -- utilisateur courant
SHOW CON_NAME              -- pluggable database courante
DESCRIBE satellite         -- structure d'une table
SET LINESIZE 150           -- largeur d'affichage
SET PAGESIZE 50            -- lignes par page
SET SERVEROUTPUT ON        -- afficher les sorties PL/SQL
COLUMN nom FORMAT A30      -- largeur d'une colonne
@/chemin/script.sql        -- exécuter un script
SPOOL fichier.txt          -- démarrer la capture
SPOOL OFF                  -- arrêter la capture
/                          -- réexécuter la dernière requête
EXIT                       -- quitter
```

---

# Mini-exercice de validation

Pour vérifier que vous maîtrisez les outils, réalisez cette courte séquence :

1. Lancez SQL\*Plus en connexion applicative.
2. Affichez l'utilisateur et la *pluggable database* courants.
3. Décrivez la structure de la table `FENETRE_COM`.
4. Réglez l'affichage (`LINESIZE 150`, `PAGESIZE 50`).
5. Affichez le contenu de la table `STATION_SOL`.
6. Capturez dans un fichier `verif-stations.txt` la liste des stations et leur statut.
7. Quittez SQL\*Plus.
8. Vérifiez l'état du listener et repérez le service `FREEPDB1`.
9. Ouvrez EM Express et retrouvez l'occupation des tablespaces.

Si vous réalisez ces neuf étapes sans aide, vous êtes prêt pour la suite du module.

---

*Tutoriel des outils Oracle — Séance 2 — Module BDOE633 — Branche `academy`*
