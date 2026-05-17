# Environnement technique — Oracle 23ai NanoOrbit

> Cet environnement fournit la base de données NanoOrbit utilisée comme fil rouge tout au long du module. Il doit être opérationnel **avant la séance 2**.

---

## 🎯 Principe

Tous les apprenants travaillent sur une instance Oracle 23ai contenant le schéma `NANOORBIT_ADMIN`. La base évolue au fil des séances : elle n'est **jamais remise à zéro**. La continuité de l'environnement est la condition du fil rouge.

## 🛠️ Composants

| Composant | Détail |
|---|---|
| SGBD | Oracle Database 23ai Free |
| Pluggable Database | `FREEPDB1` |
| Schéma de travail | `NANOORBIT_ADMIN` |
| Outils | SQL*Plus, SQLcl, Oracle Enterprise Manager, RMAN |
| Conteneurisation | Image Docker officielle Oracle Database Free |

## 📦 Scripts d'initialisation

Le dossier `init/` contient les scripts qui construisent la base NanoOrbit. Ils sont exécutés **une seule fois**, lors du provisionnement initial.

| Script | Rôle | Origine |
|---|---|---|
| `01-create-schema.sql` | Création du schéma `NANOORBIT_ADMIN` et des privilèges | À adapter |
| `02-ddl-tables.sql` | Création des 10 tables + `HISTORIQUE_STATUT` | Script L2-A du projet ALTN83 |
| `03-triggers.sql` | Création des 5 triggers métier | Script L2-C du projet ALTN83 |
| `04-package.sql` | Création du package `pkg_nanoOrbit` (SPEC + BODY) | Scripts L3-B/L3-C du projet ALTN83 |
| `05-dml-jeu-de-donnees.sql` | Insertion du jeu de données de test | Script L2-B du projet ALTN83 |

> ℹ️ **Origine des scripts** : le schéma NanoOrbit provient du module ALTN83 (cycle ingénieur). Les scripts DDL/DML/triggers/package y sont produits par les apprenants en phases 2 et 3. Pour ce module BDOE633, ils sont fournis tels quels — les apprenants n'ont pas à les écrire, seulement à administrer la base qui en résulte.

## 🚀 Provisionnement

### Démarrage de l'instance

```bash
docker run -d --name nanoorbit-oracle \
  -p 1521:1521 \
  -e ORACLE_PWD=<mot_de_passe_admin> \
  container-registry.oracle.com/database/free:latest
```

### Initialisation du schéma

Une fois l'instance démarrée et l'état « healthy » atteint, exécuter les scripts d'init dans l'ordre :

```bash
for script in init/0*.sql; do
  echo "Exécution de $script"
  sqlplus -S system/<mot_de_passe>@//localhost:1521/FREEPDB1 @"$script"
done
```

### Vérification

Le script `verification.sql` contrôle que la base est correctement initialisée :

```sql
-- À exécuter en tant que NANOORBIT_ADMIN
SELECT 'Tables', COUNT(*) FROM user_tables;          -- attendu : 11
SELECT 'Triggers', COUNT(*) FROM user_triggers;      -- attendu : 5
SELECT 'Package', COUNT(*) FROM user_objects
  WHERE object_type LIKE 'PACKAGE%';                 -- attendu : 2
SELECT 'Satellites', COUNT(*) FROM satellite;        -- attendu : 5
```

## 💾 Sauvegarde du travail apprenant entre les séances

Le fil rouge impose que le travail réalisé en FOAD soit conservé d'une séance à l'autre. Deux approches possibles selon le contexte EPSI :

- **Instance persistante par binôme** : chaque binôme dispose de son conteneur, le volume Docker est persistant. À privilégier si l'infrastructure le permet.
- **Export/import** : en fin de séance FOAD, l'apprenant exporte son schéma (`expdp`) ou ses scripts ; il les réimporte au début de la séance suivante. Plus lourd mais ne dépend pas d'une infrastructure persistante.

La procédure retenue doit être communiquée aux apprenants dès la séance 1.

## ⚠️ Points de vigilance

**Provisionner avant la séance 2.** L'environnement doit être testé par chaque binôme avant la première séance technique. 8 h de FOAD sans environnement stable génèrent du décrochage.

**Tester la connexion en fin de séance 1.** Profiter de la séance de cadrage pour faire valider l'accès de chaque binôme.

**Conserver une image de référence.** Garder une image Docker de la base NanoOrbit dans son état initial, pour pouvoir réinitialiser un environnement défaillant sans bloquer le fil rouge.

## 📁 Contenu attendu de ce dossier

```
01-environnement/
├── README.md                      Ce fichier
├── docker-compose.yml             Définition de l'instance Oracle (à produire)
├── init/                          Scripts d'initialisation (à alimenter depuis ALTN83)
│   ├── 01-create-schema.sql
│   ├── 02-ddl-tables.sql
│   ├── 03-triggers.sql
│   ├── 04-package.sql
│   └── 05-dml-jeu-de-donnees.sql
└── verification.sql               Contrôle post-installation
```

---

*Environnement technique — Module BDOE633 — Branche `academy`*
