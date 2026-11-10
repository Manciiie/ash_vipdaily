-- ash_vipdaily — serveur
-- Règle d'or : ne jamais faire confiance au client. Tout est vérifié ici :
-- statut VIP, jour, série, contenu de la récompense et montants.

-- Le joueur, l'argent et les items passent par Bridge (bridge/server.lua) : QBCore, Qbox et ESX.
local dernierAppel = {}
local derniereOuverture = {}
local verrou = {}        -- empêche deux récupérations simultanées pour un même joueur
local cacheVip = {}      -- [source] = { vip = bool, expire = os.time() }

local TOKEN_BOT = GetConvar('ash_vipdaily_bot_token', '')
local WEBHOOK = GetConvar('ash_vipdaily_webhook', '')

local function debug(...)
    if Config.Debug then print('[ash_vipdaily]', ...) end
end

local function avertir(message)
    print(('^3[ash_vipdaily] %s^0'):format(message))
end

--- Le client affiche avec ash_notify (ou ox_lib en secours) : voir Config.Notifications
local function notifier(source, message, typeNotif)
    TriggerClientEvent('ash_vipdaily:client:notifier', source, message, typeNotif or 'inform')
end

local function estStaff(source)
    return IsPlayerAceAllowed(source, Config.AcePermission)
end

--- Vérifie les permissions (et prévient le joueur si refus)
local function autorise(source)
    if Config.StaffSeulement and not estStaff(source) then
        notifier(source, _L('pas_permission'), 'error')
        debug(('refus permission pour %s'):format(source))
        return false
    end
    return true
end

--- Anti-spam : une action par joueur toutes les `delai` ms
local function pasTropRapide(source, historique, delai, prevenir)
    local maintenant = GetGameTimer()
    local precedent = historique[source]
    if precedent and maintenant - precedent < delai then
        if prevenir then notifier(source, _L('trop_rapide'), 'warning') end
        return false
    end
    historique[source] = maintenant
    return true
end

