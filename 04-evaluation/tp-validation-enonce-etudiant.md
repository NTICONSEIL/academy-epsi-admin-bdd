# TP DE VALIDATION — BDOE633
## Administration et Optimisation des Bases de Données

**Module** : BDOE633 · Bachelor SIN — Spécialisation SysOps · 3ème année  
**Durée** : 1h30  
**Modalité** : Individuel — base Oracle 23ai NanoOrbit fournie  
**Évaluation** : Note formative de fin de module

---

## Contexte

Il est **03h17**. Vous êtes DBA d'astreinte chez NanoOrbit.

Le système de surveillance automatique vient de déclencher deux alertes simultanées :

> 🔴 **ALERTE #1** — `TBS_OPERATION` : taux d'occupation > 85 %  
> 🔴 **ALERTE #2** — Des fenêtres de communication ont été supprimées par erreur

En tant qu'administrateur, vous devez diagnostiquer, corriger et prévenir.  
Le contrat de services vous impose : **disponibilité 99,5 %**, **RPO 15 min**, **RTO 30 min**.

---

## Connexion à la base

```
Utilisateur  : NANOORBIT_ADMIN
Mot de passe : NanoOrbit_2026
Service      : localhost:1521/FREEPDB1
```

---

## BLOC A — Diagnostic du stockage (20 min)

### Contexte

L'alerte indique que `TBS_OPERATION` approche de la saturation. Avant d'agir, vous devez établir un diagnostic complet.

### Questions

**A1.** Exécutez une requête sur les vues du dictionnaire de données pour afficher, pour chaque tablespace NanoOrbit (`TBS_OPERATION`, `TBS_REFERENTIEL`, `TBS_HISTORIQUE`) :
- la taille totale allouée (en MB)
- l'espace libre (en MB)
- le taux d'occupation (en %)

**A2.** Identifiez les 3 tables qui occupent le plus d'espace dans `TBS_OPERATION`. Quelle vue avez-vous utilisée ?

**A3.** Le tablespace `TBS_OPERATION` est configuré avec `AUTOEXTEND OFF` et ne peut plus croître. Rédigez la commande permettant de lui ajouter de l'espace en ajoutant un second fichier de données de 10 MB avec `AUTOEXTEND ON NEXT 5M MAXSIZE 200M`.

> **Rappel chemin** : `/opt/oracle/oradata/FREE/FREEPDB1/`

**A4.** Exécutez la commande A3 et vérifiez avec une nouvelle requête que le taux d'occupation est redescendu en dessous de 50 %.

**A5.** En une phrase, expliquez pourquoi `TBS_OPERATION` est le tablespace le plus critique au regard du contrat de services.

---

## BLOC B — Sauvegarde RMAN (25 min)

### Contexte

Le contrat impose un RPO de 15 minutes sur les données opérationnelles. Il n'existe aucune sauvegarde récente de la base. Vous devez en réaliser une et en vérifier l'intégrité.

### Questions

**B1.** Vérifiez que la base est en mode `ARCHIVELOG`. Quelle requête avez-vous utilisée ? Quel est le résultat ?

**B2.** Connectez-vous à RMAN et lancez une **sauvegarde complète de la base ouverte** incluant les archivelogs, puis sauvegardez le controlfile. Collez la sortie RMAN dans votre livrable.

```
Connexion RMAN :
rman target sys/NanoOrbit_Sys2026@localhost:1521/FREE
```

**B3.** Après la sauvegarde, exécutez `LIST BACKUP SUMMARY` dans RMAN. Combien de pièces (*pieces*) ont été créées ? Quel est l'espace disque total occupé ?

**B4.** Exécutez `VALIDATE DATABASE` dans RMAN. Quel est le résultat ? Que vérifie cette commande ?

**B5.** D'après le résultat de B3, si un incident se produisait maintenant, quel serait votre RPO réel ? Est-il compatible avec le contrat ?

---

## BLOC C — Restauration (25 min)

### Contexte

⚠️ **INCIDENT EN COURS** — Des fenêtres de communication avec le statut `Planifiée` viennent d'être supprimées par erreur. L'heure de la suppression vous a été communiquée par l'instructeur.

> Heure de l'incident : **`____________________`** *(à noter dès l'annonce)*

### Questions

