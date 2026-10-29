# CODEMAP — vip_gh

> Généré par `codemap.py` v2 : **ne pas modifier à la main**. Régénérer après chaque modification du code.
> Format : `nom` suivi du numéro de ligne → lire seulement les lignes utiles (Read avec offset).

**11 fichiers · 1638 lignes** · 8 lua · 1 sql · 1 js · 1 html

## Ressources FiveM

- **vip_gh** (fx cerulean, v 1.5.1, lua54 yes)
  - partagé : `@ox_lib/init.lua`, `config.lua`, `locales/fr.lua`, `bridge/shared.lua`
  - client : `bridge/client.lua`, `client/main.lua`
  - serveur : `@oxmysql/lib/MySQL.lua`, `bridge/server.lua`, `server/main.lua`
  - ui_page : `html/index.html`
  - dépendances : `ox_lib`, `oxmysql`

## Liens entre fichiers

- `ash_vipdaily:client:notifier` : émis `server/main.lua:24` → écouté `client/main.lua:37`
- callback `ash_vipdaily:server:action` : déclaré `server/main.lua:488` ← appelé `client/main.lua:70`
- callback `ash_vipdaily:server:ouvrir` : déclaré `server/main.lua:467` ← appelé `client/main.lua:46`
- callback `ash_vipdaily:server:rappel` : déclaré `server/main.lua:479` ← appelé `client/main.lua:205`
- NUI `action` : JS `html/app.js:248` → Lua `client/main.lua:68`
- NUI `fermer` : JS `html/app.js:231` → Lua `client/main.lua:63`
- NUI action `fermer` : Lua `client/main.lua:58` → JS `html/app.js:226`
- NUI action `ouvrir` : Lua `client/main.lua:51` → JS `html/app.js:225`

## Fichiers

### config.lua — config · 148 l.
- clés de config : `Config.Langue` 4, `Config.Debug` 7, `Config.Framework` 10, `Config.Notifications` 16, `Config.Commande` 26, `Config.Touche` 27, `Config.Pnj` 32, `Config.StaffSeulement` 50, `Config.AcePermission` 51, `Config.DelaiActions` 54, `Config.DelaiOuverture` 55, `Config.Vip` 62, `Config.HeureReinitialisation` 93, `Config.SerieStricte` 97, `Config.Recompenses` 107, `Config.MontantMax` 142, `Config.RappelConnexion` 145

### fxmanifest.lua — manifeste · 41 l.
- (aucun symbole)

### install.sql — 10 l.
- tables créées : `ash_vipdaily_joueurs` 3

### bridge/client.lua — client · 77 l.
- framework : QBCore, Qbox, Bridge
- exports utilisés : `qb-core:GetCoreObject` 11, `es_extended:getSharedObject` 13, `qbx_core:GetPlayerData` 25
- fonctions : `normaliserJob(job)` 16, `donneesBrutes()` 24, `estCharge()` 30, `Bridge.GetPlayerData()` 35, `Bridge.OnPlayerLoaded(cb)` 58, `Bridge.OnJobUpdate(cb)` 72
- threads : 1 (l. 66)

### bridge/server.lua — serveur · 141 l.
- framework : Qbox, Bridge
- exports utilisés : `qb-core:GetCoreObject` 14, `es_extended:getSharedObject` 16, `qbx_core:GetPlayer` 22, `qbx_core:GetMoney` 78, `qbx_core:AddMoney` 93, `qbx_core:RemoveMoney` 109, `qs-inventory:AddItem` 125, `ox_inventory:CanCarryItem` 127, `ox_inventory:AddItem` 128
- fonctions : `joueurBrut(source)` 21, `montantValide(montant)` 27, `Bridge.GetPlayer(source)` 33, `Bridge.HasJob(source, metiers, gradeMin)` 57, `Bridge.GetMoney(source, compte)` 69, `Bridge.AddMoney(source, compte, montant, raison)` 83, `Bridge.RemoveMoney(source, compte, montant, raison)` 98, `demarree(nom)` 118, `Bridge.AddItem(source, item, quantite)` 120

