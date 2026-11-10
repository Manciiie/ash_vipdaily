# CODEMAP — vip_gh

> Généré par `codemap.py` v2 : **ne pas modifier à la main**. Régénérer après chaque modification du code.
> Format : `nom` suivi du numéro de ligne → lire seulement les lignes utiles (Read avec offset).

**10 fichiers · 2202 lignes** · 8 lua · 1 sql · 1 html

## Ressources FiveM

- **vip_gh** (fx cerulean, v 2.0.0, lua54 yes)
  - partagé : `@ox_lib/init.lua`, `config.lua`, `locales/fr.lua`, `bridge/shared.lua`
  - client : `bridge/client.lua`, `client/main.lua`
  - serveur : `@oxmysql/lib/MySQL.lua`, `bridge/server.lua`, `server/main.lua`
  - ui_page : `html/index.html`
  - dépendances : `ox_lib`, `oxmysql`

## Liens entre fichiers

- `ash_vipdaily:client:notifier` : émis `server/main.lua:24` → écouté `client/main.lua:37`
- callback `ash_vipdaily:server:action` : déclaré `server/main.lua:931` ← appelé `client/main.lua:70`
- callback `ash_vipdaily:server:ouvrir` : déclaré `server/main.lua:904` ← appelé `client/main.lua:46`
- callback `ash_vipdaily:server:rappel` : déclaré `server/main.lua:920` ← appelé `client/main.lua:205`
- NUI `action` : JS `html/index.html:382`, `html/index.html:394` → Lua `client/main.lua:68`
- NUI `fermer` : JS `html/index.html:409`, `html/index.html:432` → Lua `client/main.lua:63`
- NUI action `fermer` : Lua `client/main.lua:58` → JS `html/index.html:424`
- NUI action `ouvrir` : Lua `client/main.lua:51` → JS `html/index.html:414`

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

### client/main.lua — client · 209 l.
- framework : ox_lib, Bridge
- écoute (events) : `ash_vipdaily:client:notifier` 37, `onResourceStop` 192
- callbacks appelés : `ash_vipdaily:server:ouvrir` 46, `ash_vipdaily:server:action` 70, `ash_vipdaily:server:rappel` 205
- NUI : callbacks reçus : `fermer` 63, `action` 68
- NUI : messages envoyés : `ouvrir` 51, `fermer` 58
- exports fournis : `GuiderVersPnj` 184
- exports utilisés : `ox_target:removeLocalEntity` 93, `ox_target:addLocalEntity` 120
- fonctions : `notifier(message, typeNotif, duree)` 14, `ouvrir()` 42, `fermer()` 54, `supprimerPed()` 90, `creerPed()` 100, `cacherTexte()` 131, `nearby()` 164, `onExit()` 175

### html/index.html — NUI · 437 l.
- NUI : callbacks envoyés au Lua : `action` 382, `action` 394, `fermer` 409, `fermer` 432
- NUI : actions reçues : `ouvrir` 414, `fermer` 424
- fonctions : `argent(n)` 138, `virgule(x)` 139, `envoyer(nom, donnees = {})` 146, `texte(id, valeur)` 154, `el(balise, classe, contenu)` 159, `puces(conteneur, items)` 166, `nbJours()` 176, `lot(jour)` 177, `entete()` 180, `coffre()` 189, `demain()` 237, `chaine()` 248, `rangs()` 280, `cycle()` 299, `defis()` 310, `classement()` 338, `rangee(pos, nom, serie, moi)` 354, `rendre()` 362, `attendre(ms)` 375
- écrans / sections : `col-coffre` 35
- styles : `style.css`
- script intégré : `<script>` 130

### locales/fr.lua — partagé · 42 l.
- fonctions : `_L(cle, ...)` 35

### server/main.lua — serveur · 994 l.
- framework : ox_lib, Bridge
- écoute (events) : `playerJoining` 518, `playerDropped` 987
- émet → client : `ash_vipdaily:client:notifier` 24
- callbacks déclarés : `ash_vipdaily:server:ouvrir` 904, `ash_vipdaily:server:rappel` 920, `ash_vipdaily:server:action` 931
- fonctions : `debug(...)` 14, `avertir(message)` 18, `notifier(source, message, typeNotif)` 23, `estStaff(source)` 27, `autorise(source)` 32, `pasTropRapide(source, historique, delai, prevenir)` 42, `logDiscord(titre, description, couleur)` 53, `verifierConfig()` 73, `cleCompte(source)` 128, `idDiscord(source)` 135, `roleDiscordVip(source)` 141, `terminer(vip, erreur)` 154, `vipParRessource(source, forcer)` 189, `estVip(source, forcer)` 215, `jour(decalageJours)` 255, `semaineCourante()` 260, `secondesAvantReinit()` 267, `indexRecompense(serie)` 273, `itemsAffichables(items)` 279, `listeRecompenses()` 288, `rangPour(serie)` 306, `tirerBonus()` 316, `bonusMax()` 328, `montantCoffre(base, multRang, bonus)` 335, `attendreBase()` 396, `ligneVide()` 411, `personnagesDuCompte(source, personnageActuel)` 421, `ajouter(id)` 423, `ligneBrute(source, cle, personnageActuel)` 462, `ligneJoueur(source, cle, personnageActuel)` 495, `tempsSession(source)` 527, `enregistrerTemps(source)` 534, `serieActive(ligne)` 562, `serieSuivante(ligne)` 570, `progressionDefi(defi, ligne, source)` 576, `validerDefis(source, cle, ligne)` 585, `classement(source, ligne)` 618, `nomClassement(joueur)` 643, `etat(source, joueur, cle, connu)` 651, `donnerRecompense(source, recompense, raison)` 731, `presDuPnj(source)` 777, `ouvrirCoffreDuJour(source, joueur, cle)` 789, `ouvrirCoffreLegendaire(source, joueur, cle)` 870, `finir(resultat)` 952
- tables SQL : `information_schema` 378, `users` 442, `players` 446, `ash_vipdaily_joueurs` 480, `ash_vipdaily_joueurs` 484, `ash_vipdaily_joueurs` 635, `ash_vipdaily_joueurs` 811, `ash_vipdaily_joueurs` 874, `ash_vipdaily_joueurs` 883
- threads : 3 (l. 356, 522, 552)
