# Séance 4 — Étape 2 : Les 5 dimensions de la stratégie de sauvegarde

> **Module BDOE633 · Séance 4 · Temps 2 (20 min)**
> Produit le livrable **L2-A** — Stratégie de sauvegarde/restauration NanoOrbit.

---

## Introduction : une stratégie, pas une recette

Une stratégie de sauvegarde ne se résume pas à "faire une copie de la base tous les jours". Elle répond à **5 questions précises**, et chaque réponse doit se justifier par le contrat de services.

```
Contrat de services
       ↓
  5 dimensions          →    Stratégie de sauvegarde (L2-A)
       ↓
  Mise en œuvre RMAN    →    Scripts + tests (L3-A/B/C, séance 5)
```

---

## Dimension 1 — Type de sauvegarde

### Les trois types possibles

| Type | Ce qui est sauvegardé | Taille | Temps de restauration |
|---|---|---|---|
| **Complète** | Tous les blocs de données, qu'ils aient changé ou non | Grande | Court — une seule sauvegarde suffit |
| **Différentielle** | Tous les blocs modifiés depuis la **dernière complète** | Moyenne | Moyen — besoin de la complète + la différentielle |
| **Incrémentale** | Uniquement les blocs modifiés depuis la **dernière sauvegarde** (complète ou incrémentale) | Petite | Long — besoin de la complète + toutes les incrémentales |

### Illustration

```
Lundi    Mardi    Mercredi   Jeudi    Vendredi   Samedi   Dimanche
COMPLÈTE  INCR     INCR      INCR      INCR       INCR    COMPLÈTE
  100MB   2MB      3MB       2MB       4MB        2MB      100MB

Pour restaurer jeudi soir :
  → COMPLÈTE (lundi) + INCR (mardi) + INCR (mercredi) + INCR (jeudi)
```

### Choix NanoOrbit

**Complète hebdomadaire + incrémentale quotidienne.**

Justification : la base NanoOrbit est de taille modeste (quelques centaines de Mo). Une complète hebdomadaire reste rapide. Les incrémentales quotidiennes minimisent la fenêtre de sauvegarde tout en limitant la chaîne de restauration à 7 éléments maximum.

---

## Dimension 2 — Données à sauvegarder

Dans Oracle, "sauvegarder la base" ne signifie pas sauvegarder uniquement les tables. Une restauration complète nécessite **4 types de fichiers**.

### Les 4 composants obligatoires

| Composant | Rôle | Conséquence si absent |
|---|---|---|
| **Datafiles** (`.dbf`) | Contiennent les données des tables et index | Sans eux, aucune donnée n'est restaurable |
| **Control file** | Décrit la structure de la base (liste des datafiles, des redo logs, historique des sauvegardes) | Sans lui, Oracle ne sait pas quels fichiers constituent la base |
| **Archive logs** | Journaux de transactions archivés — permettent de rejouer les modifications depuis la dernière sauvegarde | Sans eux, impossible de respecter le RPO de 15 min |
| **SPFILE** | Paramètres de démarrage de l'instance Oracle (tailles mémoire, chemins, etc.) | Sans lui, l'instance ne peut pas redémarrer avec les bons paramètres |

### Analogie

