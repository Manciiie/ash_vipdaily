-- ash_vipdaily — client
-- Aucune boucle permanente : la ressource consomme 0.00 ms au repos.
-- Framework via Bridge (bridge/client.lua) : Bridge.GetPlayerData(),
-- Bridge.OnPlayerLoaded(fonction), Bridge.OnJobUpdate(fonction).

local nuiOuverte = false

local function ouvrir()
    if nuiOuverte then return end

    -- Le serveur vérifie les permissions et renvoie les données à afficher
    local donnees = lib.callback.await('ash_vipdaily:server:ouvrir', false)
    if not donnees then return end

    nuiOuverte = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'ouvrir', titre = _L('titre'), donnees = donnees })
end

local function fermer()
    if not nuiOuverte then return end
    nuiOuverte = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'fermer' })
end

-- Callbacks NUI ---------------------------------------------------------------

RegisterNUICallback('fermer', function(_, cb)
    fermer()
    cb('ok')
end)

RegisterNUICallback('action', function(data, cb)
    -- Le serveur renvoie le nouvel état (ou false) : l'interface se met à jour sans rouvrir
    local etat = lib.callback.await('ash_vipdaily:server:action', false, data)
    cb({ ok = etat ~= false and etat ~= nil, etat = etat or nil })
end)

-- Sécurité : on rend la main au joueur si la ressource s'arrête NUI ouverte
AddEventHandler('onResourceStop', function(ressource)
    if ressource == GetCurrentResourceName() and nuiOuverte then
        SetNuiFocus(false, false)
    end
end)

-- Commande et touche -----------------------------------------------------------

RegisterCommand(Config.Commande, ouvrir, false)

if Config.Touche ~= '' then
    RegisterKeyMapping(Config.Commande, _L('ouvrir'), 'keyboard', Config.Touche)
end

-- Rappel à la connexion (un seul appel serveur, aucune boucle) ------------------

Bridge.OnPlayerLoaded(function()
    if not Config.RappelConnexion then return end
    SetTimeout(15000, function()
        if lib.callback.await('ash_vipdaily:server:rappel', false) then
            lib.notify({ title = _L('titre'), description = _L('rappel', Config.Commande), type = 'inform', duration = 10000 })
        end
    end)
end)