local function logDiscord(titre, description, couleur)
    if WEBHOOK == '' then return end
    PerformHttpRequest(WEBHOOK, function(code)
        if code < 200 or code >= 300 then
            avertir(('webhook Discord : envoi du log refusé (HTTP %s), vérifiez la convar ash_vipdaily_webhook'):format(code))
        end
    end, 'POST', json.encode({
        username = 'ASH City — VIP',
        embeds = { {
            title = titre,
            description = description,
            color = couleur or 10185983,
            footer = { text = 'ash_vipdaily' },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
    }), { ['Content-Type'] = 'application/json' })
end

-- Vérification de la config (une fois au démarrage) ---------------------------------

local function verifierConfig()
    local recompenses = Config.Recompenses
    if type(recompenses) ~= 'table' or #recompenses == 0 then
        print('^1[ash_vipdaily] Config.Recompenses est vide : aucune récompense ne peut être donnée.^0')
        return false
    end
    for i, r in ipairs(recompenses) do
        if r.argent then
            local montant = tonumber(r.argent.montant)
            if not montant or montant <= 0 then
                avertir(('jour %d : montant invalide (%s)'):format(i, tostring(r.argent.montant)))
            elseif montant > Config.MontantMax then
                avertir(('jour %d : %d $ dépasse Config.MontantMax (%d $), l\'argent ne sera pas versé'):format(i, montant, Config.MontantMax))
            end
            if r.argent.compte ~= 'cash' and r.argent.compte ~= 'bank' then
                avertir(('jour %d : compte « %s » inconnu, « bank » sera utilisé'):format(i, tostring(r.argent.compte)))
            end
        end
        for _, item in ipairs(r.items or {}) do
            if type(item.nom) ~= 'string' or item.nom == '' then
                avertir(('jour %d : item sans nom, il sera ignoré'):format(i))
            elseif (tonumber(item.quantite) or 0) < 1 then
                avertir(('jour %d : quantité invalide pour %s, item ignoré'):format(i, item.nom))
            end
        end
        if not r.argent and not r.items then
            avertir(('jour %d : ni argent ni item'):format(i))
        end
    end

    local precedent = 0
    for i, rang in ipairs(Config.Rangs or {}) do
        if (tonumber(rang.min) or 0) <= precedent or (tonumber(rang.mult) or 0) <= 0 then
            avertir(('Config.Rangs[%d] (%s) : min doit augmenter d\'un rang à l\'autre et mult être positif'):format(i, tostring(rang.nom)))
        end
        precedent = tonumber(rang.min) or precedent
    end
    for i, b in ipairs(Config.Bonus or {}) do
        if (tonumber(b.mult) or 0) <= 0 or (tonumber(b.chance) or -1) < 0 then
            avertir(('Config.Bonus[%d] : mult et chance doivent être positifs'):format(i))
        end
    end
    local legendaire = Config.CoffreLegendaire
    if legendaire and legendaire.argent and (tonumber(legendaire.argent.montant) or 0) > Config.MontantMax then
        avertir('Config.CoffreLegendaire : montant au-dessus de Config.MontantMax, l\'argent ne sera pas versé')
    end
    return true
end

local configValide = verifierConfig()

-- Identifiant du compte -------------------------------------------------------------
-- Le VIP vaut pour tout le compte : la récompense est liée à la licence Rockstar,
-- jamais au personnage (sinon un VIP à plusieurs personnages la toucherait plusieurs fois).

local function cleCompte(source)
    return GetPlayerIdentifierByType(source, 'license') or GetPlayerIdentifierByType(source, 'license2')
end

-- Statut VIP ----------------------------------------------------------------------
-- Chaque méthode renvoie vip (true / false) et, si la vérification a échoué, un message d'erreur.

local function idDiscord(source)
    local id = GetPlayerIdentifierByType(source, 'discord')
    return id and id:gsub('^discord:', '') or nil
end

--- Interroge l'API Discord : le membre a-t-il un des rôles VIP ?
local function roleDiscordVip(source)
    local conf = Config.Vip.Discord
    if not conf or not conf.Actif then return false end
    if TOKEN_BOT == '' then
        debug('convar ash_vipdaily_bot_token absente : détection Discord ignorée')
        return false
    end

    local discord = idDiscord(source)
    if not discord or not discord:match('^%d+$') then return false end

    local p = promise.new()
    local fini = false
    local function terminer(vip, erreur)
        if fini then return end
        fini = true
        p:resolve({ vip, erreur })
    end

    -- Sans réponse de Discord, on n'attend pas indéfiniment (le verrou du joueur resterait pris)
    SetTimeout(10000, function() terminer(false, 'Discord ne répond pas') end)

    PerformHttpRequest(
        ('https://discord.com/api/v10/guilds/%s/members/%s'):format(conf.ServeurId, discord),
        function(code, corps)
            if code == 404 then return terminer(false) end -- pas membre du serveur Discord
            if code ~= 200 or not corps then
                return terminer(false, code == 429 and 'limite de requêtes Discord atteinte (429)' or ('HTTP %s'):format(code))
            end
            local ok, membre = pcall(json.decode, corps)
            if not ok or type(membre) ~= 'table' then return terminer(false, 'réponse Discord illisible') end
            for _, role in ipairs(membre.roles or {}) do
                for _, vip in ipairs(conf.Roles) do
                    if role == vip then return terminer(true) end
                end
            end
            terminer(false)
        end,
        'GET', '', { Authorization = 'Bot ' .. TOKEN_BOT }
    )
    local resultat = Citizen.Await(p)
    return resultat[1], resultat[2]
end

--- ASH City : statut VIP fourni par ash_newplayers (rôle Discord lu et mis en cache par lui).
--- Renvoie true / false (+ erreur), ou nil si la ressource n'est pas utilisable (on passe alors aux autres méthodes).
--- forcer = true (au moment de récupérer) : relecture immédiate du rôle Discord.
local avertiRessourceVip = false
local function vipParRessource(source, forcer)
    local ressource = Config.Vip.Ressource
    if not ressource or ressource == '' or GetResourceState(ressource) ~= 'started' then return nil end

    local ok, statut, erreur = pcall(function()
        if forcer then
            local vip = exports[ressource]:RefreshVip(source)
            if vip ~= nil then return vip end
            -- RefreshVip ne donne pas la cause d'un refus : GetVipStatus la donne
            -- (sans nouvel appel à Discord si le joueur n'est simplement pas VIP, réponse en cache)
        end
        return exports[ressource]:GetVipStatus(source)
    end)
    if not ok then
        if not avertiRessourceVip then
            avertiRessourceVip = true
            avertir(('%s : lecture du statut VIP impossible (%s), autres méthodes utilisées'):format(ressource, tostring(statut)))
        end
        return nil
    end
    if statut == nil and erreur and erreur ~= 'Discord non lié' then
        return false, erreur
    end
    return statut ~= nil
end

local function estVip(source, forcer)
    if Config.Vip.Ace and IsPlayerAceAllowed(source, Config.Vip.Ace) then
        return true
    end

    -- ash_newplayers a son propre cache : pas de double mise en cache ici
    local parRessource, erreurRessource = vipParRessource(source, forcer)
    if parRessource ~= nil then
        return parRessource, erreurRessource
    end

    local cache = cacheVip[source]
    if not forcer and cache and cache.expire > os.time() then
        return cache.vip
    end

    local vip, erreur = false, nil
    if type(Config.Vip.Personnalisee) == 'function' then
        local ok, resultat = pcall(Config.Vip.Personnalisee, source)
        if ok then
            vip = resultat == true
        else
            avertir(('Config.Vip.Personnalisee a échoué : %s'):format(tostring(resultat)))
        end
    end
    if not vip then vip, erreur = roleDiscordVip(source) end

    -- Une erreur Discord n'est pas mise en cache : on réessaiera à la prochaine ouverture
    if not erreur then
        cacheVip[source] = { vip = vip, expire = os.time() + (Config.Vip.CacheMinutes or 10) * 60 }
    end
    return vip, erreur
end


-- Jours et semaines ------------------------------------------------------------------

local DECALAGE = (Config.HeureReinitialisation or 0) * 3600

--- Jour « logique » : il change à Config.HeureReinitialisation, pas à minuit
local function jour(decalageJours)
    return os.date('%Y-%m-%d', os.time() - DECALAGE - (decalageJours or 0) * 86400)
end

--- Semaine des défis : date du lundi (logique) de la semaine en cours
local function semaineCourante()
    local t = os.time() - DECALAGE
    local depuisLundi = (os.date('*t', t).wday + 5) % 7
    return os.date('%Y-%m-%d', t - depuisLundi * 86400)
end

--- Secondes avant la prochaine récompense
local function secondesAvantReinit()
    local t = os.date('*t', os.time() - DECALAGE)
    local finJour = os.time({ year = t.year, month = t.month, day = t.day + 1, hour = 0, min = 0, sec = 0 })
    return math.max(0, finJour - (os.time() - DECALAGE))
end

local function indexRecompense(serie)
    return ((serie - 1) % #Config.Recompenses) + 1
end

--- Version affichable des récompenses (labels et montants uniquement, jamais les noms d'items)
--- Calculée une seule fois : la config ne change pas en cours de partie
local function itemsAffichables(items)
    local liste = {}
    for _, item in ipairs(items or {}) do
        liste[#liste + 1] = { label = item.label or item.nom, quantite = math.floor(item.quantite or 0) }
    end
    return liste
end

local cacheListe
local function listeRecompenses()
    if cacheListe then return cacheListe end
    cacheListe = {}
    for i, r in ipairs(Config.Recompenses) do
        cacheListe[i] = {
            argent = r.argent and {
                compte = r.argent.compte == 'cash' and 'cash' or 'bank',
                montant = math.floor(r.argent.montant or 0),
            } or nil,
            items = itemsAffichables(r.items),
            gros = r.gros == true,
        }
    end
    return cacheListe
end

-- Rangs et bonus ----------------------------------------------------------------------

local function rangPour(serie)
    local rangs = Config.Rangs or {}
    local trouve, index = rangs[1] or { nom = '—', min = 1, mult = 1 }, 1
    for i, r in ipairs(rangs) do
        if math.max(1, serie) >= r.min then trouve, index = r, i end
    end
    return trouve, index
end

--- Bonus surprise du coffre, tiré ici (jamais par le client)
local function tirerBonus()
    local total = 0
    for _, b in ipairs(Config.Bonus or {}) do total = total + b.chance end
    if total <= 0 then return 1 end
    local tirage = math.random() * total
    for _, b in ipairs(Config.Bonus) do
        if tirage < b.chance then return b.mult end
        tirage = tirage - b.chance
    end
    return 1
end

local function bonusMax()
    local max = 1
    for _, b in ipairs(Config.Bonus or {}) do max = math.max(max, b.mult) end
    return max
end

--- Argent du coffre : base × rang × bonus, arrondi à la centaine, jamais au-delà de Config.MontantMax
local function montantCoffre(base, multRang, bonus)
    return math.min(math.floor(base * multRang * bonus / 100) * 100, Config.MontantMax)
end

-- Base de données -----------------------------------------------------------------

-- Colonnes ajoutées en v2.0.0 : créées automatiquement sur une table existante (aucun SQL à importer)
local COLONNES_V2 = {
    { nom = 'nom',             sql = 'ALTER TABLE `ash_vipdaily_joueurs` ADD COLUMN `nom` VARCHAR(64) NULL' },
    { nom = 'meilleure_serie', sql = 'ALTER TABLE `ash_vipdaily_joueurs` ADD COLUMN `meilleure_serie` INT NOT NULL DEFAULT 0' },
    { nom = 'boucliers',       sql = 'ALTER TABLE `ash_vipdaily_joueurs` ADD COLUMN `boucliers` INT NOT NULL DEFAULT 0' },
    { nom = 'cles',            sql = 'ALTER TABLE `ash_vipdaily_joueurs` ADD COLUMN `cles` INT NOT NULL DEFAULT 0' },
    { nom = 'semaine',         sql = 'ALTER TABLE `ash_vipdaily_joueurs` ADD COLUMN `semaine` VARCHAR(10) NULL' },
    { nom = 'coffres_semaine', sql = 'ALTER TABLE `ash_vipdaily_joueurs` ADD COLUMN `coffres_semaine` INT NOT NULL DEFAULT 0' },
    { nom = 'temps_semaine',   sql = 'ALTER TABLE `ash_vipdaily_joueurs` ADD COLUMN `temps_semaine` INT NOT NULL DEFAULT 0' },
    { nom = 'palier_semaine',  sql = 'ALTER TABLE `ash_vipdaily_joueurs` ADD COLUMN `palier_semaine` INT NOT NULL DEFAULT 0' },
    { nom = 'defis_semaine',   sql = 'ALTER TABLE `ash_vipdaily_joueurs` ADD COLUMN `defis_semaine` INT NOT NULL DEFAULT 0' },
}

local basePrete = false

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ash_vipdaily_joueurs` (
            `identifiant`     VARCHAR(64) NOT NULL,
            `dernier_jour`    VARCHAR(10) NULL,
            `serie`           INT NOT NULL DEFAULT 0,
            `total`           INT NOT NULL DEFAULT 0,
            `nom`             VARCHAR(64) NULL,
            `meilleure_serie` INT NOT NULL DEFAULT 0,
            `boucliers`       INT NOT NULL DEFAULT 0,
            `cles`            INT NOT NULL DEFAULT 0,
            `semaine`         VARCHAR(10) NULL,
            `coffres_semaine` INT NOT NULL DEFAULT 0,
            `temps_semaine`   INT NOT NULL DEFAULT 0,
            `palier_semaine`  INT NOT NULL DEFAULT 0,
            `defis_semaine`   INT NOT NULL DEFAULT 0,
            `maj_le`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifiant`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    local presentes = {}
    for _, c in ipairs(MySQL.query.await(
        "SELECT COLUMN_NAME AS nom FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ash_vipdaily_joueurs'") or {}) do
        presentes[c.nom] = true
    end
    for _, colonne in ipairs(COLONNES_V2) do
        if not presentes[colonne.nom] then
            local ok, err = pcall(MySQL.query.await, colonne.sql)
            if ok then
                print(('[ash_vipdaily] colonne %s ajoutée à la table'):format(colonne.nom))
            else
                print(('^1[ash_vipdaily] impossible d\'ajouter la colonne %s : %s^0'):format(colonne.nom, tostring(err)))
            end
        end
    end
    basePrete = true
end)

--- Les callbacks attendent la mise à jour de la table au démarrage (quelques secondes au plus)
local function attendreBase()
    local essais = 0
    while not basePrete and essais < 100 do
        Wait(100)
        essais = essais + 1
    end
    return basePrete
end

local REQUETE_LIGNE = [[
    SELECT dernier_jour, serie, total, nom, meilleure_serie, boucliers, cles, semaine,
           coffres_semaine, temps_semaine, palier_semaine, defis_semaine
    FROM `ash_vipdaily_joueurs` WHERE identifiant = ?
]]

local function ligneVide()
    return {
        dernier_jour = nil, serie = 0, total = 0, meilleure_serie = 0,
        boucliers = (Config.Boucliers and Config.Boucliers.Depart) or 0, cles = 0,
        semaine = nil, coffres_semaine = 0, temps_semaine = 0, palier_semaine = 0, defis_semaine = 0,
        nouvelle = true,
    }
end

--- Identifiants de tous les personnages du compte (lignes enregistrées avant la v1.3.1)
local function personnagesDuCompte(source, personnageActuel)
    local liste, vus = {}, {}
    local function ajouter(id)
        if id and id ~= '' and not vus[id] then
            vus[id] = true
            liste[#liste + 1] = id
        end
    end
    ajouter(personnageActuel)

    -- Les deux licences (license et license2) : une seule si le joueur n'en a qu'une
    local licence1 = GetPlayerIdentifierByType(source, 'license')
    local licence2 = GetPlayerIdentifierByType(source, 'license2') or licence1
    licence1 = licence1 or licence2
    if not licence1 then return liste end

    local ok, lignes = pcall(function()
        if Bridge.Framework == 'esx' then
            -- ESX : identifier = empreinte de la licence, ou charN:empreinte en multipersonnage
            local empreinte1 = licence1:gsub('^license%d?:', '')
            local empreinte2 = licence2:gsub('^license%d?:', '')
            return MySQL.query.await(
                'SELECT identifier AS id FROM `users` WHERE identifier = ? OR identifier LIKE ? OR identifier = ? OR identifier LIKE ?',
                { empreinte1, '%:' .. empreinte1, empreinte2, '%:' .. empreinte2 })
        end
        return MySQL.query.await('SELECT citizenid AS id FROM `players` WHERE license = ? OR license = ?', { licence1, licence2 })
    end)
    if not ok then
        avertir(('reprise des anciennes séries : personnages introuvables (%s), seul le personnage connecté est repris'):format(tostring(lignes)))
        return liste
    end
    for _, l in ipairs(lignes or {}) do ajouter(l.id) end
    return liste
end

--- Ligne du compte. Avant la v1.3.1 les lignes étaient enregistrées par personnage :
--- la première fois, les lignes de tous les personnages du compte sont fusionnées
--- (dernière récupération et série du plus récent, totaux additionnés), ce qui empêche
--- de récupérer une deuxième fois le jour de la mise à jour avec un autre personnage.
local fusionFaite = {}   -- [licence] = true : fusion déjà tentée depuis le démarrage, pas de nouvelle recherche

local function ligneBrute(source, cle, personnageActuel)
    local ligne = MySQL.single.await(REQUETE_LIGNE, { cle })
    if ligne or fusionFaite[cle] then return ligne end

    local anciens = personnagesDuCompte(source, personnageActuel)
    if #anciens > 0 then
        -- Une requête par personnage (quelques-uns au plus, une seule fois par compte)
        local lignes = {}
        for _, id in ipairs(anciens) do
            local l = MySQL.single.await(REQUETE_LIGNE, { id })
            if l then lignes[#lignes + 1] = l end
        end
        if #lignes > 0 then
            local recente, total = nil, 0
            for _, l in ipairs(lignes) do
                total = total + (l.total or 0)
                if not recente or (l.dernier_jour or '') > (recente.dernier_jour or '') then recente = l end
            end
            MySQL.insert.await(
                'INSERT IGNORE INTO `ash_vipdaily_joueurs` (identifiant, dernier_jour, serie, total, meilleure_serie, boucliers) VALUES (?, ?, ?, ?, ?, ?)',
                { cle, recente.dernier_jour, recente.serie or 0, total, recente.serie or 0, (Config.Boucliers and Config.Boucliers.Depart) or 0 })
            for _, id in ipairs(anciens) do
                MySQL.update.await('DELETE FROM `ash_vipdaily_joueurs` WHERE identifiant = ?', { id })
            end
            debug(('%d ligne(s) de personnage fusionnée(s) pour le compte %s'):format(#lignes, cle))
            ligne = MySQL.single.await(REQUETE_LIGNE, { cle })
        end
    end
    fusionFaite[cle] = true
    return ligne
end

--- Ligne du compte, compteurs de la semaine remis à zéro si une nouvelle semaine a commencé
local function ligneJoueur(source, cle, personnageActuel)
    local ligne = ligneBrute(source, cle, personnageActuel)
    if not ligne then
        local vide = ligneVide()
        vide.semaine = semaineCourante()
        return vide
    end
    local semaine = semaineCourante()
    if ligne.semaine ~= semaine then
        MySQL.update.await([[
            UPDATE `ash_vipdaily_joueurs`
            SET coffres_semaine = 0, temps_semaine = 0, palier_semaine = 0, defis_semaine = 0, semaine = ?
            WHERE identifiant = ? AND (semaine IS NULL OR semaine <> ?)
        ]], { semaine, cle, semaine })
        ligne.semaine, ligne.coffres_semaine, ligne.temps_semaine, ligne.palier_semaine, ligne.defis_semaine = semaine, 0, 0, 0, 0
    end
    return ligne
end

-- Temps de jeu (défi « Jouer 3 h ») ------------------------------------------------------

local debutSession = {}   -- [source] = os.time() du début de la partie non encore enregistrée

AddEventHandler('playerJoining', function()
    debutSession[source] = os.time()
end)

CreateThread(function()
    -- Redémarrage de la ressource : les joueurs déjà connectés repartent de maintenant
    for _, id in ipairs(GetPlayers()) do debutSession[tonumber(id)] = os.time() end
end)

local function tempsSession(source)
    local debut = debutSession[source]
    return debut and math.max(0, os.time() - debut) or 0
end

--- Ajoute le temps de jeu non enregistré à la semaine du compte (seuls les comptes déjà connus sont suivis).
--- Une seule requête, sans lecture : les compteurs d'une semaine passée sont remis à zéro dans le même UPDATE.
local function enregistrerTemps(source)
    local ecoule = tempsSession(source)
    local cle = cleCompte(source)
    if ecoule <= 0 or not cle or not basePrete then return end
    debutSession[source] = os.time()
    local semaine = semaineCourante()
    MySQL.update([[
        UPDATE `ash_vipdaily_joueurs` SET
            temps_semaine   = IF(semaine = ?, temps_semaine + ?, ?),
            coffres_semaine = IF(semaine = ?, coffres_semaine, 0),
            palier_semaine  = IF(semaine = ?, palier_semaine, 0),
            defis_semaine   = IF(semaine = ?, defis_semaine, 0),
            semaine = ?
        WHERE identifiant = ?
    ]], { semaine, ecoule, ecoule, semaine, semaine, semaine, semaine, cle })
end

-- Enregistrement régulier (une requête par joueur toutes les 10 minutes, rien entre deux)
CreateThread(function()
    while true do
        Wait(10 * 60 * 1000)
        for _, id in ipairs(GetPlayers()) do enregistrerTemps(tonumber(id)) end
    end
end)

-- Série, défis, classement ---------------------------------------------------------------

--- Série en cours affichée (0 si elle est cassée)
local function serieActive(ligne)
    local d = ligne.dernier_jour
    if not Config.SerieStricte or d == jour(0) or d == jour(1) then return ligne.serie or 0 end
    if d == jour(2) and (ligne.boucliers or 0) > 0 then return ligne.serie or 0 end
    return 0
end

--- Série qu'aura le joueur s'il récupère aujourd'hui, et si un bouclier est utilisé pour la garder
local function serieSuivante(ligne)
    if not Config.SerieStricte or ligne.dernier_jour == jour(1) then return (ligne.serie or 0) + 1, false end
    if ligne.dernier_jour == jour(2) and (ligne.boucliers or 0) > 0 then return (ligne.serie or 0) + 1, true end
    return 1, false
end

local function progressionDefi(defi, ligne, source)
    if defi.id == 'coffres' then return ligne.coffres_semaine or 0 end
    if defi.id == 'temps' then return (ligne.temps_semaine or 0) + tempsSession(source) end
    if defi.id == 'palier' then return ligne.palier_semaine or 0 end
    return 0
end

--- Valide les défis terminés (une fois par semaine) et donne leurs clés / boucliers.
--- Renvoie les labels des défis tout juste réussis.
local function validerDefis(source, cle, ligne)
    if ligne.nouvelle then return {} end
    local masque, cles, boucliers, gagnes = ligne.defis_semaine or 0, 0, 0, {}
    for i, defi in ipairs(Config.Defis or {}) do
        local bit = 1 << (i - 1)
        if masque & bit == 0 and progressionDefi(defi, ligne, source) >= defi.objectif then
            masque = masque | bit
            cles = cles + (defi.cles or 0)
            boucliers = boucliers + (defi.boucliers or 0)
            gagnes[#gagnes + 1] = defi.label
        end
    end
    if #gagnes == 0 then return gagnes end

    local max = (Config.Boucliers and Config.Boucliers.Max) or 0
    -- Condition sur l'ancien masque : deux appels simultanés ne donnent pas deux fois le gain
    local modifie = MySQL.update.await([[
        UPDATE `ash_vipdaily_joueurs` SET defis_semaine = ?, cles = cles + ?, boucliers = LEAST(boucliers + ?, ?)
        WHERE identifiant = ? AND semaine = ? AND defis_semaine = ?
    ]], { masque, cles, boucliers, max, cle, ligne.semaine, ligne.defis_semaine or 0 })
    if modifie ~= 1 then return {} end

    ligne.defis_semaine = masque
    ligne.cles = (ligne.cles or 0) + cles
    ligne.boucliers = math.min((ligne.boucliers or 0) + boucliers, max)
    for _, label in ipairs(gagnes) do
        notifier(source, _L('defi_reussi', label), 'success')
    end
    return gagnes
end

local cacheClassement = { expire = 0, liste = {} }

local function classement(source, ligne)
    local conf = Config.Classement
    if not conf or not conf.Actif then return nil end
    if os.time() >= cacheClassement.expire then
        local lignes = MySQL.query.await([[
            SELECT nom, serie FROM `ash_vipdaily_joueurs`
            WHERE dernier_jour >= ? AND nom IS NOT NULL AND serie > 0
            ORDER BY serie DESC LIMIT ?
        ]], { jour(1), math.floor(conf.Taille or 5) }) or {}
        local liste = {}
        for i, l in ipairs(lignes) do liste[i] = { nom = l.nom, serie = l.serie } end
        cacheClassement = { expire = os.time() + (conf.CacheSecondes or 60), liste = liste }
    end

    local position
    local maSerie = serieActive(ligne)
    if maSerie > 0 and (ligne.dernier_jour or '') >= jour(1) then
        local r = MySQL.single.await(
            'SELECT COUNT(*) AS n FROM `ash_vipdaily_joueurs` WHERE dernier_jour >= ? AND serie > ?', { jour(1), maSerie })
        position = r and (r.n + 1) or nil
    end
    return { top = cacheClassement.liste, position = position, serie = maSerie }
end

--- Nom affiché dans le classement : prénom et initiale du nom
local function nomClassement(joueur)
    local initiale = (joueur.nom or ''):sub(1, 1)
    return (initiale ~= '' and ('%s %s.'):format(joueur.prenom or '', initiale) or (joueur.prenom or 'VIP')):sub(1, 64)
end

-- État envoyé à l'interface ---------------------------------------------------------------

--- connu (optionnel) : { vip } déjà vérifié par l'appelant
local function etat(source, joueur, cle, connu)
    local vip = connu and connu.vip or (estVip(source) == true)
    local ligne = ligneJoueur(source, cle, joueur.identifiant)
    if vip then validerDefis(source, cle, ligne) end

    local dejaRecupere = ligne.dernier_jour == jour(0)
    local disponible = vip and not dejaRecupere

    -- Coffre mis en avant : celui à ouvrir aujourd'hui, sinon celui de demain
    local prochaineSerie, bouclierPrevu
    if dejaRecupere then
        prochaineSerie, bouclierPrevu = (ligne.serie or 0) + 1, false
    else
        prochaineSerie, bouclierPrevu = serieSuivante(ligne)
    end
    local jourCycle = indexRecompense(prochaineSerie)
    local rang, indexRang = rangPour(prochaineSerie)
    local rangSuivant = (Config.Rangs or {})[indexRang + 1]
    local recompenses = listeRecompenses()

    -- Demain : le coffre suivant celui d'aujourd'hui
    local jourDemain = indexRecompense(dejaRecupere and (ligne.serie or 0) + 2 or prochaineSerie + 1)
    local rangDemain = rangPour(dejaRecupere and (ligne.serie or 0) + 2 or prochaineSerie + 1)
    local lotDemain = recompenses[jourDemain]

    local defis = {}
    for i, defi in ipairs(Config.Defis or {}) do
        local bit = 1 << (i - 1)
        defis[i] = {
            id = defi.id,
            label = defi.label,
            progression = math.min(progressionDefi(defi, ligne, source), defi.objectif),
            objectif = defi.objectif,
            fait = (ligne.defis_semaine or 0) & bit ~= 0,
            cles = defi.cles or 0,
            boucliers = defi.boucliers or 0,
        }
    end

    local legendaire = Config.CoffreLegendaire or {}
    local base = recompenses[jourCycle] and recompenses[jourCycle].argent and recompenses[jourCycle].argent.montant or 0

    return {
        joueur = ('%s %s'):format(joueur.prenom, joueur.nom),
        vip = vip,
        disponible = disponible,
        dejaRecupere = dejaRecupere,
        serie = serieActive(ligne),
        meilleureSerie = ligne.meilleure_serie or 0,
        total = ligne.total or 0,
        jourCycle = jourCycle,
        recompenses = recompenses,
        secondes = secondesAvantReinit(),
        base = base,
        rang = { nom = rang.nom, mult = rang.mult },
        rangs = Config.Rangs or {},
        rangSuivant = rangSuivant and { nom = rangSuivant.nom, mult = rangSuivant.mult, dans = rangSuivant.min - prochaineSerie } or nil,
        bonusMax = bonusMax(),
        bouclierPrevu = bouclierPrevu,
        boucliers = ligne.boucliers or 0,
        boucliersMax = (Config.Boucliers and Config.Boucliers.Max) or 0,
        cles = ligne.cles or 0,
        clesRequises = legendaire.Cles or 3,
        legendaire = {
            montant = legendaire.argent and math.floor(legendaire.argent.montant or 0) or 0,
            items = itemsAffichables(legendaire.items),
        },
        defis = defis,
        demain = {
            jour = jourDemain,
            gros = lotDemain and lotDemain.gros or false,
            max = lotDemain and lotDemain.argent and montantCoffre(lotDemain.argent.montant, rangDemain.mult, bonusMax()) or 0,
        },
        classement = classement(source, ligne),
    }
end

-- Distribution --------------------------------------------------------------------

--- Renvoie false + raison si rien n'a été remis (le jour est alors rendu au joueur)
local function donnerRecompense(source, recompense, raison)
    local donnes, manques = {}, {}
    local premierItem = true

    -- Items d'abord : si le premier échoue (inventaire plein), rien n'a été donné
    for _, item in ipairs(recompense.items or {}) do
        local quantite = math.floor(tonumber(item.quantite) or 0)
        local nomValide = type(item.nom) == 'string' and item.nom ~= ''
        if nomValide and quantite > 0 then
            if Bridge.AddItem(source, item.nom, quantite) then
                donnes[#donnes + 1] = ('%dx %s'):format(quantite, item.label or item.nom)
            else
                if premierItem then return false, 'inventaire' end
                manques[#manques + 1] = item.label or item.nom
            end
            premierItem = false
        end
        -- Item mal configuré : déjà signalé dans la console au démarrage
    end

    local argent = recompense.argent
    if argent then
        local montant = math.floor(tonumber(argent.montant) or 0)
        local compte = argent.compte == 'cash' and 'cash' or 'bank'
        local texteArgent = ('$%d (%s)'):format(montant, compte == 'cash' and _L('liquide') or _L('banque'))
        if montant > 0 and montant <= Config.MontantMax then
            if Bridge.AddMoney(source, compte, montant, raison or 'ash_vipdaily : récompense quotidienne') then
                donnes[#donnes + 1] = texteArgent
            else
                avertir(('versement de %s refusé par le framework pour le joueur %s'):format(texteArgent, source))
                manques[#manques + 1] = texteArgent
            end
        else
            avertir(('montant refusé (%s) : vérifiez Config.Recompenses / Config.MontantMax'):format(montant))
            manques[#manques + 1] = texteArgent
        end
    end

    if #donnes == 0 then return false, 'rien' end
    return true, donnes, manques
end

-- PNJ -------------------------------------------------------------------------------

--- La récompense ne se récupère qu'auprès du PNJ : position lue par le serveur, jamais envoyée par le client
local MARGE_PNJ = 2.0   -- tolérance (décalage de synchronisation de la position)
local function presDuPnj(source)
    local pnj = Config.Pnj
    if not pnj or not pnj.Actif then return true end
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end
    local c = pnj.Coords
    return #(GetEntityCoords(ped) - vec3(c.x, c.y, c.z)) <= (pnj.Distance or 2.5) + MARGE_PNJ
end

-- Actions ---------------------------------------------------------------------------

--- Coffre du jour : série (avec bouclier), rang, bonus tiré au sort, puis remise
local function ouvrirCoffreDuJour(source, joueur, cle)
    local aujourdhui = jour(0)
    local ligne = ligneJoueur(source, cle, joueur.identifiant)
    if ligne.dernier_jour == aujourdhui then
        notifier(source, _L('deja_recupere'), 'warning')
        return false
    end

    local serie, bouclierUtilise = serieSuivante(ligne)
    local indexJour = indexRecompense(serie)
    local recompense = Config.Recompenses[indexJour]
    local rang = rangPour(serie)
    local bonus = tirerBonus()
    local base = recompense.argent and math.floor(tonumber(recompense.argent.montant) or 0) or 0
    local montant = base > 0 and base <= Config.MontantMax and montantCoffre(base, rang.mult, bonus) or base
    local palier = recompense.gros == true and 1 or 0
    local semaine = semaineCourante()
    local boucliersDepart = ligne.nouvelle and ((Config.Boucliers and Config.Boucliers.Depart) or 0) or (ligne.boucliers or 0)
    local boucliersApres = boucliersDepart - (bouclierUtilise and 1 or 0)

    -- Réservation atomique du jour : même avec deux personnages / deux requêtes, une seule passe.
    -- Les compteurs de la semaine sont remis à zéro dans la même requête si la semaine a changé.
    MySQL.insert.await('INSERT IGNORE INTO `ash_vipdaily_joueurs` (identifiant, boucliers) VALUES (?, ?)', { cle, boucliersDepart })
    local modifie = MySQL.update.await([[
        UPDATE `ash_vipdaily_joueurs` SET
            dernier_jour = ?, serie = ?, total = total + 1, nom = ?,
            meilleure_serie = GREATEST(meilleure_serie, ?), boucliers = ?,
            coffres_semaine = IF(semaine = ?, coffres_semaine + 1, 1),
            palier_semaine  = IF(semaine = ?, palier_semaine + ?, ?),
            temps_semaine   = IF(semaine = ?, temps_semaine, 0),
            defis_semaine   = IF(semaine = ?, defis_semaine, 0),
            semaine = ?
        WHERE identifiant = ? AND (dernier_jour IS NULL OR dernier_jour <> ?)
    ]], { aujourdhui, serie, nomClassement(joueur), serie, boucliersApres,
          semaine, semaine, palier, palier, semaine, semaine, semaine, cle, aujourdhui })

    if modifie ~= 1 then
        notifier(source, _L('deja_recupere'), 'warning')
        return false
    end

    local lot = { items = recompense.items, argent = recompense.argent and { compte = recompense.argent.compte, montant = montant } or nil }
    local ok, donnes, manques = donnerRecompense(source, lot, 'ash_vipdaily : coffre du jour')
    if not ok then
        -- Rien n'a été donné : on rend le jour au joueur (série, bouclier et compteurs de la semaine)
        MySQL.update.await([[
            UPDATE `ash_vipdaily_joueurs` SET dernier_jour = ?, serie = ?, total = total - 1, boucliers = ?,
                coffres_semaine = GREATEST(coffres_semaine - 1, 0), palier_semaine = GREATEST(palier_semaine - ?, 0)
            WHERE identifiant = ?
        ]], { ligne.dernier_jour, ligne.serie or 0, boucliersDepart, palier, cle })
        notifier(source, donnes == 'inventaire' and _L('inventaire_plein') or _L('remise_impossible'), 'error')
        return false
    end

    if bouclierUtilise then notifier(source, _L('bouclier_utilise', serie), 'inform') end
    notifier(source, _L('recupere', indexJour, table.concat(donnes, ', ')), 'success')
    if #manques > 0 then
        notifier(source, _L('items_manques', table.concat(manques, ', ')), 'warning')
    end

    logDiscord(_L('log_titre'), ('**%s** (%s, %s) — jour %d, série %d, rang %s ×%s, bonus ×%s\n%s%s'):format(
        joueur.prenom .. ' ' .. joueur.nom, joueur.identifiant, cle, indexJour, serie, rang.nom, rang.mult, bonus,
        table.concat(donnes, ', '),
        #manques > 0 and ('\n⚠ Non remis : ' .. table.concat(manques, ', ')) or ''
    ), #manques > 0 and 16753920 or 4054148)
    debug(('%s a ouvert le coffre du jour %d (bonus ×%s)'):format(cle, indexJour, bonus))

    local nouvelEtat = etat(source, joueur, cle, { vip = true })
    nouvelEtat.revelation = {
        jour = indexJour,
        base = base,
        rang = { nom = rang.nom, mult = rang.mult },
        bonus = bonus,
        montant = montant,
        items = itemsAffichables(recompense.items),
        bouclierUtilise = bouclierUtilise,
    }
    return nouvelEtat
end

--- Coffre légendaire : consomme les clés, rendues si rien n'a pu être remis
local function ouvrirCoffreLegendaire(source, joueur, cle)
    local conf = Config.CoffreLegendaire
    if not conf then return false end
    local requises = math.max(1, math.floor(conf.Cles or 3))
    local modifie = MySQL.update.await(
        'UPDATE `ash_vipdaily_joueurs` SET cles = cles - ? WHERE identifiant = ? AND cles >= ?', { requises, cle, requises })
    if modifie ~= 1 then
        notifier(source, _L('cles_manquantes', requises), 'error')
        return false
    end

    local ok, donnes, manques = donnerRecompense(source, conf, 'ash_vipdaily : coffre légendaire')
    if not ok then
        MySQL.update.await('UPDATE `ash_vipdaily_joueurs` SET cles = cles + ? WHERE identifiant = ?', { requises, cle })
        notifier(source, donnes == 'inventaire' and _L('inventaire_plein') or _L('remise_impossible'), 'error')
        return false
    end

    notifier(source, _L('legendaire_ouvert', table.concat(donnes, ', ')), 'success')
    if #manques > 0 then
        notifier(source, _L('items_manques', table.concat(manques, ', ')), 'warning')
    end
    logDiscord(_L('log_legendaire'), ('**%s** (%s)\n%s'):format(joueur.prenom .. ' ' .. joueur.nom, cle, table.concat(donnes, ', ')), 16766720)

    local nouvelEtat = etat(source, joueur, cle, { vip = true })
    nouvelEtat.revelationLegendaire = {
        montant = conf.argent and math.floor(conf.argent.montant or 0) or 0,
        items = itemsAffichables(conf.items),
    }
    return nouvelEtat
end

-- Callbacks -------------------------------------------------------------------------

lib.callback.register('ash_vipdaily:server:ouvrir', function(source)
    if not autorise(source) then return false end
    if not pasTropRapide(source, derniereOuverture, Config.DelaiOuverture or 1000, true) then return false end
    local joueur = Bridge.GetPlayer(source)
    local cle = cleCompte(source)
    if not joueur or not cle then
        notifier(source, _L('personnage_non_charge'), 'error')
        return false
    end
    if not attendreBase() then
        notifier(source, _L('action_erreur'), 'error')
        return false
    end
    return etat(source, joueur, cle)
end)

lib.callback.register('ash_vipdaily:server:rappel', function(source)
    if not Config.RappelConnexion then return false end
    if not pasTropRapide(source, derniereOuverture, Config.DelaiOuverture or 1000, false) then return false end
    local joueur = Bridge.GetPlayer(source)
    local cle = cleCompte(source)
    if not joueur or not cle or not attendreBase() or estVip(source) ~= true then return false end
    return ligneJoueur(source, cle, joueur.identifiant).dernier_jour ~= jour(0)
end)

local ACTIONS = { recuperer = ouvrirCoffreDuJour, legendaire = ouvrirCoffreLegendaire }

lib.callback.register('ash_vipdaily:server:action', function(source, data)
    if not autorise(source) then return false end
    if not pasTropRapide(source, dernierAppel, Config.DelaiActions, true) then return false end

    -- Actions acceptées ; le contenu des coffres est décidé ici, jamais par le client
    local action = type(data) == 'table' and ACTIONS[data.type]
    if not action then
        debug(('données invalides de %s'):format(source))
        return false
    end
    if not configValide or not attendreBase() then
        notifier(source, _L('action_erreur'), 'error')
        return false
    end
    if not presDuPnj(source) then
        notifier(source, _L('trop_loin'), 'error')
        return false
    end
    if verrou[source] then return false end
    verrou[source] = true

    local function finir(resultat)
        verrou[source] = nil
        return resultat
    end

    local joueur = Bridge.GetPlayer(source)
    local cle = cleCompte(source)
    if not joueur or not cle then
        notifier(source, _L('personnage_non_charge'), 'error')
        return finir(false)
    end

    -- Statut VIP revérifié au moment d'ouvrir (pas de cache)
    local vip, erreurVip = estVip(source, true)
    if not vip then
        if erreurVip then
            avertir(('statut VIP de %s illisible : %s'):format(cle, erreurVip))
            notifier(source, _L('discord_indisponible'), 'error')
        else
            notifier(source, _L('pas_vip'), 'error')
        end
        return finir(false)
    end

    local ok, resultat = pcall(action, source, joueur, cle)
    if not ok then
        avertir(('action %s de %s en erreur : %s'):format(data.type, cle, tostring(resultat)))
        notifier(source, _L('action_erreur'), 'error')
        return finir(false)
    end
    return finir(resultat)
end)

-- Nettoyage ---------------------------------------------------------------------------

AddEventHandler('playerDropped', function()
    enregistrerTemps(source)
    debutSession[source] = nil
    dernierAppel[source] = nil
    derniereOuverture[source] = nil
    verrou[source] = nil
    cacheVip[source] = nil
end)
