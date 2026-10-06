-- Bridge — côté serveur
-- Bridge.GetPlayer(source)                          → joueur normalisé (ou nil)
-- Bridge.HasJob(source, 'police' | { 'police', 'sheriff' }, gradeMin?)
-- Bridge.GetMoney(source, compte)                   → montant
-- Bridge.AddMoney(source, compte, montant, raison)  → true / false
-- Bridge.RemoveMoney(source, compte, montant, raison) → true / false (refuse si solde insuffisant)
--
-- Comptes : 'cash', 'bank' (et 'black' pour l'argent sale sous ESX).
-- Joueur normalisé : { source, identifiant, prenom, nom, job = { nom, label, grade, gradeLabel } }

local Core

if Bridge.Framework == 'qbcore' then
    Core = exports['qb-core']:GetCoreObject()
elseif Bridge.Framework == 'esx' then
    Core = exports['es_extended']:getSharedObject()
end

local COMPTES_ESX = { cash = 'money', bank = 'bank', black = 'black_money' }

local function joueurBrut(source)
    if Bridge.Framework == 'qbox' then return exports.qbx_core:GetPlayer(source) end
    if Bridge.Framework == 'qbcore' then return Core.Functions.GetPlayer(source) end
    if Bridge.Framework == 'esx' then return Core.GetPlayerFromId(source) end
end

local function montantValide(montant)
    montant = math.floor(tonumber(montant) or 0)
    if montant <= 0 then return nil end
    return montant
end

function Bridge.GetPlayer(source)
    local p = joueurBrut(source)
    if not p then return nil end

    if Bridge.Framework == 'esx' then
        return {
            source = source,
            identifiant = p.identifier,
            prenom = p.get('firstName') or '',
            nom = p.get('lastName') or '',
            job = { nom = p.job.name, label = p.job.label, grade = p.job.grade, gradeLabel = p.job.grade_label },
        }
    end

    local d = p.PlayerData
    return {
        source = source,
        identifiant = d.citizenid,
        prenom = d.charinfo.firstname,
        nom = d.charinfo.lastname,
        job = { nom = d.job.name, label = d.job.label, grade = d.job.grade.level, gradeLabel = d.job.grade.name },
    }
end

function Bridge.HasJob(source, metiers, gradeMin)
    local joueur = Bridge.GetPlayer(source)
    if not joueur then return false end
    if type(metiers) == 'string' then metiers = { metiers } end
    for _, nom in ipairs(metiers) do
        if joueur.job.nom == nom then
            return joueur.job.grade >= (gradeMin or 0)
        end
    end
    return false
end

function Bridge.GetMoney(source, compte)
    compte = compte or 'cash'
    local p = joueurBrut(source)
    if not p then return 0 end

    if Bridge.Framework == 'esx' then
        local c = p.getAccount(COMPTES_ESX[compte] or compte)
        return c and c.money or 0
    elseif Bridge.Framework == 'qbox' then
        return exports.qbx_core:GetMoney(source, compte) or 0
    end
    return p.Functions.GetMoney(compte) or 0
end

function Bridge.AddMoney(source, compte, montant, raison)
    montant = montantValide(montant)
    local p = joueurBrut(source)
    if not montant or not p then return false end
    raison = raison or GetCurrentResourceName()

    if Bridge.Framework == 'esx' then
        p.addAccountMoney(COMPTES_ESX[compte] or compte, montant, raison)
        return true
    elseif Bridge.Framework == 'qbox' then
        return exports.qbx_core:AddMoney(source, compte, montant, raison) ~= false
    end
    return p.Functions.AddMoney(compte, montant, raison) ~= false
end

function Bridge.RemoveMoney(source, compte, montant, raison)
    montant = montantValide(montant)
    local p = joueurBrut(source)
    if not montant or not p then return false end
    if Bridge.GetMoney(source, compte) < montant then return false end
    raison = raison or GetCurrentResourceName()

    if Bridge.Framework == 'esx' then
        p.removeAccountMoney(COMPTES_ESX[compte] or compte, montant, raison)
        return true
    elseif Bridge.Framework == 'qbox' then
        return exports.qbx_core:RemoveMoney(source, compte, montant, raison) ~= false
    end
    return p.Functions.RemoveMoney(compte, montant, raison) ~= false
end

-- Inventaire ---------------------------------------------------------------------------
-- Bridge.AddItem(source, item, quantite) → true / false
-- Ordre : qs-inventory, ox_inventory, puis l'inventaire du framework.

local function demarree(nom) return GetResourceState(nom) == 'started' end

function Bridge.AddItem(source, item, quantite)
    quantite = math.floor(tonumber(quantite) or 0)
    if quantite <= 0 or type(item) ~= 'string' then return false end

    if demarree('qs-inventory') then
        return exports['qs-inventory']:AddItem(source, item, quantite) ~= false
    elseif demarree('ox_inventory') then
        if not exports.ox_inventory:CanCarryItem(source, item, quantite) then return false end
        return exports.ox_inventory:AddItem(source, item, quantite) == true
    end

    local p = joueurBrut(source)
    if not p then return false end

    if Bridge.Framework == 'esx' then
        if p.canCarryItem and not p.canCarryItem(item, quantite) then return false end
        p.addInventoryItem(item, quantite)
        return true
    end
    -- QBCore (Qbox utilise ox_inventory, traité plus haut)
    return p.Functions.AddItem(item, quantite) ~= false
end