**C1.** Vérifiez l'état actuel de la table `FENETRE_COM` : combien de lignes reste-t-il ? Combien y en avait-il avant l'incident ? *(Utilisez `HISTORIQUE_STATUT` ou votre connaissance du jeu de données initial pour justifier.)*

**C2.** Tentez d'abord une restauration par **Flashback Table**. Rédigez et exécutez la commande. Cela fonctionne-t-il ? Justifiez pourquoi cela peut fonctionner ou échouer selon le délai écoulé.

```sql
-- Aide mémoire Flashback Table
FLASHBACK TABLE FENETRE_COM TO TIMESTAMP
  TO_TIMESTAMP('YYYY-MM-DD HH24:MI:SS', 'YYYY-MM-DD HH24:MI:SS');
```

**C3.** Si Flashback Table ne fonctionne pas (ou pour les étudiants dont le délai dépasse `UNDO_RETENTION`), réalisez une **restauration PITR via RMAN** jusqu'à l'instant juste avant l'incident.

```
RMAN> SHUTDOWN IMMEDIATE;
RMAN> STARTUP MOUNT;
RMAN> SET UNTIL TIME "TO_DATE('...','YYYY-MM-DD HH24:MI:SS')";
RMAN> RESTORE DATABASE;
RMAN> RECOVER DATABASE;
RMAN> ALTER DATABASE OPEN RESETLOGS;
```

**C4.** Vérifiez le résultat : affichez le nombre de lignes dans `FENETRE_COM` après restauration. Collez la sortie.

**C5.** Mesurez le temps total écoulé entre l'annonce de l'incident et la confirmation de la restauration. Comparez-le au **RTO contractuel de 30 minutes**. Quel est votre verdict ?

---

## BLOC D — Supervision avec les vues V$ (20 min)

### Contexte

La direction souhaite être prévenue **avant** les incidents, pas après. Vous devez mettre en place des requêtes de supervision basées sur les vues `V$` disponibles dans Oracle 23ai Free.

### Questions

**D1.** Rédigez une requête sur `V$SESSION` (connexion en **SYS**) qui affiche toutes les sessions actives sur la base, avec : nom d'utilisateur, machine d'origine, programme utilisé, statut de la session, et heure de connexion. Combien de sessions sont actives en ce moment ?

**D2.** Rédigez une requête combinant `DBA_DATA_FILES` et `DBA_FREE_SPACE` pour afficher le taux d'occupation de chaque tablespace, triée du plus rempli au moins rempli. Cette requête constitue votre **tableau de bord stockage**.

**D3.** Rédigez une requête sur `V$ARCHIVED_LOG` qui affiche les 5 derniers archivelogs générés, avec leur date de complétion, leur taille et leur statut. À quoi sert cet indicateur pour un DBA ?

**D4.** En vous appuyant sur les résultats de D1, D2 et D3, remplissez ce tableau de KPI pour NanoOrbit au moment de votre TP :

| KPI | Valeur mesurée | Seuil contrat | Statut |
|-----|---------------|--------------|--------|
| Taux d'occupation TBS_OPERATION | | < 85 % | |
| Taux d'occupation TBS_HISTORIQUE | | < 70 % | |
| Nombre de sessions actives | | < 20 | |
| Dernier archivelog < 30 min | | Oui | |

**D5.** Proposez, en 3 à 5 lignes, comment vous organiseriez une surveillance régulière de ces KPI dans un contexte de production réel (sans OEM Cloud Control — uniquement les outils disponibles sur Oracle 23ai Free).

---

## Livrable à remettre

Un **document unique** (Markdown, texte ou PDF) contenant pour chaque question :
- la commande ou requête SQL/RMAN utilisée
- la sortie obtenue (copier-coller du terminal)
- votre interprétation ou justification en une à deux phrases

**Nom du fichier** : `NOM_Prenom_BDOE633_TP_Validation.md`

---

## Barème indicatif

| Bloc | Points |
|------|--------|
| A — Diagnostic stockage | 4 pts |
| B — Sauvegarde RMAN | 5 pts |
| C — Restauration | 6 pts |
| D — Supervision V$ | 5 pts |
| **Total** | **20 pts** |

> La qualité des **justifications contractuelles** (référence explicite au RPO, RTO ou taux de disponibilité) est valorisée dans chaque bloc.

---

*BDOE633 · Administration et Optimisation des Bases de Données · EPSI · 2025-2026*
