-- ash_vipdaily — client
-- Aucune boucle permanente : la ressource consomme 0.00 ms au repos
-- (le PNJ n'existe et la touche E n'est surveillée qu'à proximité).
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

-- Commande (désactivée par défaut) ---------------------------------------------

if Config.Commande and Config.Commande ~= '' then
    RegisterCommand(Config.Commande, ouvrir, false)
    if Config.Touche ~= '' then
        RegisterKeyMapping(Config.Commande, _L('ouvrir'), 'keyboard', Config.Touche)
    end
end

-- PNJ ----------------------------------------------------------------------------

local pnj = Config.Pnj or {}
local ped, blip
local cibleOx = false
local texteAffiche = false

local function supprimerPed()
    if not ped then return end
    if cibleOx then
        exports.ox_target:removeLocalEntity(ped, 'ash_vipdaily_pnj')
        cibleOx = false
    end
    if DoesEntityExist(ped) then DeleteEntity(ped) end
    ped = nil
end

local function creerPed()
    if ped and DoesEntityExist(ped) then return end
    local c = pnj.Coords
    local ok, modele = pcall(lib.requestModel, pnj.Modele, 10000)
    if not ok or not modele then
        print(('^3[ash_vipdaily] modèle du PNJ introuvable (%s) : vérifiez Config.Pnj.Modele^0'):format(tostring(pnj.Modele)))
        return
    end

    ped = CreatePed(4, modele, c.x, c.y, c.z - 1.0, c.w, false, false)
    SetModelAsNoLongerNeeded(modele)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    if pnj.Scenario and pnj.Scenario ~= '' then
        TaskStartScenarioInPlace(ped, pnj.Scenario, 0, true)
    end

    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addLocalEntity(ped, { {
            name = 'ash_vipdaily_pnj',
            icon = 'fa-solid fa-gift',
            label = _L('pnj_interagir'),
            distance = pnj.Distance or 2.5,
            onSelect = ouvrir,
        } })
        cibleOx = true
    end
end

local function cacherTexte()
    if texteAffiche then
        lib.hideTextUI()
        texteAffiche = false
    end
end

if pnj.Actif then
    local position = vec3(pnj.Coords.x, pnj.Coords.y, pnj.Coords.z)

    if pnj.Blip and pnj.Blip.Actif then
        blip = AddBlipForCoord(position.x, position.y, position.z)
        SetBlipSprite(blip, pnj.Blip.Sprite or 617)
        SetBlipColour(blip, pnj.Blip.Couleur or 27)
        SetBlipScale(blip, pnj.Blip.Taille or 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(pnj.Blip.Nom or _L('titre'))
        EndTextCommandSetBlipName(blip)
    end

    -- Le PNJ n'est créé que pour les joueurs proches
    lib.points.new({
        coords = position,
        distance = pnj.DistanceApparition or 60.0,
        onEnter = creerPed,
        onExit = supprimerPed,
    })

    -- Interaction : sans ox_target, touche E (surveillée seulement à quelques mètres du PNJ)
    lib.points.new({
        coords = position,
        distance = pnj.Distance or 2.5,
        nearby = function()
            if cibleOx or nuiOuverte then return cacherTexte() end
            if not texteAffiche then
                lib.showTextUI(_L('pnj_touche'))
                texteAffiche = true
            end
            if IsControlJustReleased(0, 38) then
                cacherTexte()
                ouvrir()
            end
        end,
        onExit = function()
            cacherTexte()
            fermer()   -- le joueur s'éloigne du PNJ : le panneau se ferme
        end,
    })
end

-- Export : place un point GPS sur le PNJ (utilisé par le bouton du menu pause ash_pausemenu)
-- Renvoie false si le PNJ est désactivé (l'appelant peut alors ouvrir le panneau autrement).
exports('GuiderVersPnj', function()
    if not pnj.Actif then return false end
    SetNewWaypoint(pnj.Coords.x, pnj.Coords.y)
    lib.notify({ title = _L('titre'), description = _L('gps_pnj'), type = 'inform' })
    return true
end)

-- Sécurité : on rend la main au joueur si la ressource s'arrête NUI ouverte
AddEventHandler('onResourceStop', function(ressource)
    if ressource ~= GetCurrentResourceName() then return end
    if nuiOuverte then SetNuiFocus(false, false) end
    cacherTexte()
    supprimerPed()
    if blip then RemoveBlip(blip) end
end)

-- Rappel à la connexion (un seul appel serveur, aucune boucle) ------------------

Bridge.OnPlayerLoaded(function()
    if not Config.RappelConnexion then return end
    SetTimeout(15000, function()
        if lib.callback.await('ash_vipdaily:server:rappel', false) then
            lib.notify({ title = _L('titre'), description = _L('rappel'), type = 'inform', duration = 10000 })
        end
    end)
end)
