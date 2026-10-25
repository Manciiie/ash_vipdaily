# CODEMAP — vip_gh

> Généré par `codemap.py` v2 : **ne pas modifier à la main**. Régénérer après chaque modification du code.
> Format : `nom` suivi du numéro de ligne → lire seulement les lignes utiles (Read avec offset).

**11 fichiers · 1587 lignes** · 8 lua · 1 sql · 1 js · 1 html

## Ressources FiveM

- **vip_gh** (fx cerulean, v 1.4.0, lua54 yes)
  - partagé : `@ox_lib/init.lua`, `config.lua`, `locales/fr.lua`, `bridge/shared.lua`
  - client : `bridge/client.lua`, `client/main.lua`
  - serveur : `@oxmysql/lib/MySQL.lua`, `bridge/server.lua`, `server/main.lua`
  - ui_page : `html/index.html`
  - dépendances : `ox_lib`, `oxmysql`

## Liens entre fichiers

- callback `ash_vipdaily:server:action` : déclaré `server/main.lua:491` ← appelé `client/main.lua:37`
- callback `ash_vipdaily:server:ouvrir` : déclaré `server/main.lua:470` ← appelé `client/main.lua:13`
- callback `ash_vipdaily:server:rappel` : déclaré `server/main.lua:482` ← appelé `client/main.lua:163`
- NUI `action` : JS `html/app.js:248` → Lua `client/main.lua:35`
- NUI `fermer` : JS `html/app.js:231` → Lua `client/main.lua:30`
- NUI action `fermer` : Lua `client/main.lua:25` → JS `html/app.js:226`
- NUI action `ouvrir` : Lua `client/main.lua:18` → JS `html/app.js:225`

## Fichiers

### config.lua — config · 137 l.
- clés de config : `Config.Langue` 4, `Config.Debug` 7, `Config.Framework` 10, `Config.Commande` 15, `Config.Touche` 16, `Config.Pnj` 21, `Config.StaffSeulement` 39, `Config.AcePermission` 40, `Config.DelaiActions` 43, `Config.DelaiOuverture` 44, `Config.Vip` 51, `Config.HeureReinitialisation` 82, `Config.SerieStricte` 86, `Config.Recompenses` 96, `Config.MontantMax` 131, `Config.RappelConnexion` 134

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

### client/main.lua — client · 167 l.
- framework : ox_lib, Bridge
- écoute (events) : `onResourceStop` 150
- callbacks appelés : `ash_vipdaily:server:ouvrir` 13, `ash_vipdaily:server:action` 37, `ash_vipdaily:server:rappel` 163
- NUI : callbacks reçus : `fermer` 30, `action` 35
- NUI : messages envoyés : `ouvrir` 18, `fermer` 25
- exports utilisés : `ox_target:removeLocalEntity` 60, `ox_target:addLocalEntity` 87
- fonctions : `ouvrir()` 9, `fermer()` 21, `supprimerPed()` 57, `creerPed()` 67, `cacherTexte()` 98, `nearby()` 131, `onExit()` 142

### html/app.js — NUI · 259 l.
- NUI : callbacks envoyés au Lua : `fermer` 231, `action` 248
- NUI : actions reçues : `ouvrir` 225, `fermer` 226
- fonctions : `envoyer(nom, donnees = {})` 17, `texte(id, valeur)` 28, `el(balise, classe, contenu)` 33, `duree(total)` 40, `montant(lot)` 47, `jourEnCours()` 52, `nbJours()` 53, `demarrerMinuteur()` 56, `majTemps()` 65, `construireGrille()` 73, `construireHero()` 104, `construireSerie()` 182, `rendre()` 189, `appliquer(nouvelEtat)` 196, `afficher(donnees, titre)` 205, `masquer()` 214

### html/index.html — NUI · 96 l.
- écrans / sections : `calendrier` 23, `serie` 73
- scripts : `app.js`
- styles : `style.css`

### locales/fr.lua — partagé · 36 l.
- fonctions : `_L(cle, ...)` 29

### server/main.lua — serveur · 593 l.
- framework : ox_lib, Bridge
- écoute (events) : `playerDropped` 588
- émet → client : `ox_lib:notify` 23
- callbacks déclarés : `ash_vipdaily:server:ouvrir` 470, `ash_vipdaily:server:rappel` 482, `ash_vipdaily:server:action` 491
- fonctions : `debug(...)` 14, `avertir(message)` 18, `notifier(source, message, typeNotif)` 22, `estStaff(source)` 30, `autorise(source)` 35, `pasTropRapide(source, historique, delai, prevenir)` 45, `logDiscord(titre, description, couleur)` 56, `verifierConfig()` 76, `cleCompte(source)` 114, `idDiscord(source)` 121, `roleDiscordVip(source)` 127, `terminer(vip, erreur)` 140, `vipParRessource(source, forcer)` 175, `estVip(source, forcer)` 201, `jour(decalageJours)` 240, `secondesAvantReinit()` 245, `indexRecompense(serie)` 251, `listeRecompenses()` 258, `personnagesDuCompte(source, personnageActuel)` 296, `ajouter(id)` 298, `ligneJoueur(source, cle, personnageActuel)` 337, `serieSuivante(ligne)` 372, `etat(source, joueur, cle, connu)` 379, `donnerRecompense(source, recompense)` 413, `presDuPnj(source)` 459, `finir(resultat)` 511
- tables SQL : `users` 317, `players` 321, `ash_vipdaily_joueurs` 357, `ash_vipdaily_joueurs` 361, `ash_vipdaily_joueurs` 546, `ash_vipdaily_joueurs` 560
- threads : 1 (l. 280)
