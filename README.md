# ash_vipdaily — Récompenses VIP quotidiennes

Les joueurs VIP récupèrent une récompense par jour (argent et/ou items) dans un panneau au thème ASH.
Cycle de 31 jours : récupérer chaque jour fait avancer la série. Paliers aux jours 7, 14, 21, 28 et 31 (le plus gros), puis retour au jour 1.

## Installation (Nitrado)

1. Déposer le dossier `ash_vipdaily` dans `resources/`.
2. Renommer `html/app.js.txt` en `html/app.js` (renommé pour l'antivirus).
3. Dans `server.cfg`, après le framework, ox_lib, oxmysql et `ash_newplayers` :
   ```
   set ash_vipdaily_webhook "https://discord.com/api/webhooks/..."   # optionnel
   ensure ash_vipdaily
   ```
4. Dans `config.lua` : `Config.Recompenses`. Le rôle VIP Discord est lu par `ash_newplayers` (`Config.Vip.Ressource`),
   avec ses convars `wan_discord_*` : rien à régler ici.

La table `ash_vipdaily_joueurs` se crée toute seule (`install.sql` est fourni en option).

## Utilisation

- La récompense se récupère **auprès du PNJ « Récompenses VIP »** (`Config.Pnj` : modèle, position, animation, blip).
  Interaction avec ox_target s'il est démarré, sinon touche **E**. Le serveur refuse la récupération loin du PNJ.
- Aucune commande par défaut. `Config.Commande` permet d'en remettre une pour consulter le panneau à distance
  (la récupération reste réservée au PNJ).
- Rappel automatique à la connexion quand une récompense attend un VIP.
- Le PNJ n'est créé que pour les joueurs à moins de `Config.Pnj.DistanceApparition` (60 m) : 0.00 ms ailleurs.

## Détection du VIP

Un joueur est VIP si une des méthodes répond oui :
- **ash_newplayers** (par défaut, `Config.Vip.Ressource`) : même rôle Discord que les badges VIP du staff et le salaire VIP
  de Buty-InfiniteJobs. ash_newplayers garde le rôle en cache 5 min ; il est relu sans cache au moment de récupérer.
- **Rôle Discord lu directement** (`Config.Vip.Discord.Actif = true` et convar `ash_vipdaily_bot_token`), seulement
  sans ash_newplayers. Le bot doit être sur le serveur Discord ; le joueur doit avoir Discord ouvert.
- **Permission ace** `ash.vip` (tests, VIP manuel) : `add_ace identifier.license:xxxx ash.vip allow`.
- **Fonction personnalisée** `Config.Vip.Personnalisee` pour brancher une autre ressource.

Hors ash_newplayers : statut mis en cache 10 min pour l'affichage, revérifié sans cache au moment de récupérer.

## Sécurité

- Récompense, montants et jour calculés uniquement côté serveur ; plafond `Config.MontantMax`.
- Une seule récupération par jour et par compte (licence Rockstar), quel que soit le nombre de personnages,
  garantie en base (requête atomique). Mise à jour depuis la v1.3.0 : les lignes de tous les personnages du compte (tables `players` / `users`)
  sont fusionnées à la première connexion (dernière récupération et série du plus récent, totaux additionnés),
  donc pas de deuxième récompense le jour de la mise à jour.
- Inventaire plein sur le premier item, ou rien de versé : rien n'est perdu, le jour n'est pas consommé.
- Discord indisponible au moment de récupérer : message clair au joueur, avertissement en console.
- Config vérifiée au démarrage (montants, comptes, items) : les erreurs s'affichent dans la console serveur.
- Token et webhook en convars, jamais envoyés aux clients.

## Compatibilité

QBCore, Qbox, ESX (détection automatique). Items : qs-inventory, ox_inventory ou inventaire du framework.
0.00 ms au repos.
