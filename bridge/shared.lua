-- Bridge — détection du framework (QBCore, Qbox ou ESX)
-- Tout le code de la ressource passe par Bridge : il ne dépend d'aucun framework.

Bridge = {}

local function demarree(ressource)
    local etat = GetResourceState(ressource)
    return etat == 'started' or etat == 'starting'
end

local function detecter()
    local force = Config.Framework
    if force and force ~= 'auto' then
        return force
    end
    -- Qbox en premier : qbx_core se présente aussi comme 'qb-core' pour la compatibilité
    if demarree('qbx_core') then return 'qbox' end
    if demarree('es_extended') then return 'esx' end
    if demarree('qb-core') then return 'qbcore' end
    return nil
end

Bridge.Framework = detecter()

if not Bridge.Framework then
    print(('^1[%s] Aucun framework détecté (qbx_core, es_extended ou qb-core). '
        .. 'Démarre-le avant cette ressource dans server.cfg.^0'):format(GetCurrentResourceName()))
elseif Config.Debug then
    print(('[%s] framework détecté : %s'):format(GetCurrentResourceName(), Bridge.Framework))
end
