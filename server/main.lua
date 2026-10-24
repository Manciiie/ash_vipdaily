-- ash_vipdaily — serveur
-- Règle d'or : ne jamais faire confiance au client. Tout est vérifié ici :
-- statut VIP, jour, série, contenu de la récompense et montants.

-- Le joueur, l'argent et les items passent par Bridge (bridge/server.lua) : QBCore, Qbox et ESX.
local dernierAppel = {}
local verrou = {}        -- empêche deux récupérations simultanées pour un même joueur
local cacheVip = {}      -- [source] = { vip = bool, expire = os.time() }

local TOKEN_BOT = GetConvar('ash_vipdaily_bot_token', '')
local WEBHOOK = GetConvar('ash_vipdaily_webhook', '')

local function debug(...)
    if Config.Debug then print('[ash_vipdaily]', ...) end
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

--- Anti-spam : une action par joueur toutes les Config.DelaiActions ms
local function pasTropRapide(source)
    local maintenant = GetGameTimer()
    local precedent = dernierAppel[source]
    if precedent and maintenant - precedent < Config.DelaiActions then
        notifier(source, _L('trop_rapide'), 'warning')
        return false
    end
    dernierAppel[source] = maintenant
    return true
end

local function logDiscord(titre, description, couleur)
    if WEBHOOK == '' then return end
    PerformHttpRequest(WEBHOOK, function() end, 'POST', json.encode({
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

-- Statut VIP ----------------------------------------------------------------------

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
    PerformHttpRequest(
        ('https://discord.com/api/v10/guilds/%s/members/%s'):format(conf.ServeurId, discord),
        function(code, corps)
            if code ~= 200 or not corps then
                debug(('Discord a répondu %s pour %s'):format(code, discord))
                return p:resolve(false)
            end
            local membre = json.decode(corps)
            local roles = membre and membre.roles or {}
            for _, role in ipairs(roles) do
                for _, vip in ipairs(conf.Roles) do
                    if role == vip then return p:resolve(true) end
                end
            end
            p:resolve(false)
        end,
        'GET', '', { Authorization = 'Bot ' .. TOKEN_BOT }
    )
    return Citizen.Await(p)
end

--- ASH City : statut VIP fourni par ash_newplayers (rôle Discord lu et mis en cache par lui).
--- Renvoie true / false, ou nil si la ressource n'est pas utilisable (on passe alors aux autres méthodes).
--- forcer = true (au moment de récupérer) : relecture immédiate du rôle Discord.
local avertiRessourceVip = false
local function vipParRessource(source, forcer)
    local ressource = Config.Vip.Ressource
    if not ressource or ressource == '' or GetResourceState(ressource) ~= 'started' then return nil end

    local ok, statut = pcall(function()
        if forcer then return exports[ressource]:RefreshVip(source) end
        return exports[ressource]:GetVipStatus(source)
    end)
    if not ok then
        if not avertiRessourceVip then
            avertiRessourceVip = true
            print(('^3[ash_vipdaily] %s : lecture du statut VIP impossible (%s), autres méthodes utilisées^0'):format(ressource, tostring(statut)))
        end
        return nil
    end
    return statut ~= nil
end

local function estVip(source, forcer)
    if Config.Vip.Ace and IsPlayerAceAllowed(source, Config.Vip.Ace) then
        return true
    end

    -- ash_newplayers a son propre cache : pas de double mise en cache ici
    local parRessource = vipParRessource(source, forcer)
    if parRessource ~= nil then
        return parRessource
    end

    local cache = cacheVip[source]
    if not forcer and cache and cache.expire > os.time() then
        return cache.vip
    end

    local vip = false
    if type(Config.Vip.Personnalisee) == 'function' then
        local ok, resultat = pcall(Config.Vip.Personnalisee, source)
        vip = ok and resultat == true
    end
    if not vip then vip = roleDiscordVip(source) end

    cacheVip[source] = { vip = vip, expire = os.time() + (Config.Vip.CacheMinutes or 10) * 60 }
    return vip
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

local function ligneJoueur(identifiant)
    return MySQL.single.await(
        'SELECT dernier_jour, serie, total FROM `ash_vipdaily_joueurs` WHERE identifiant = ?',
        { identifiant }
    ) or { dernier_jour = nil, serie = 0, total = 0 }
end

--- Série qu'aura le joueur s'il récupère aujourd'hui
local function serieSuivante(ligne)
    if Config.SerieStricte and ligne.dernier_jour ~= jour(1) then return 1 end
    return (ligne.serie or 0) + 1
end

--- État complet envoyé à l'interface
local function etat(source, joueur)
    local vip = estVip(source)
    local ligne = ligneJoueur(joueur.identifiant)
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

local function donnerRecompense(source, recompense)
    local donnes, manques = {}, {}

    -- Items d'abord : si le tout premier échoue (inventaire plein), rien n'a été donné
    for i, item in ipairs(recompense.items or {}) do
        local quantite = math.floor(tonumber(item.quantite) or 0)
        if quantite > 0 and Bridge.AddItem(source, item.nom, quantite) then
            donnes[#donnes + 1] = ('%dx %s'):format(quantite, item.label or item.nom)
        else
            if i == 1 then return false, 'inventaire' end
            manques[#manques + 1] = item.label or item.nom
        end
    end

    local argent = recompense.argent
    if argent then
        local montant = math.floor(tonumber(argent.montant) or 0)
        local compte = argent.compte == 'cash' and 'cash' or 'bank'
        if montant > 0 and montant <= Config.MontantMax then
            if Bridge.AddMoney(source, compte, montant, 'ash_vipdaily : récompense quotidienne') then
                donnes[#donnes + 1] = ('$%d (%s)'):format(montant, compte == 'cash' and _L('liquide') or _L('banque'))
            end
        else
            print(('[ash_vipdaily] montant refusé (%s) : vérifiez Config.Recompenses / Config.MontantMax'):format(montant))
        end
    end

    return true, donnes, manques
end

-- Callbacks -------------------------------------------------------------------------

lib.callback.register('ash_vipdaily:server:ouvrir', function(source)
    if not autorise(source) then return false end
    local joueur = Bridge.GetPlayer(source)
    if not joueur then return false end
    return etat(source, joueur)
end)

lib.callback.register('ash_vipdaily:server:rappel', function(source)
    if not Config.RappelConnexion then return false end
    local joueur = Bridge.GetPlayer(source)
    if not joueur or not estVip(source) then return false end
    return ligneJoueur(joueur.identifiant).dernier_jour ~= jour(0)
end)

lib.callback.register('ash_vipdaily:server:action', function(source, data)
    if not autorise(source) then return false end
    if not pasTropRapide(source) then return false end

    -- Seule action acceptée ; le contenu de la récompense est décidé ici, jamais par le client
    if type(data) ~= 'table' or data.type ~= 'recuperer' then
        debug(('données invalides de %s'):format(source))
        return false
    end
    if verrou[source] then return false end
    verrou[source] = true

    local function finir(resultat)
        verrou[source] = nil
        return resultat
    end

    local joueur = Bridge.GetPlayer(source)
    if not joueur then return finir(false) end

    -- Statut VIP revérifié au moment de récupérer (pas de cache)
    if not estVip(source, true) then
        notifier(source, _L('pas_vip'), 'error')
        return finir(false)
    end

    local aujourdhui = jour(0)
    local ligne = ligneJoueur(joueur.identifiant)
    if ligne.dernier_jour == aujourdhui then
        notifier(source, _L('deja_recupere'), 'warning')
        return finir(false)
    end

    local serie = serieSuivante(ligne)
    local recompense = Config.Recompenses[indexRecompense(serie)]

    -- Réservation atomique du jour : même avec deux personnages / deux requêtes, une seule passe
    MySQL.insert.await('INSERT IGNORE INTO `ash_vipdaily_joueurs` (identifiant) VALUES (?)', { joueur.identifiant })
    local modifie = MySQL.update.await([[
        UPDATE `ash_vipdaily_joueurs` SET dernier_jour = ?, serie = ?, total = total + 1
        WHERE identifiant = ? AND (dernier_jour IS NULL OR dernier_jour <> ?)
    ]], { aujourdhui, serie, joueur.identifiant, aujourdhui })

    if modifie ~= 1 then
        notifier(source, _L('deja_recupere'), 'warning')
        return finir(false)
    end

    local ok, donnes, manques = donnerRecompense(source, recompense)
    if not ok then
        -- Rien n'a été donné : on rend le jour au joueur
        MySQL.update.await(
            'UPDATE `ash_vipdaily_joueurs` SET dernier_jour = ?, serie = ?, total = total - 1 WHERE identifiant = ?',
            { ligne.dernier_jour, ligne.serie or 0, joueur.identifiant })
        notifier(source, _L('inventaire_plein'), 'error')
        return finir(false)
    end

    notifier(source, _L('recupere', indexRecompense(serie), table.concat(donnes, ', ')), 'success')
    if #manques > 0 then
        notifier(source, _L('items_manques', table.concat(manques, ', ')), 'warning')
    end

    logDiscord(_L('log_titre'), ('**%s** (%s) — jour %d, série %d\n%s%s'):format(
        joueur.prenom .. ' ' .. joueur.nom, joueur.identifiant, indexRecompense(serie), serie,
        table.concat(donnes, ', '),
        #manques > 0 and ('\n⚠ Non remis : ' .. table.concat(manques, ', ')) or ''
    ), #manques > 0 and 16753920 or 4054148)

    debug(('%s a récupéré le jour %d'):format(joueur.identifiant, serie))
    return finir(etat(source, joueur))
end)

-- Nettoyage ---------------------------------------------------------------------------

AddEventHandler('playerDropped', function()
    dernierAppel[source] = nil
    verrou[source] = nil
    cacheVip[source] = nil
end)
