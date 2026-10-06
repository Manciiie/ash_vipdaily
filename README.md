# ash_vipdaily — Récompenses VIP quotidiennes

Les joueurs VIP récupèrent une récompense par jour (argent et/ou items) dans un panneau au thème ASH.
Cycle de 7 jours (modifiable) : récupérer chaque jour fait avancer la série, le dernier jour est le plus gros.

## Installation (Nitrado)

1. Déposer le dossier `ash_vipdaily` dans `resources/`.
2. Renommer `html/app.js.txt` en `html/app.js` (renommé pour l'antivirus).
3. Dans `server.cfg`, après le framework, ox_lib et oxmysql :
   ```
   set ash_vipdaily_bot_token "TOKEN_DU_BOT_DISCORD"
   set ash_vipdaily_webhook "https://discord.com/api/webhooks/..."   # optionnel
   ensure ash_vipdaily
   ```
4. Dans `config.lua` : `Config.Vip.Discord.ServeurId`, `Config.Vip.Discord.Roles` (ID du rôle VIP) et `Config.Recompenses`.

La table `ash_vipdaily_joueurs` se crée toute seule (`install.sql` est fourni en option).

## Utilisation

- `/recompenses` : ouvre le panneau (aucune touche par défaut, `Config.Touche` pour en mettre une).
- Rappel automatique à la connexion quand une récompense attend un VIP.

## Détection du VIP

Un joueur est VIP si une des méthodes répond oui :
- **Rôle Discord** lu via l'API Discord (le bot doit être sur le serveur Discord ; le joueur doit avoir Discord ouvert pour que FiveM transmette son ID).
- **Permission ace** `ash.vip` (tests, VIP manuel) : `add_ace identifier.license:xxxx ash.vip allow`.
- **Fonction personnalisée** `Config.Vip.Personnalisee` pour brancher une autre ressource.

Statut mis en cache 10 min pour l'affichage, revérifié sans cache au moment de récupérer.

## Sécurité

- Récompense, montants et jour calculés uniquement côté serveur ; plafond `Config.MontantMax`.
- Une seule récupération par jour et par personnage, garantie en base (requête atomique).
- Inventaire plein sur le premier item : rien n'est donné, le jour n'est pas consommé.
- Token et webhook en convars, jamais envoyés aux clients.

## Compatibilité

QBCore, Qbox, ESX (détection automatique). Items : qs-inventory, ox_inventory ou inventaire du framework.
0.00 ms au repos.