Imaginez votre base comme un immeuble :
- Les **datafiles** sont les appartements (les données).
- Le **control file** est le registre de propriété (qui sait que l'immeuble existe et où il est).
- Les **archive logs** sont le journal du gardien (tout ce qui s'est passé depuis la dernière photo).
- Le **SPFILE** est le plan électrique (sans lui, impossible de rallumer les lumières correctement).

> Perdre un seul de ces composants peut rendre la restauration incomplète ou impossible.

### Choix NanoOrbit

Sauvegarder les **4 composants** : `datafiles + controlfile + archivelogs + SPFILE`.

---

## Dimension 3 — Fréquence

La fréquence est directement dictée par le **RPO** du contrat de services.

### Rappel RPO

Le RPO (*Recovery Point Objective*) est la perte de données maximale acceptable. Un RPO de 15 min signifie : en cas de sinistre, on peut perdre au maximum 15 minutes de données.

```
Dernière sauvegarde          Incident
       ↓                        ↓
───────┼────────────────────────┼───────
       │←──── perte de données ─────→│
                  ≤ RPO
```

### Calcul de la fréquence des archive logs

Si les archive logs sont sauvegardés toutes les heures, et qu'un incident survient, on perd au maximum 1 heure de données → RPO = 1h. Pour respecter le RPO de **15 min**, les archive logs doivent être sauvegardés **toutes les 15 minutes**.

### Planification NanoOrbit

| Sauvegarde | Fréquence | Horaire | Justification |
|---|---|---|---|
| Complète (RMAN) | Hebdomadaire | Dimanche 02:00 UTC | Hors heures opérationnelles, impact nul sur les passages satellites |
| Incrémentale (RMAN) | Quotidienne | 00:00, 04:00, 08:00, 12:00, 16:00, 20:00 UTC | Toutes les 4h pour limiter la chaîne de restauration |
| Archive logs | Toutes les 15 min | En continu | **RPO contractuel de 15 min** sur l'Opérationnel |

> ⚠️ La sauvegarde des archive logs toutes les 15 min **nécessite le mode ARCHIVELOG** activé sur la base. Sans ce mode, Oracle écrase les redo logs sans les archiver → RPO de 15 min impossible à tenir.

---

## Dimension 4 — Rétention

La rétention définit combien de temps les sauvegardes sont conservées avant d'être supprimées.

### La règle de base

Conserver **au minimum 2 fois la fréquence de la sauvegarde complète**. Pour NanoOrbit (complète hebdomadaire) :

```
2 × 7 jours = 14 jours minimum
```

Cela garantit qu'en cas de découverte tardive d'une corruption (ex. : corruption détectée 8 jours après), on dispose toujours d'une sauvegarde complète valide précédente pour restaurer.

### Politique de rétention NanoOrbit

| Niveau | Durée de conservation | Justification |
|---|---|---|
| Sauvegardes en ligne (restauration rapide) | **30 jours** | Couvre les incidents détectés tardivement |
| Sauvegardes archive (restauration différée) | **1 an** | Obligations légales des données de missions scientifiques |
| Sauvegardes froides annuelles | **7 ans** | Contrats de missions à long terme |

### Dans RMAN, la rétention se configure ainsi

```sql
RMAN> CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 14 DAYS;
-- Oracle conserve assez de sauvegardes pour restaurer n'importe quel
-- point dans les 14 derniers jours.
```

---

## Dimension 5 — Emplacement de stockage

### La règle 3-2-1

C'est la règle d'or de la sauvegarde, universellement reconnue :

```
3 copies des données
  └── sur 2 supports différents
        └── dont 1 copie hors site (distante)
```

| Règle | Ce que ça signifie pour NanoOrbit | Risque couvert |
|---|---|---|
| **3 copies** | Données originales + sauvegarde locale + sauvegarde distante | Une copie corrompue ne compromet pas tout |
| **2 supports** | Disque Docker local + volume réseau ou stockage objet | Panne matérielle du serveur principal |
| **1 hors site** | Copie vers le centre Singapour ou Houston | Incendie, inondation, destruction du datacenter Paris |

### Application NanoOrbit

```
Copie 1 : Base active dans Docker (Paris)
           /opt/oracle/oradata/FREE/FREEPDB1/

Copie 2 : Sauvegarde RMAN locale (Paris)
           /opt/oracle/backup/nanoorbit/

Copie 3 : Réplication vers site distant (Singapour ou Houston)
           simulée dans notre environnement Docker
```

---

## Synthèse — La stratégie retenue (Livrable L2-A)

| Dimension | Choix NanoOrbit | Justification contrat |
|---|---|---|
| **Type** | Complète hebdomadaire + incrémentale quotidienne | Volume maîtrisé, fenêtre de sauvegarde courte |
| **Données** | Datafiles + controlfile + archivelogs + SPFILE | Restauration complète garantie dans tous les scénarios |
| **Fréquence archivelogs** | Toutes les **15 minutes** | RPO contractuel de 15 min sur l'Opérationnel |
| **Rétention** | **14 jours** minimum en ligne | 2 × fréquence complète hebdomadaire |
| **Emplacement** | Local Docker + copie distante simulée | Règle 3-2-1 / multi-sites Paris-Singapour-Houston |

---

## À retenir

> Une stratégie de sauvegarde n'est pas un choix technique arbitraire.
> **Chaque dimension se justifie par une ligne du contrat de services.**
>
> - RPO 15 min → archive logs toutes les 15 min → **mode ARCHIVELOG obligatoire**
> - RTO 30 min → procédures testées et chronométrées → **séance 5**
> - Disponibilité 99,5 % → sauvegarde sans arrêt de la base → **sauvegarde base ouverte**

---

*Séance 4 · Temps 2 · Module BDOE633 — Livrable L2-A*
