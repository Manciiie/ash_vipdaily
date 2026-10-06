Config = {}

-- Langue des textes (fichier locales/<langue>.lua)
Config.Langue = 'fr'

-- Affiche des messages de débogage dans la console F8 / serveur
Config.Debug = false

-- Framework : 'auto' (détection), 'qbcore', 'qbox' ou 'esx'
Config.Framework = 'auto'

-- Ouverture
Config.Commande = 'recompenses'
Config.Touche = ''            -- touche par défaut, '' pour aucune (modifiable par chaque joueur dans Paramètres > Raccourcis)

-- Permissions (le panneau reste ouvert à tous : un non-VIP voit qu'il doit être VIP)
Config.StaffSeulement = false
Config.AcePermission = 'wan.staff'

-- Anti-spam : délai minimum entre deux actions d'un même joueur (ms)
Config.DelaiActions = 1500

-------------------------------------------------------------------------------------
-- Détection du grade VIP
-------------------------------------------------------------------------------------
-- Le VIP est reconnu si AU MOINS UNE des méthodes activées répond oui.

Config.Vip = {
    -- 1) Rôle Discord (lu directement via l'API Discord, sans dépendre d'une autre ressource)
    --    Le token du bot NE VA PAS ici : mettez-le dans server.cfg (jamais envoyé aux clients) :
    --        set ash_vipdaily_bot_token "VOTRE_TOKEN_BOT"
    Discord = {
        Actif = true,
        ServeurId = '000000000000000000',          -- ID du serveur Discord (guild)
        Roles = { '000000000000000000' },          -- ID du/des rôle(s) VIP
    },

    -- 2) Permission ace (pratique pour les tests ou un VIP donné à la main)
    --        add_ace identifier.license:xxxx ash.vip allow
    Ace = 'ash.vip',

    -- 3) Vérification personnalisée (optionnelle) : brancher ici une autre ressource
    --    Exemple : Personnalisee = function(source) return exports['ma_ressource']:EstVip(source) end
    Personnalisee = nil,

    -- Durée de mise en cache du statut VIP (évite d'interroger Discord à chaque ouverture)
    CacheMinutes = 10,
}

-------------------------------------------------------------------------------------
-- Journée et série
-------------------------------------------------------------------------------------

-- Heure (heure du serveur) à laquelle une nouvelle récompense devient disponible
Config.HeureReinitialisation = 6

-- true : il faut se connecter chaque jour pour avancer dans la série (un jour manqué = retour au jour 1)
-- false : la série avance à chaque récupération, même avec des jours manqués
Config.SerieStricte = true

-------------------------------------------------------------------------------------
-- Récompenses : 31 jours (une entrée par jour), le cycle recommence au jour 1 après le jour 31
-- Paliers (gros = true, mis en avant) : jours 7, 14, 21, 28 et 31
-------------------------------------------------------------------------------------
-- argent : { compte = 'cash' | 'bank', montant = nombre }
-- items  : { { nom = 'nom_item', quantite = nombre, label = 'Nom affiché' }, ... }
-- ⚠ Valeurs d'exemple : adaptez les montants et les noms d'items à votre serveur.

Config.Recompenses = {
    { argent = { compte = 'bank', montant = 2000 } }, -- jour 1
    { argent = { compte = 'bank', montant = 2200 } }, -- jour 2
    { argent = { compte = 'bank', montant = 2400 }, items = { { nom = 'water_bottle', quantite = 3, label = "Bouteille d'eau" } } }, -- jour 3
    { argent = { compte = 'bank', montant = 2600 } }, -- jour 4
    { argent = { compte = 'bank', montant = 2800 } }, -- jour 5
    { argent = { compte = 'bank', montant = 3000 }, items = { { nom = 'bandage', quantite = 3, label = 'Bandage' } } }, -- jour 6
    { argent = { compte = 'bank', montant = 10000 }, items = { { nom = 'repairkit', quantite = 1, label = 'Kit de réparation' } }, gros = true }, -- jour 7
    { argent = { compte = 'bank', montant = 3400 } }, -- jour 8
    { argent = { compte = 'bank', montant = 3600 }, items = { { nom = 'sandwich', quantite = 3, label = 'Sandwich' } } }, -- jour 9
    { argent = { compte = 'bank', montant = 3800 } }, -- jour 10
    { argent = { compte = 'bank', montant = 4000 } }, -- jour 11
    { argent = { compte = 'bank', montant = 4200 }, items = { { nom = 'water_bottle', quantite = 3, label = "Bouteille d'eau" } } }, -- jour 12
    { argent = { compte = 'bank', montant = 4400 } }, -- jour 13
    { argent = { compte = 'bank', montant = 12500 }, items = { { nom = 'repairkit', quantite = 2, label = 'Kit de réparation' }, { nom = 'lockpick', quantite = 2, label = 'Crochet' } }, gros = true }, -- jour 14
    { argent = { compte = 'bank', montant = 4800 }, items = { { nom = 'bandage', quantite = 3, label = 'Bandage' } } }, -- jour 15
    { argent = { compte = 'bank', montant = 5000 } }, -- jour 16
    { argent = { compte = 'bank', montant = 5200 } }, -- jour 17
    { argent = { compte = 'bank', montant = 5400 }, items = { { nom = 'sandwich', quantite = 3, label = 'Sandwich' } } }, -- jour 18
    { argent = { compte = 'bank', montant = 5600 } }, -- jour 19
    { argent = { compte = 'bank', montant = 5800 } }, -- jour 20
    { argent = { compte = 'bank', montant = 15000 }, items = { { nom = 'advancedrepairkit', quantite = 1, label = 'Kit de réparation avancé' }, { nom = 'lockpick', quantite = 3, label = 'Crochet' } }, gros = true }, -- jour 21
    { argent = { compte = 'bank', montant = 6200 } }, -- jour 22
    { argent = { compte = 'bank', montant = 6400 } }, -- jour 23
    { argent = { compte = 'bank', montant = 6600 }, items = { { nom = 'bandage', quantite = 3, label = 'Bandage' } } }, -- jour 24
    { argent = { compte = 'bank', montant = 6800 } }, -- jour 25
    { argent = { compte = 'bank', montant = 7000 } }, -- jour 26
    { argent = { compte = 'bank', montant = 7200 }, items = { { nom = 'sandwich', quantite = 3, label = 'Sandwich' } } }, -- jour 27
    { argent = { compte = 'bank', montant = 20000 }, items = { { nom = 'advancedrepairkit', quantite = 2, label = 'Kit de réparation avancé' }, { nom = 'phone', quantite = 1, label = 'Téléphone' } }, gros = true }, -- jour 28
    { argent = { compte = 'bank', montant = 7600 } }, -- jour 29
    { argent = { compte = 'bank', montant = 7800 }, items = { { nom = 'water_bottle', quantite = 3, label = "Bouteille d'eau" } } }, -- jour 30
    { argent = { compte = 'bank', montant = 30000 }, items = { { nom = 'advancedrepairkit', quantite = 3, label = 'Kit de réparation avancé' }, { nom = 'lockpick', quantite = 5, label = 'Crochet' } }, gros = true }, -- jour 31
}

-- Plafond de sécurité : aucun montant au-delà ne sera versé (protège d'une faute de frappe)
Config.MontantMax = 50000

-- Prévenir le VIP à la connexion quand une récompense l'attend
Config.RappelConnexion = true

-- Logs Discord (optionnel) : mettez l'URL du webhook dans server.cfg :
--     set ash_vipdaily_webhook "https://discord.com/api/webhooks/..."
