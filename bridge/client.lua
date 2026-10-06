-- Bridge — côté client
-- Bridge.GetPlayerData()       → joueur normalisé (ou nil si pas encore chargé)
-- Bridge.OnPlayerLoaded(cb)    → cb(joueur) à la connexion du personnage
-- Bridge.OnJobUpdate(cb)       → cb(job) à chaque changement de métier
--
-- Joueur normalisé : { identifiant, prenom, nom, job = { nom, label, grade, gradeLabel } }

local Core

if Bridge.Framework == 'qbcore' then
    Core = exports['qb-core']:GetCoreObject()
elseif Bridge.Framework == 'esx' then
    Core = exports['es_extended']:getSharedObject()
end

local function normaliserJob(job)
    if not job then return nil end
    if Bridge.Framework == 'esx' then
        return { nom = job.name, label = job.label, grade = job.grade, gradeLabel = job.grade_label }
    end
    return { nom = job.name, label = job.label, grade = job.grade and job.grade.level or 0, gradeLabel = job.grade and job.grade.name or '' }
end

local function donneesBrutes()
    if Bridge.Framework == 'qbox' then return exports.qbx_core:GetPlayerData() end
    if Bridge.Framework == 'qbcore' then return Core.Functions.GetPlayerData() end
    if Bridge.Framework == 'esx' then return Core.GetPlayerData() end
end

local function estCharge()
    if Bridge.Framework == 'esx' then return Core.IsPlayerLoaded() end
    return LocalPlayer.state.isLoggedIn == true
end

function Bridge.GetPlayerData()
    if not Bridge.Framework or not estCharge() then return nil end
    local d = donneesBrutes()
    if not d or not d.job then return nil end

    if Bridge.Framework == 'esx' then
        return {
            identifiant = d.identifier,
            prenom = d.firstName or '',
            nom = d.lastName or '',
            job = normaliserJob(d.job),
        }
    end

    local infos = d.charinfo or {}
    return {
        identifiant = d.citizenid,
        prenom = infos.firstname or '',
        nom = infos.lastname or '',
        job = normaliserJob(d.job),
    }
end

function Bridge.OnPlayerLoaded(cb)
    local evenement = Bridge.Framework == 'esx' and 'esx:playerLoaded' or 'QBCore:Client:OnPlayerLoaded'
    RegisterNetEvent(evenement, function()
        -- Petit délai : les données du joueur sont remplies juste après l'événement
        SetTimeout(500, function() cb(Bridge.GetPlayerData()) end)
    end)

    -- Redémarrage de la ressource en jeu : le joueur est déjà chargé
    CreateThread(function()
        local joueur = Bridge.GetPlayerData()
        if joueur then cb(joueur) end
    end)
end

function Bridge.OnJobUpdate(cb)
    local evenement = Bridge.Framework == 'esx' and 'esx:setJob' or 'QBCore:Client:OnJobUpdate'
    RegisterNetEvent(evenement, function(job)
        cb(normaliserJob(job))
    end)
end
