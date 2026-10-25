Locales = Locales or {}

Locales['fr'] = {
    titre          = 'Récompenses VIP',
    ouvrir         = 'Ouvrir : Récompenses VIP',
    pas_permission = "Vous n'avez pas la permission de faire ça.",
    action_ok      = 'Action effectuée.',
    action_erreur  = "L'action a échoué.",
    trop_rapide    = 'Doucement, réessayez dans un instant.',
    pas_vip        = 'Cette récompense est réservée aux VIP.',
    deja_recupere  = "Vous avez déjà récupéré votre récompense aujourd'hui.",
    inventaire_plein = "Inventaire plein : libérez de la place puis réessayez (rien n'a été perdu).",
    recupere       = 'Jour %d récupéré : %s',
    items_manques  = 'Non remis : %s (signalé au staff)',
    remise_impossible = "La récompense n'a pas pu être remise : réessayez dans un instant (rien n'a été perdu).",
    discord_indisponible = 'Impossible de vérifier votre rôle VIP sur Discord pour le moment, réessayez dans un instant.',
    personnage_non_charge = "Votre personnage n'est pas encore chargé, réessayez dans un instant.",
    rappel         = 'Votre récompense VIP du jour vous attend auprès du PNJ « Récompenses VIP » (point sur la carte).',
    trop_loin      = 'Rendez-vous auprès du PNJ « Récompenses VIP » pour récupérer votre récompense.',
    pnj_interagir  = 'Récompenses VIP',
    gps_pnj        = 'Point GPS placé sur le PNJ « Récompenses VIP ».',
    pnj_touche     = '[E] Récompenses VIP',
    log_titre      = 'Récompense VIP récupérée',
    liquide        = 'Liquide',
    banque         = 'Banque',
}

--- Renvoie le texte traduit, formaté avec les arguments éventuels.
--- Exemple : _L('bienvenue', nomJoueur)
function _L(cle, ...)
    local langue = Locales[Config.Langue] or Locales['fr']
    local texte = langue[cle] or Locales['fr'][cle] or cle
    if select('#', ...) > 0 then
        return texte:format(...)
    end
    return texte
end
