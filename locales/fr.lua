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
    items_manques  = 'Non remis (inventaire plein) : %s',
    rappel         = 'Votre récompense VIP du jour vous attend : /%s',
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
