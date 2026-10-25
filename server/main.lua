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

local function notifier(source, message, typeNotif)
    TriggerClientEvent('ox_lib:notify', source, {
        title = _L('titre'),
        description = message,
        type = typeNotif or 'inform',
    })
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

-- Jours ---------------------------------------------------------------------------

local DECALAGE = (Config.HeureReinitialisation or 0) * 3600

--- Jour « logique » : il change à Config.HeureReinitialisation, pas à minuit
local function jour(decalageJours)
    return os.date('%Y-%m-%d', os.time() - DECALAGE - (decalageJours or 0) * 86400)
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
local cacheListe
local function listeRecompenses()
    if cacheListe then return cacheListe end
    cacheListe = {}
    for i, r in ipairs(Config.Recompenses) do
        local items = {}
        for _, item in ipairs(r.items or {}) do
            items[#items + 1] = { label = item.label or item.nom, quantite = math.floor(item.quantite or 0) }
        end
        cacheListe[i] = {
            argent = r.argent and {
                compte = r.argent.compte == 'cash' and 'cash' or 'bank',
                montant = math.floor(r.argent.montant or 0),
            } or nil,
            items = items,
            gros = r.gros == true,
        }
    end
    return cacheListe
end

-- Base de données -----------------------------------------------------------------

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ash_vipdaily_joueurs` (
            `identifiant`   VARCHAR(64) NOT NULL,
            `dernier_jour`  VARCHAR(10) NULL,
            `serie`         INT NOT NULL DEFAULT 0,
            `total`         INT NOT NULL DEFAULT 0,
            `maj_le`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifiant`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end)

