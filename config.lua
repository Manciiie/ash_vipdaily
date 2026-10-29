Config = {}

-- Langue des textes (fichier locales/<langue>.lua)
Config.Langue = 'fr'

-- Affiche des messages de débogage dans la console F8 / serveur
Config.Debug = false

-- Framework : 'auto' (détection), 'qbcore', 'qbox' ou 'esx'
Config.Framework = 'auto'

-- Notifications : ash_notify (exports['ash_notify']:SendAlert), ox_lib en secours
--   systeme   : 'ash_notify' ou 'ox_lib'
--   ressource : nom du dossier d'ash_notify sur le serveur (ensure ash_notify AVANT ash_vipdaily)
-- Si ash_notify n'est pas démarrée, ox_lib prend le relais (une ligne jaune l'indique en F8).
Config.Notifications = {
    systeme   = 'ash_notify',
    ressource = 'ash_notify',
    duree     = 5000,   -- ms
    son       = { success = true, error = true, warning = false, info = false },
}

-- Ouverture : la récompense se récupère auprès du PNJ (Config.Pnj).
-- Commande désactivée par défaut. Si vous en mettez une, elle ouvre le panneau pour consulter,
-- mais la récupération reste refusée loin du PNJ (vérifié par le serveur).
Config.Commande = ''
Config.Touche = ''            -- touche de la commande, '' pour aucune (ignorée sans commande)

-------------------------------------------------------------------------------------
-- PNJ des récompenses
-------------------------------------------------------------------------------------
Config.Pnj = {
    Actif = true,                                  -- false : plus de PNJ ni de contrôle de distance
    Modele = 'a_f_y_business_01',
    Coords = vec4(-546.8246, -190.9287, 38.2211, 156.5999),  -- x, y, z (hauteur du joueur debout), orientation
    Scenario = 'WORLD_HUMAN_CLIPBOARD',            -- animation du PNJ, '' pour aucune
    Distance = 2.5,                                -- distance d'interaction (m)
    DistanceApparition = 60.0,                     -- le PNJ n'existe que pour les joueurs à moins de cette distance
    -- Interaction : ox_target s'il est démarré, sinon touche E (texte à l'écran)
    Blip = {
        Actif = true,
        Sprite = 617,                              -- icône : https://docs.fivem.net/docs/game-references/blips/
        Couleur = 27,
        Taille = 0.8,
        Nom = 'Récompenses VIP',
    },
}

-- Permissions (le panneau reste ouvert à tous : un non-VIP voit qu'il doit être VIP)
Config.StaffSeulement = false
Config.AcePermission = 'wan.staff'

-- Anti-spam : délai minimum entre deux actions d'un même joueur (ms)
Config.DelaiActions = 1500
Config.DelaiOuverture = 1000  -- entre deux ouvertures du panneau

-------------------------------------------------------------------------------------
-- Détection du grade VIP
-------------------------------------------------------------------------------------
-- Le VIP est reconnu si AU MOINS UNE des méthodes activées répond oui.

Config.Vip = {
    -- 1) ash_newplayers (recommandé) : c'est lui qui lit le rôle VIP Discord pour tout le serveur
    --    (convars wan_discord_*), avec son propre cache. Mettre '' pour ne pas l'utiliser.
    Ressource = 'ash_newplayers',

    -- 2) Rôle Discord lu directement par ash_vipdaily (seulement si ash_newplayers n'est pas utilisé)
    --    Le token du bot NE VA PAS ici : mettez-le dans server.cfg (jamais envoyé aux clients) :
    --        set ash_vipdaily_bot_token "VOTRE_TOKEN_BOT"
    Discord = {
        Actif = false,                             -- doublon d'ash_newplayers : à activer seulement sans lui
        ServeurId = '000000000000000000',          -- ID du serveur Discord (guild)
        Roles = { '000000000000000000' },          -- ID du/des rôle(s) VIP
    },

    -- 3) Permission ace (pratique pour les tests ou un VIP donné à la main)
    --        add_ace identifier.license:xxxx ash.vip allow
    Ace = 'ash.vip',

    -- 4) Vérification personnalisée (optionnelle) : brancher ici une autre ressource
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
Config.RappelConnexion = false

-- Logs Discord (optionnel) : mettez l'URL du webhook dans server.cfg :
--     set ash_vipdaily_webhook "https://discord.com/api/webhooks/..."
