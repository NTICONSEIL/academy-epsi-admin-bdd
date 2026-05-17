# Séance 3 — Organisation et optimisation du stockage

**Format** : FOAD (autoformation) · **Durée** : 2 h · **Partie syllabus** : Partie 2 — Administration / disponibilité

---

## 🧵 Étape du fil rouge

> **Étape 1 (2/2) — La base Oracle est livrée à l'équipe d'administration.**
> La base est outillée, le plan d'administration est posé. L'équipe organise maintenant le stockage : la base livrée tient dans un tablespace unique, sans optimisation. Il faut structurer.

| | |
|---|---|
| État de la base **en entrée** | Base outillée, plan d'administration posé, stockage par défaut |
| État de la base **en sortie** | Stockage organisé par famille de données, candidats à l'indexation identifiés |
| Livrables produits | L1-B (cartographie du stockage), L1-C (script de réorganisation) |

---

## 🎯 Objectifs pédagogiques

À l'issue de la séance, l'apprenant est capable de :

- **Cartographier** l'organisation physique du stockage d'une base Oracle
- **Créer et gérer** des tablespaces adaptés aux profils de données
- **Déplacer** des objets vers le tablespace approprié
- **Identifier** les colonnes candidates à l'indexation *(ASRBD1.8)*

> Cette séance couvre directement la compétence **ASRBD1.8 — Améliorer les performances en optimisant l'emplacement des stockages.**

## 🗺️ Déroulé FOAD

La séance est en autonomie. Elle est structurée en quatre temps, avec un résultat attendu en commentaire pour chaque étape.

### Temps 1 — Cartographie du stockage existant (30 min)

Explorer l'organisation physique actuelle de la base NanoOrbit :

```sql
-- Tablespaces et fichiers de données
SELECT tablespace_name, file_name, bytes/1024/1024 AS mb
FROM dba_data_files;

-- Répartition des segments par tablespace
SELECT tablespace_name, segment_type, COUNT(*) AS nb,
       ROUND(SUM(bytes)/1024/1024, 2) AS mb
FROM user_segments
GROUP BY tablespace_name, segment_type;
```

**Production attendue** : cartographie de l'état initial du stockage (livrable L1-B, partie 1).

### Temps 2 — Conception de la cible (30 min)

À partir de la classification du contrat de services (familles référentiel / opérationnel / historique), concevoir une organisation cible des tablespaces :

| Tablespace cible | Tables hébergées | Justification |
|---|---|---|
| `TBS_REFERENTIEL` | ORBITE, INSTRUMENT, CENTRE_CONTROLE, STATION_SOL, MISSION | Données stables, peu d'écritures |
| `TBS_OPERATION` | SATELLITE, EMBARQUEMENT, AFFECTATION_STATION, PARTICIPATION, FENETRE_COM | Données vivantes, fortes écritures |
| `TBS_HISTORIQUE` | HISTORIQUE_STATUT | Croissance continue, candidate au partitionnement |

**Production attendue** : cartographie cible justifiée (livrable L1-B, partie 2).

### Temps 3 — Mise en œuvre de la réorganisation (45 min)

Créer les tablespaces et déplacer les tables :

```sql
-- Création d'un tablespace
CREATE TABLESPACE tbs_referentiel
  DATAFILE 'tbs_referentiel01.dbf' SIZE 100M AUTOEXTEND ON;

-- Déplacement d'une table
ALTER TABLE orbite MOVE TABLESPACE tbs_referentiel;

-- Reconstruction des index après déplacement
ALTER INDEX <nom_index> REBUILD;
```

**Production attendue** : script complet de réorganisation, commenté (livrable L1-C).

### Temps 4 — Identification des candidats à l'indexation (15 min)

Repérer les colonnes fréquemment utilisées en filtre ou en jointure qui mériteraient un index : clés étrangères de `FENETRE_COM` et `PARTICIPATION`, colonne `statut` de `SATELLITE`, etc. La création effective des index sera abordée en séance 6 (lien performance/supervision).

**Production attendue** : liste argumentée des candidats à l'indexation (livrable L1-B, partie 3).

---

## 🎒 Supports à préparer

| Support | Format | Emplacement |
|---|---|---|
| Énoncé FOAD détaillé | Document | `ressources/foad-stockage.md` |
| Scripts SQL de référence | `.sql` commenté | `ressources/` |
| Corrigé (section instructeur) | Document | `instructor/` |

## ⚠️ Points de vigilance

**Le déplacement de table invalide les index** : insister sur le `ALTER INDEX … REBUILD` après chaque `MOVE`. C'est une erreur classique.

**Justifier chaque choix par le contrat de services** : la séance ne consiste pas à déplacer des tables au hasard mais à organiser le stockage selon les profils de données documentés.

**Prévoir un point de contrôle** : comme c'est une séance FOAD, prévoir un mécanisme de validation (forum, dépôt intermédiaire) pour détecter les apprenants en difficulté.

## 📎 Livrables du fil rouge

| Réf. | Livrable | Contenu |
|---|---|---|
| L1-B | Cartographie du stockage | État initial + cible + candidats à l'indexation |
| L1-C | Script de réorganisation | CREATE TABLESPACE + ALTER TABLE MOVE, commenté |

## 📚 Ressources

- [Fil rouge NanoOrbit](../../00-cadrage/fil-rouge.md)
- [Contrat de services — classification des données](../../00-cadrage/contrat-de-services.md)
- [Séance 4 — Stratégie de sauvegarde](../seance-4-strategie-backup/README.md)

---

*Séance 3 — Module BDOE633 — Branche `academy`*
