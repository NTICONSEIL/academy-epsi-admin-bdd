# Environnement technique — Oracle 23ai NanoOrbit

> Cet environnement fournit la base de données NanoOrbit utilisée comme fil rouge tout au long du module. Il doit être opérationnel **avant la séance 2**.

---

## 🎯 Principe

Tous les apprenants travaillent sur une instance Oracle 23ai contenant le schéma `NANOORBIT_ADMIN`. La base évolue au fil des séances : elle n'est **jamais remise à zéro**. La continuité de l'environnement est la condition du fil rouge.

La base s'initialise **automatiquement au premier démarrage** du conteneur, puis **persiste** : le travail réalisé en FOAD est conservé d'une séance à l'autre.

## 🛠️ Composants

| Composant | Valeur |
|---|---|
| SGBD | Oracle Database 23ai Free |
| Pluggable Database | `FREEPDB1` |
| Schéma de travail | `NANOORBIT_ADMIN` / `NanoOrbit_2026` |
| Compte SYSTEM | `system` / `NanoOrbit_Sys2026` |
| Jeu de caractères | `AL32UTF8` (obligatoire — données accentuées) |
| Conteneurisation | Docker Compose |

## 📁 Contenu du dossier

```
01-environnement/
├── README.md                  Ce fichier
├── docker-compose.yml         Définition de l'instance Oracle
├── init-nanoorbit.sh          Orchestrateur d'initialisation
├── verification.sql           Contrôle post-installation
├── setup/
│   └── 01-run-init.sh         Lanceur exécuté une seule fois par le conteneur
└── init/
    ├── 00-create-schema.sql   Création du schéma NANOORBIT_ADMIN
    ├── 01-ddl-tables.sql      Création des 11 tables
    ├── 02-dml-donnees.sql     Chargement du jeu de données (43 lignes)
    ├── 03-triggers.sql        Création des 5 triggers métier
    └── 04-package.sql         Création du package pkg_nanoOrbit
```

## 🔢 Ordre d'initialisation

L'orchestrateur enchaîne les scripts dans cet ordre précis :

| Étape | Script | Rôle |
|---|---|---|
| 0 | `00-create-schema.sql` | Crée l'utilisateur et accorde les privilèges |
| 1 | `01-ddl-tables.sql` | Crée les 11 tables et leurs contraintes |
| 2 | `02-dml-donnees.sql` | Charge les 43 lignes du jeu de données |
| 3 | `03-triggers.sql` | Crée les 5 triggers métier |
| 4 | `04-package.sql` | Crée le package `pkg_nanoOrbit` |
| — | `verification.sql` | Contrôle la conformité de l'installation |

> ⚠️ **Le DML est chargé avant les triggers.** La table `PARTICIPATION` contient des lignes rattachées à la mission `MSN-DEF-2022` (statut *Terminée*). Le trigger T4 bloquant tout ajout sur une mission terminée, le chargement initial doit avoir lieu **avant** sa création. Ces participations sont historiquement valides.

## 🚀 Démarrage

### Prérequis

- Docker et Docker Compose installés
- Accès au registre `container-registry.oracle.com` (acceptation de la licence Oracle Free requise la première fois)

### Lancer l'instance

```bash
cd 01-environnement
docker compose up -d
```

L'initialisation démarre automatiquement. Suivre son déroulement :

```bash
docker compose logs -f
```

L'instance est prête lorsque les logs affichent le bilan de vérification *« environnement NanoOrbit CONFORME »*. Le premier démarrage prend plusieurs minutes (création de la base).

### Se connecter

Avec SQL*Plus, SQLcl ou tout client Oracle :

```bash
sqlplus NANOORBIT_ADMIN/NanoOrbit_2026@//localhost:1521/FREEPDB1
```

Oracle Enterprise Manager Express est accessible sur `https://localhost:5500/em`.

## ✅ Vérifier l'installation

À tout moment, relancer le contrôle de conformité :

```bash
sqlplus NANOORBIT_ADMIN/NanoOrbit_2026@//localhost:1521/FREEPDB1 @verification.sql
```

Résultats attendus : **11 tables, 5 triggers, 2 objets package, 43 lignes, 0 objet invalide**.

## 🔄 Cycle de vie

| Commande | Effet |
|---|---|
| `docker compose up -d` | Démarre l'instance ; initialise la base au premier lancement |
| `docker compose stop` | Arrête l'instance ; **conserve** les données |
| `docker compose start` | Redémarre l'instance ; la base est dans l'état laissé |
| `docker compose down` | Supprime le conteneur ; **conserve** le volume de données |
| `docker compose down -v` | Supprime le conteneur **et les données** ; réinitialisation complète |

## 💾 Sauvegarde du travail apprenant entre les séances

Le fil rouge impose que le travail FOAD soit conservé d'une séance à l'autre. Deux approches selon le contexte EPSI :

- **Instance persistante par binôme** — chaque binôme dispose de son conteneur ; le volume `nanoorbit-data` assure la persistance. À privilégier si l'infrastructure le permet.
- **Export / import** — en fin de séance FOAD, l'apprenant exporte son schéma (`expdp`) ou conserve ses scripts ; il les réimporte au début de la séance suivante.

La procédure retenue doit être communiquée aux apprenants dès la séance 1.

## ⚠️ Points de vigilance

**Provisionner avant la séance 2.** L'environnement doit être testé par chaque binôme avant la première séance technique.

**Conserver une image de référence.** Garder le volume `nanoorbit-data` dans son état initial (ou un export `expdp`) permet de réinitialiser un environnement défaillant sans bloquer le fil rouge.

**Réinitialiser proprement.** Pour repartir d'une base neuve : `docker compose down -v` puis `docker compose up -d`. L'orchestrateur supprime de toute façon le schéma existant avant de le recréer (`DROP USER ... CASCADE`).

**Stockage volontairement brut.** Les tables sont créées dans le tablespace par défaut, sans optimisation. La réorganisation en tablespaces par famille de données est l'objet de la séance 3 — c'est voulu.

## ℹ️ Origine du schéma

Le schéma NanoOrbit (11 tables, 5 triggers, package `pkg_nanoOrbit`) provient d'un projet de modélisation et programmation du module ALTN83 (cycle ingénieur). Les scripts d'initialisation de ce dossier en sont une reconstruction fidèle, calibrée à partir du jeu de données de référence ALTN83. Pour le module BDOE633, la base est fournie clé en main : les apprenants l'administrent, ils ne la construisent pas.

---

*Environnement technique — Module BDOE633 — Branche `academy`*
