# CODEMAP — vip_gh

> Généré par `codemap.py` v2 : **ne pas modifier à la main**. Régénérer après chaque modification du code.
> Format : `nom` suivi du numéro de ligne → lire seulement les lignes utiles (Read avec offset).

**11 fichiers · 1442 lignes** · 8 lua · 1 sql · 1 js · 1 html

## Ressources FiveM

- **vip_gh** (fx cerulean, v 1.3.4, lua54 yes)
  - partagé : `@ox_lib/init.lua`, `config.lua`, `locales/fr.lua`, `bridge/shared.lua`
  - client : `bridge/client.lua`, `client/main.lua`
  - serveur : `@oxmysql/lib/MySQL.lua`, `bridge/server.lua`, `server/main.lua`
  - ui_page : `html/index.html`
  - dépendances : `ox_lib`, `oxmysql`

## Liens entre fichiers

- callback `ash_vipdaily:server:action` : déclaré `server/main.lua:478` ← appelé `client/main.lua:36`
- callback `ash_vipdaily:server:ouvrir` : déclaré `server/main.lua:457` ← appelé `client/main.lua:12`
- callback `ash_vipdaily:server:rappel` : déclaré `server/main.lua:469` ← appelé `client/main.lua:60`
- NUI `action` : JS `html/app.js:248` → Lua `client/main.lua:34`
- NUI `fermer` : JS `html/app.js:231` → Lua `client/main.lua:29`
- NUI action `fermer` : Lua `client/main.lua:24` → JS `html/app.js:226`
- NUI action `ouvrir` : Lua `client/main.lua:17` → JS `html/app.js:225`

## Fichiers

### config.lua — config · 115 l.
- clés de config : `Config.Langue` 4, `Config.Debug` 7, `Config.Framework` 10, `Config.Commande` 13, `Config.Touche` 14, `Config.StaffSeulement` 17, `Config.AcePermission` 18, `Config.DelaiActions` 21, `Config.DelaiOuverture` 22, `Config.Vip` 29, `Config.HeureReinitialisation` 60, `Config.SerieStricte` 64, `Config.Recompenses` 74, `Config.MontantMax` 109, `Config.RappelConnexion` 112

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

### client/main.lua — client · 64 l.
- framework : ox_lib, Bridge
- écoute (events) : `onResourceStop` 41
- callbacks appelés : `ash_vipdaily:server:ouvrir` 12, `ash_vipdaily:server:action` 36, `ash_vipdaily:server:rappel` 60
- NUI : callbacks reçus : `fermer` 29, `action` 34
- NUI : messages envoyés : `ouvrir` 17, `fermer` 24
- fonctions : `ouvrir()` 8, `fermer()` 20

### html/app.js — NUI · 259 l.
- NUI : callbacks envoyés au Lua : `fermer` 231, `action` 248
- NUI : actions reçues : `ouvrir` 225, `fermer` 226
- fonctions : `envoyer(nom, donnees = {})` 17, `texte(id, valeur)` 28, `el(balise, classe, contenu)` 33, `duree(total)` 40, `montant(lot)` 47, `jourEnCours()` 52, `nbJours()` 53, `demarrerMinuteur()` 56, `majTemps()` 65, `construireGrille()` 73, `construireHero()` 104, `construireSerie()` 182, `rendre()` 189, `appliquer(nouvelEtat)` 196, `afficher(donnees, titre)` 205, `masquer()` 214

### html/index.html — NUI · 96 l.
- écrans / sections : `calendrier` 23, `serie` 73
- scripts : `app.js`
- styles : `style.css`

### locales/fr.lua — partagé · 33 l.
- fonctions : `_L(cle, ...)` 26

### server/main.lua — serveur · 576 l.
- framework : ox_lib, Bridge
- écoute (events) : `playerDropped` 571
- émet → client : `ox_lib:notify` 23
- callbacks déclarés : `ash_vipdaily:server:ouvrir` 457, `ash_vipdaily:server:rappel` 469, `ash_vipdaily:server:action` 478
- fonctions : `debug(...)` 14, `avertir(message)` 18, `notifier(source, message, typeNotif)` 22, `estStaff(source)` 30, `autorise(source)` 35, `pasTropRapide(source, historique, delai, prevenir)` 45, `logDiscord(titre, description, couleur)` 56, `verifierConfig()` 76, `cleCompte(source)` 114, `idDiscord(source)` 121, `roleDiscordVip(source)` 127, `terminer(vip, erreur)` 140, `vipParRessource(source, forcer)` 175, `estVip(source, forcer)` 201, `jour(decalageJours)` 240, `secondesAvantReinit()` 245, `indexRecompense(serie)` 251, `listeRecompenses()` 258, `personnagesDuCompte(source, personnageActuel)` 296, `ajouter(id)` 298, `ligneJoueur(source, cle, personnageActuel)` 337, `serieSuivante(ligne)` 372, `etat(source, joueur, cle, connu)` 379, `donnerRecompense(source, recompense)` 413, `finir(resultat)` 494
- tables SQL : `users` 317, `players` 321, `ash_vipdaily_joueurs` 357, `ash_vipdaily_joueurs` 361, `ash_vipdaily_joueurs` 529, `ash_vipdaily_joueurs` 543
- threads : 1 (l. 280)
