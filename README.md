# ash_vipdaily — Récompenses VIP quotidiennes

Chaque jour, les joueurs VIP ouvrent un **coffre** auprès du PNJ « Récompenses VIP », dans un panneau au thème ASH.
Cycle de 31 jours : ouvrir chaque jour fait avancer la série. Paliers aux jours 7, 14, 21, 28 et 31 (le plus gros), puis retour au jour 1.

## Installation (Nitrado)

1. Déposer le dossier `ash_vipdaily` dans `resources/`.
2. Dans `server.cfg`, après le framework, ox_lib, oxmysql, `ash_newplayers` et `ash_notify` :
   ```
   set ash_vipdaily_webhook "https://discord.com/api/webhooks/..."   # optionnel
   ensure ash_vipdaily
   ```
3. Dans `config.lua` : `Config.Recompenses`, `Config.Pnj`. Le rôle VIP Discord est lu par `ash_newplayers` (`Config.Vip.Ressource`),
   avec ses convars `wan_discord_*` : rien à régler ici.

La table `ash_vipdaily_joueurs` se crée toute seule, et les colonnes de la v2.0.0 sont ajoutées automatiquement
à une table existante au démarrage (aucun SQL à importer ; `install.sql` est fourni en option).

## Ce qui donne envie de revenir

- **Coffre du jour** : il s'ouvre avec une animation. Argent = montant du jour (`Config.Recompenses`) × rang de série ×
  **bonus surprise** tiré par le serveur (`Config.Bonus` : ×1, ×1,25, ×1,5 ou ×2 par défaut), arrondi à la centaine
  et jamais au-delà de `Config.MontantMax`. Les objets du jour sont donnés tels quels.
- **Série et rangs** (`Config.Rangs`) : Bronze ×1, Argent ×1,1 (7 j), Or ×1,2 (14 j), Platine ×1,3 (21 j), Diamant ×1,5 (28 j).
  La série et le rang restent affichés en haut du panneau.
- **Demain** : le panneau annonce le coffre du lendemain et ce qu'il peut rapporter au maximum.
- **Chaîne de 7 jours** : les jours faits, manqués, aujourd'hui et les prochains paliers.
- **Boucliers de série** (`Config.Boucliers`) : un jour manqué (un seul) ne casse pas la série ; le bouclier est utilisé
  automatiquement. Un bouclier offert au départ, d'autres à gagner avec les défis, 3 au maximum.
- **Défis de la semaine** (`Config.Defis`, remis à zéro le lundi) : ouvrir 5 coffres, jouer 3 h, atteindre un palier.
  Chaque défi réussi donne une **clé** (et un bouclier pour le palier).
- **Coffre légendaire** (`Config.CoffreLegendaire`) : s'ouvre auprès du PNJ avec 3 clés.
- **Classement** (`Config.Classement`) : les meilleures séries VIP en cours (prénom + initiale), et ta place.

Le temps de jeu du défi « Jouer 3 h » est compté pour les comptes qui ont déjà ouvert au moins un coffre, enregistré
toutes les 10 minutes et à la déconnexion.

## Utilisation

- Le coffre s'ouvre **auprès du PNJ « Récompenses VIP »** (`Config.Pnj` : modèle, position, animation, blip).
  Interaction avec ox_target s'il est démarré, sinon touche **E**. Le serveur refuse l'ouverture loin du PNJ.
- Aucune commande par défaut. `Config.Commande` permet d'en remettre une pour consulter le panneau à distance
  (les coffres restent réservés au PNJ).
- Rappel à la connexion quand un coffre attend un VIP : désactivé par défaut (`Config.RappelConnexion`).
- Le PNJ n'est créé que pour les joueurs à moins de `Config.Pnj.DistanceApparition` (60 m) : 0.00 ms ailleurs.

## Détection du VIP

Un joueur est VIP si une des méthodes répond oui :
- **ash_newplayers** (par défaut, `Config.Vip.Ressource`) : même rôle Discord que les badges VIP du staff et le salaire VIP
  de Buty-InfiniteJobs. ash_newplayers garde le rôle en cache 5 min ; il est relu sans cache au moment d'ouvrir un coffre.
- **Rôle Discord lu directement** (`Config.Vip.Discord.Actif = true` et convar `ash_vipdaily_bot_token`), seulement
  sans ash_newplayers. Le bot doit être sur le serveur Discord ; le joueur doit avoir Discord ouvert.
- **Permission ace** `ash.vip` (tests, VIP manuel) : `add_ace identifier.license:xxxx ash.vip allow`.
- **Fonction personnalisée** `Config.Vip.Personnalisee` pour brancher une autre ressource.

Hors ash_newplayers : statut mis en cache 10 min pour l'affichage, revérifié sans cache au moment d'ouvrir.

## Sécurité

- Coffres, bonus, rangs, montants, défis et clés calculés uniquement côté serveur ; plafond `Config.MontantMax`.
- Un seul coffre par jour et par compte (licence Rockstar), quel que soit le nombre de personnages,
  garanti en base (requête atomique). Mise à jour depuis la v1.3.0 : les lignes de tous les personnages du compte (tables `players` / `users`)
  sont fusionnées à la première connexion (dernière récupération et série du plus récent, totaux additionnés).
- Défis validés une seule fois par semaine, clés retirées en base avant l'ouverture du coffre légendaire (rendues si rien n'est remis).
- Inventaire plein sur le premier item, ou rien de versé : rien n'est perdu, le jour (ou les clés) n'est pas consommé.
- Discord indisponible au moment d'ouvrir : message clair au joueur, avertissement en console.
- Config vérifiée au démarrage (montants, comptes, items, rangs, bonus) : les erreurs s'affichent dans la console serveur.
- Token et webhook en convars, jamais envoyés aux clients. Interface sans `innerHTML`.

## Compatibilité

QBCore, Qbox, ESX (détection automatique). Items : qs-inventory, ox_inventory ou inventaire du framework.
Notifications : ash_notify (`Config.Notifications`, son réglable par type), ox_lib si ash_notify n'est pas démarrée.
Menu pause : ash_pausemenu lit un résumé léger de l'état du jour (callback `ash_vipdaily:server:resume`, depuis la v2.0.1).
0.00 ms au repos.
