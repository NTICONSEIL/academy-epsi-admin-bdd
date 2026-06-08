# L2-A — Stratégie de sauvegarde et restauration NanoOrbit

> **Livrable L2-A · Séance 4 · Module BDOE633**
> Document à intégrer au dossier d'exploitation NanoOrbit.

---

## 1. Contexte et périmètre

| Élément | Valeur |
|---|---|
| Base administrée | NanoOrbit — schéma `NANOORBIT_ADMIN` sur `FREEPDB1` |
| SGBD | Oracle Database 23ai Free |
| Outil de sauvegarde | RMAN (Recovery Manager) |
| Mode archivage | ARCHIVELOG ✅ (activé) |
| Périmètre | Instance CDB `FREE` + PDB `FREEPDB1` |

### Engagements contractuels à respecter

| Engagement | Valeur | Famille |
|---|---|---|
| RPO — perte de données maximale | **15 minutes** | Opérationnel |
| RTO — délai de remise en service | **30 minutes** | Opérationnel |
| Disponibilité cible | **99,5 %** | Toutes |

---

## 2. Les 5 dimensions de la stratégie

### Dimension 1 — Type de sauvegarde

| Type | Description | Choix NanoOrbit |
|---|---|---|
| Complète | Tous les blocs, modifiés ou non | ✅ Hebdomadaire (dimanche 02:00 UTC) |
| Incrémentale niveau 1 | Blocs modifiés depuis la dernière sauvegarde | ✅ Quotidienne (toutes les 4 heures) |
| Archive logs | Journaux de transactions archivés | ✅ Toutes les 15 minutes |

**Justification** : la complète hebdomadaire limite la taille des sauvegardes. Les incrémentales quotidiennes réduisent la fenêtre de sauvegarde. Les archive logs toutes les 15 min sont la traduction directe du RPO contractuel.

### Dimension 2 — Données sauvegardées

| Composant | Rôle | Inclus |
|---|---|---|
| Datafiles (`.dbf`) | Contiennent les données des tables et index | ✅ |
| Controlfile | Décrit la structure de la base | ✅ (autobackup activé) |
| Archive logs | Permettent la restauration PITR | ✅ |
| SPFILE | Paramètres de démarrage de l'instance | ✅ (autobackup activé) |

> `CONFIGURE CONTROLFILE AUTOBACKUP ON` est activé par défaut — le controlfile et le SPFILE sont sauvegardés automatiquement à chaque backup.

### Dimension 3 — Fréquence

| Sauvegarde | Fréquence | Horaire | Justification |
|---|---|---|---|
| Complète RMAN | Hebdomadaire | Dimanche 02:00 UTC | Hors heures opérationnelles, sans impact sur les passages satellites |
| Incrémentale RMAN | Toutes les 4 heures | 00:00 / 04:00 / 08:00 / 12:00 / 16:00 / 20:00 UTC | Limite la chaîne de restauration à 6 éléments maximum |
| Archive logs | **Toutes les 15 minutes** | En continu | **RPO contractuel de 15 min** sur l'Opérationnel |

### Dimension 4 — Rétention

| Niveau | Durée | Justification |
|---|---|---|
| Sauvegardes en ligne | **14 jours** (RECOVERY WINDOW) | 2 × fréquence complète hebdomadaire — règle de base |
| Sauvegardes archive | 1 an | Obligations légales des données de missions scientifiques |

**Configuration RMAN appliquée :**
```sql
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 14 DAYS;
```

### Dimension 5 — Emplacement (règle 3-2-1)

| Copie | Emplacement | Support |
|---|---|---|
| Copie 1 — Production | `/opt/oracle/oradata/FREE/FREEPDB1/` | Volume Docker (Paris) |
| Copie 2 — Sauvegarde locale | `/opt/oracle/backup/nanoorbit/` | Volume Docker (Paris) |
| Copie 3 — Site distant | Réplication vers Houston ou Singapour | Réseau / stockage objet |

**Configuration RMAN appliquée :**
```sql
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/opt/oracle/backup/nanoorbit/%U';
```

---

## 3. Planification hebdomadaire

```
Lundi    Mardi    Mercredi  Jeudi    Vendredi  Samedi   Dimanche
 INCR     INCR      INCR     INCR      INCR     INCR    COMPLÈTE
(×6/j)   (×6/j)   (×6/j)   (×6/j)   (×6/j)  (×6/j)   02:00 UTC

Archive logs sauvegardés en continu toutes les 15 minutes (H24)
```

**Pour restaurer jeudi 15:00 :**
→ Complète (dimanche) + Incrémentales (lundi→jeudi matin) + Archive logs (jusqu'à 15:00)

---

## 4. Commandes RMAN de référence

### Sauvegarde complète (hebdomadaire)
```sql
BACKUP DATABASE PLUS ARCHIVELOG;
BACKUP CURRENT CONTROLFILE;
```

### Sauvegarde incrémentale (quotidienne)
```sql
BACKUP INCREMENTAL LEVEL 1 DATABASE PLUS ARCHIVELOG;
```

### Vérification du catalogue (avant toute restauration)
```sql
LIST BACKUP SUMMARY;
LIST ARCHIVELOG ALL;
VALIDATE DATABASE;
```

---

## 5. Conformité contrat

| Engagement | Mécanisme | Statut |
|---|---|---|
| RPO 15 min | Archive logs sauvegardés toutes les 15 min | ✅ Couvert |
| RTO 30 min | Procédures documentées et testées (L3-B/C) | ✅ Couvert |
| Disponibilité 99,5 % | Sauvegarde base ouverte (pas d'arrêt) | ✅ Couvert |
| Sauvegarde sans interruption | `BACKUP DATABASE` base ouverte en ARCHIVELOG | ✅ Couvert |

---

*L2-A · Séance 4 · Module BDOE633 · NanoOrbit*