### bridge/shared.lua — partagé · 30 l.
- framework : Qbox, Bridge
- fonctions : `demarree(ressource)` 6, `detecter()` 11

### client/main.lua — client · 209 l.
- framework : ox_lib, Bridge
- écoute (events) : `ash_vipdaily:client:notifier` 37, `onResourceStop` 192
- callbacks appelés : `ash_vipdaily:server:ouvrir` 46, `ash_vipdaily:server:action` 70, `ash_vipdaily:server:rappel` 205
- NUI : callbacks reçus : `fermer` 63, `action` 68
- NUI : messages envoyés : `ouvrir` 51, `fermer` 58
- exports fournis : `GuiderVersPnj` 184
- exports utilisés : `ox_target:removeLocalEntity` 93, `ox_target:addLocalEntity` 120
- fonctions : `notifier(message, typeNotif, duree)` 14, `ouvrir()` 42, `fermer()` 54, `supprimerPed()` 90, `creerPed()` 100, `cacherTexte()` 131, `nearby()` 164, `onExit()` 175

### html/app.js — NUI · 259 l.
- NUI : callbacks envoyés au Lua : `fermer` 231, `action` 248
- NUI : actions reçues : `ouvrir` 225, `fermer` 226
- fonctions : `envoyer(nom, donnees = {})` 17, `texte(id, valeur)` 28, `el(balise, classe, contenu)` 33, `duree(total)` 40, `montant(lot)` 47, `jourEnCours()` 52, `nbJours()` 53, `demarrerMinuteur()` 56, `majTemps()` 65, `construireGrille()` 73, `construireHero()` 104, `construireSerie()` 182, `rendre()` 189, `appliquer(nouvelEtat)` 196, `afficher(donnees, titre)` 205, `masquer()` 214

### html/index.html — NUI · 96 l.
- écrans / sections : `calendrier` 23, `serie` 73
- scripts : `app.js`
- styles : `style.css`

### locales/fr.lua — partagé · 37 l.
- fonctions : `_L(cle, ...)` 30

### server/main.lua — serveur · 590 l.
- framework : ox_lib, Bridge
- écoute (events) : `playerDropped` 585
- émet → client : `ash_vipdaily:client:notifier` 24
- callbacks déclarés : `ash_vipdaily:server:ouvrir` 467, `ash_vipdaily:server:rappel` 479, `ash_vipdaily:server:action` 488
- fonctions : `debug(...)` 14, `avertir(message)` 18, `notifier(source, message, typeNotif)` 23, `estStaff(source)` 27, `autorise(source)` 32, `pasTropRapide(source, historique, delai, prevenir)` 42, `logDiscord(titre, description, couleur)` 53, `verifierConfig()` 73, `cleCompte(source)` 111, `idDiscord(source)` 118, `roleDiscordVip(source)` 124, `terminer(vip, erreur)` 137, `vipParRessource(source, forcer)` 172, `estVip(source, forcer)` 198, `jour(decalageJours)` 237, `secondesAvantReinit()` 242, `indexRecompense(serie)` 248, `listeRecompenses()` 255, `personnagesDuCompte(source, personnageActuel)` 293, `ajouter(id)` 295, `ligneJoueur(source, cle, personnageActuel)` 334, `serieSuivante(ligne)` 369, `etat(source, joueur, cle, connu)` 376, `donnerRecompense(source, recompense)` 410, `presDuPnj(source)` 456, `finir(resultat)` 508
- tables SQL : `users` 314, `players` 318, `ash_vipdaily_joueurs` 354, `ash_vipdaily_joueurs` 358, `ash_vipdaily_joueurs` 543, `ash_vipdaily_joueurs` 557
- threads : 1 (l. 277)
