# CODEMAP — vip_gh

> Généré par `codemap.py` v2 : **ne pas modifier à la main**. Régénérer après chaque modification du code.
> Format : `nom` suivi du numéro de ligne → lire seulement les lignes utiles (Read avec offset).

**10 fichiers · 2287 lignes** · 8 lua · 1 sql · 1 html

## Ressources FiveM

- **vip_gh** (fx cerulean, v 2.0.4, lua54 yes)
  - partagé : `@ox_lib/init.lua`, `config.lua`, `locales/fr.lua`, `bridge/shared.lua`
  - client : `bridge/client.lua`, `client/main.lua`
  - serveur : `@oxmysql/lib/MySQL.lua`, `bridge/server.lua`, `server/main.lua`
  - ui_page : `html/index.html`
  - dépendances : `ox_lib`, `oxmysql`

## ⚠ Points d'attention

- Callback `ash_vipdaily:server:ouvrir` déclaré `server/main.lua:951` mais jamais appelé ici (code mort ou utilisé ailleurs)
- Callback `ash_vipdaily:server:resume` déclaré `server/main.lua:978` mais jamais appelé ici (code mort ou utilisé ailleurs)

## Liens entre fichiers

- `ash_vipdaily:client:notifier` : émis `server/main.lua:25` → écouté `client/main.lua:37`
- callback `ash_vipdaily:server:action` : déclaré `server/main.lua:998` ← appelé `client/main.lua:78`
- callback `ash_vipdaily:server:rappel` : déclaré `server/main.lua:967` ← appelé `client/main.lua:213`
- NUI `action` : JS `html/index.html:389`, `html/index.html:401` → Lua `client/main.lua:76`
- NUI `fermer` : JS `html/index.html:416`, `html/index.html:439` → Lua `client/main.lua:71`
- NUI action `fermer` : Lua `client/main.lua:66` → JS `html/index.html:431`
- NUI action `ouvrir` : Lua `client/main.lua:59` → JS `html/index.html:421`

## Fichiers

### config.lua — config · 213 l.
- clés de config : `Config.Langue` 4, `Config.Debug` 7, `Config.Framework` 10, `Config.Notifications` 16, `Config.Commande` 26, `Config.Touche` 27, `Config.Pnj` 32, `Config.StaffSeulement` 50, `Config.AcePermission` 51, `Config.DelaiActions` 54, `Config.DelaiOuverture` 55, `Config.Vip` 62, `Config.HeureReinitialisation` 93, `Config.SerieStricte` 97, `Config.Recompenses` 107, `Config.MontantMax` 143, `Config.Bonus` 149, `Config.Rangs` 160, `Config.Boucliers` 172, `Config.Defis` 182, `Config.CoffreLegendaire` 191, `Config.Classement` 203, `Config.RappelConnexion` 210

### fxmanifest.lua — manifeste · 40 l.
- (aucun symbole)

### install.sql — 19 l.
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

### client/main.lua — client · 217 l.
- framework : ox_lib, Bridge
- écoute (events) : `ash_vipdaily:client:notifier` 37, `onResourceStop` 200
- callbacks appelés : `ash_vipdaily:server:action` 78, `ash_vipdaily:server:rappel` 213
- NUI : callbacks reçus : `fermer` 71, `action` 76
- NUI : messages envoyés : `ouvrir` 59, `fermer` 66
- exports fournis : `GuiderVersPnj` 192
- exports utilisés : `ox_target:removeLocalEntity` 101, `ox_target:addLocalEntity` 128
- fonctions : `notifier(message, typeNotif, duree)` 14, `ouvrir()` 44, `fermer()` 62, `supprimerPed()` 98, `creerPed()` 108, `cacherTexte()` 139, `nearby()` 172, `onExit()` 183

### html/index.html — NUI · 444 l.
- NUI : callbacks envoyés au Lua : `action` 389, `action` 401, `fermer` 416, `fermer` 439
- NUI : actions reçues : `ouvrir` 421, `fermer` 431
- fonctions : `argent(n)` 138, `virgule(x)` 141, `envoyer(nom, donnees = {})` 148, `texte(id, valeur)` 156, `el(balise, classe, contenu)` 161, `puces(conteneur, items)` 168, `nbJours()` 178, `lot(jour)` 179, `entete()` 182, `coffre()` 191, `demain()` 241, `chaine()` 254, `rangs()` 287, `cycle()` 306, `defis()` 317, `classement()` 345, `rangee(pos, nom, serie, moi)` 361, `rendre()` 369, `attendre(ms)` 382
- écrans / sections : `col-coffre` 35
- styles : `style.css`
- script intégré : `<script>` 130

### locales/fr.lua — partagé · 42 l.
- fonctions : `_L(cle, ...)` 35

### server/main.lua — serveur · 1064 l.
- framework : ox_lib, Bridge
- écoute (events) : `playerJoining` 536, `playerDropped` 1054
- émet → client : `ash_vipdaily:client:notifier` 25
- callbacks déclarés : `ash_vipdaily:server:ouvrir` 951, `ash_vipdaily:server:rappel` 967, `ash_vipdaily:server:resume` 978, `ash_vipdaily:server:action` 998
- fonctions : `debug(...)` 15, `avertir(message)` 19, `notifier(source, message, typeNotif)` 24, `estStaff(source)` 28, `autorise(source)` 33, `pasTropRapide(source, historique, delai, prevenir)` 43, `logDiscord(titre, description, couleur)` 54, `verifierConfig()` 74, `cleCompte(source)` 129, `idDiscord(source)` 136, `roleDiscordVip(source)` 142, `terminer(vip, erreur)` 155, `vipParRessource(source, forcer)` 190, `estVip(source, forcer)` 216, `jour(decalageJours)` 256, `semaineCourante()` 261, `secondesAvantReinit()` 268, `indexRecompense(serie)` 274, `itemsAffichables(items)` 280, `listeRecompenses()` 289, `rangPour(serie)` 307, `tirerBonus()` 317, `bonusMax()` 329, `montantCoffre(base, multRang, bonus)` 336, `attendreBase()` 411, `ligneVide()` 426, `personnagesDuCompte(source, personnageActuel)` 436, `ajouter(id)` 438, `ligneBrute(source, cle, personnageActuel)` 477, `ligneJoueur(source, cle, personnageActuel)` 512, `tempsSession(source)` 545, `enregistrerTemps(source)` 553, `serieActive(ligne)` 582, `serieSuivante(ligne)` 590, `progressionDefi(defi, ligne, source)` 596, `validerDefis(source, cle, ligne)` 605, `classement(source, ligne, garderPosition)` 640, `nomClassement(joueur)` 674, `etat(source, joueur, cle, connu)` 682, `donnerRecompense(source, recompense, raison)` 764, `presDuPnj(source)` 810, `ouvrirCoffreDuJour(source, joueur, cle)` 822, `ouvrirCoffreLegendaire(source, joueur, cle)` 917, `finir(resultat)` 1019
- tables SQL : `information_schema` 380, `ash_vipdaily_joueurs` 392, `information_schema` 401, `users` 457, `players` 461, `ash_vipdaily_joueurs` 495, `ash_vipdaily_joueurs` 499, `ash_vipdaily_joueurs` 664, `ash_vipdaily_joueurs` 844, `ash_vipdaily_joueurs` 921, `ash_vipdaily_joueurs` 930
- threads : 3 (l. 358, 540, 572)