local REQUETE_LIGNE = 'SELECT dernier_jour, serie, total FROM `ash_vipdaily_joueurs` WHERE identifiant = ?'

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
local function ligneJoueur(source, cle, personnageActuel)
    local ligne = MySQL.single.await(REQUETE_LIGNE, { cle })
    if ligne then return ligne end

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
                'INSERT IGNORE INTO `ash_vipdaily_joueurs` (identifiant, dernier_jour, serie, total) VALUES (?, ?, ?, ?)',
                { cle, recente.dernier_jour, recente.serie or 0, total })
            for _, id in ipairs(anciens) do
                MySQL.update.await('DELETE FROM `ash_vipdaily_joueurs` WHERE identifiant = ?', { id })
            end
            debug(('%d ligne(s) de personnage fusionnée(s) pour le compte %s'):format(#lignes, cle))
            ligne = MySQL.single.await(REQUETE_LIGNE, { cle })
        end
    end
    return ligne or { dernier_jour = nil, serie = 0, total = 0 }
end

--- Série qu'aura le joueur s'il récupère aujourd'hui
local function serieSuivante(ligne)
    if Config.SerieStricte and ligne.dernier_jour ~= jour(1) then return 1 end
    return (ligne.serie or 0) + 1
end

--- État complet envoyé à l'interface
local function etat(source, joueur, cle)
    local vip = estVip(source) == true
    local ligne = ligneJoueur(source, cle, joueur.identifiant)
    local disponible = vip and ligne.dernier_jour ~= jour(0)

    -- Jour mis en avant : celui à récupérer, sinon celui de demain
    local prochain
    if ligne.dernier_jour == jour(0) then
        prochain = (ligne.serie or 0) + 1
    else
        prochain = serieSuivante(ligne)
    end

    return {
        joueur = ('%s %s'):format(joueur.prenom, joueur.nom),
        vip = vip,
        disponible = disponible,
        dejaRecupere = ligne.dernier_jour == jour(0),
        serie = (not Config.SerieStricte or ligne.dernier_jour == jour(0) or ligne.dernier_jour == jour(1)) and (ligne.serie or 0) or 0,
        total = ligne.total or 0,
        jourCycle = indexRecompense(prochain),
        recompenses = listeRecompenses(),
        secondes = secondesAvantReinit(),
    }
end

-- Distribution --------------------------------------------------------------------

--- Renvoie false + raison si rien n'a été remis (le jour est alors rendu au joueur)
local function donnerRecompense(source, recompense)
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
            if Bridge.AddMoney(source, compte, montant, 'ash_vipdaily : récompense quotidienne') then
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
    return etat(source, joueur, cle)
end)

lib.callback.register('ash_vipdaily:server:rappel', function(source)
    if not Config.RappelConnexion then return false end
    if not pasTropRapide(source, derniereOuverture, Config.DelaiOuverture or 1000, false) then return false end
    local joueur = Bridge.GetPlayer(source)
    local cle = cleCompte(source)
    if not joueur or not cle or estVip(source) ~= true then return false end
    return ligneJoueur(source, cle, joueur.identifiant).dernier_jour ~= jour(0)
end)

lib.callback.register('ash_vipdaily:server:action', function(source, data)
    if not autorise(source) then return false end
    if not pasTropRapide(source, dernierAppel, Config.DelaiActions, true) then return false end

    -- Seule action acceptée ; le contenu de la récompense est décidé ici, jamais par le client
    if type(data) ~= 'table' or data.type ~= 'recuperer' then
        debug(('données invalides de %s'):format(source))
        return false
    end
    if not configValide then
        notifier(source, _L('action_erreur'), 'error')
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

    -- Statut VIP revérifié au moment de récupérer (pas de cache)
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

    local aujourdhui = jour(0)
    local ligne = ligneJoueur(source, cle, joueur.identifiant)
    if ligne.dernier_jour == aujourdhui then
        notifier(source, _L('deja_recupere'), 'warning')
        return finir(false)
    end

    local serie = serieSuivante(ligne)
    local recompense = Config.Recompenses[indexRecompense(serie)]

    -- Réservation atomique du jour : même avec deux personnages / deux requêtes, une seule passe
    MySQL.insert.await('INSERT IGNORE INTO `ash_vipdaily_joueurs` (identifiant) VALUES (?)', { cle })
    local modifie = MySQL.update.await([[
        UPDATE `ash_vipdaily_joueurs` SET dernier_jour = ?, serie = ?, total = total + 1
        WHERE identifiant = ? AND (dernier_jour IS NULL OR dernier_jour <> ?)
    ]], { aujourdhui, serie, cle, aujourdhui })

    if modifie ~= 1 then
        notifier(source, _L('deja_recupere'), 'warning')
        return finir(false)
    end

    local ok, donnes, manques = donnerRecompense(source, recompense)
    if not ok then
        -- Rien n'a été donné : on rend le jour au joueur
        MySQL.update.await(
            'UPDATE `ash_vipdaily_joueurs` SET dernier_jour = ?, serie = ?, total = total - 1 WHERE identifiant = ?',
            { ligne.dernier_jour, ligne.serie or 0, cle })
        notifier(source, donnes == 'inventaire' and _L('inventaire_plein') or _L('remise_impossible'), 'error')
        return finir(false)
    end

    notifier(source, _L('recupere', indexRecompense(serie), table.concat(donnes, ', ')), 'success')
    if #manques > 0 then
        notifier(source, _L('items_manques', table.concat(manques, ', ')), 'warning')
    end

    logDiscord(_L('log_titre'), ('**%s** (%s, %s) — jour %d, série %d\n%s%s'):format(
        joueur.prenom .. ' ' .. joueur.nom, joueur.identifiant, cle, indexRecompense(serie), serie,
        table.concat(donnes, ', '),
        #manques > 0 and ('\n⚠ Non remis : ' .. table.concat(manques, ', ')) or ''
    ), #manques > 0 and 16753920 or 4054148)

    debug(('%s a récupéré le jour %d'):format(cle, serie))
    return finir(etat(source, joueur, cle))
end)

-- Nettoyage ---------------------------------------------------------------------------

AddEventHandler('playerDropped', function()
    dernierAppel[source] = nil
    derniereOuverture[source] = nil
    verrou[source] = nil
    cacheVip[source] = nil
end)
