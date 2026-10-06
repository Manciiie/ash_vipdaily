// Interface NUI — thème ASH
(() => {
    const app = document.getElementById('app');
    const ressource = typeof GetParentResourceName === 'function'
        ? GetParentResourceName()
        : 'ash_vipdaily';
    let visible = false;
    let secondes = 0;
    let minuteur = null;

    // Envoi d'un message au client Lua (RegisterNUICallback)
    function envoyer(nom, donnees = {}) {
        return fetch(`https://${ressource}/${nom}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(donnees),
        })
            .then((reponse) => reponse.json())
            .catch(() => null);
    }

    // Toujours textContent (jamais innerHTML) pour afficher des données
    function texte(id, valeur) {
        const element = document.getElementById(id);
        if (element) element.textContent = valeur ?? '—';
    }

    function duree(total) {
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = total % 60;
        return `${h}h ${String(m).padStart(2, '0')}m ${String(s).padStart(2, '0')}s`;
    }

    // Le minuteur ne tourne que panneau ouvert
    function demarrerMinuteur() {
        clearInterval(minuteur);
        texte('info-reinit', duree(secondes));
        minuteur = setInterval(() => {
            secondes = Math.max(0, secondes - 1);
            texte('info-reinit', duree(secondes));
            if (etatCourant && !etatCourant.disponible) texte('sous-statut', `Prochaine dans ${duree(secondes)}`);
        }, 1000);
    }

    let etatCourant = null;

    function grille(etat) {
        const conteneur = document.getElementById('grille');
        conteneur.replaceChildren();
        (etat.recompenses || []).forEach((lot, i) => {
            const numero = i + 1;
            const carte = document.createElement('div');
            carte.className = 'vip-jour';
            if (lot.gros) carte.classList.add('gros');
            if (numero === etat.jourCycle) carte.classList.add('courant');
            else if (numero < etat.jourCycle) carte.classList.add('passe');

            const titre = document.createElement('span');
            titre.className = 'vip-num';
            titre.textContent = lot.gros ? `Jour ${numero} ★` : `Jour ${numero}`;
            carte.appendChild(titre);

            (lot.lignes || []).forEach((ligne) => {
                const element = document.createElement('span');
                element.className = 'vip-lot';
                element.textContent = ligne;
                carte.appendChild(element);
            });
            conteneur.appendChild(carte);
        });

        // 31 cases : on fait défiler jusqu'au jour en cours
        const courant = conteneur.querySelector('.vip-jour.courant');
        if (courant) requestAnimationFrame(() => courant.scrollIntoView({ block: 'center' }));
    }

    function appliquer(etat) {
        if (!etat) return;
        etatCourant = etat;
        secondes = etat.secondes || 0;

        grille(etat);
        document.getElementById('bandeau-non-vip').hidden = !!etat.vip;

        const bouton = document.getElementById('btn-recuperer');
        bouton.disabled = !etat.disponible;

        if (!etat.vip) {
            texte('statut', 'Réservé aux VIP');
            texte('sous-statut', 'Obtenez le grade VIP pour débloquer les récompenses.');
        } else if (etat.disponible) {
            texte('statut', `Jour ${etat.jourCycle} / ${(etat.recompenses || []).length} disponible`);
            texte('sous-statut', 'Votre récompense vous attend.');
        } else {
            texte('statut', 'Déjà récupérée aujourd\'hui');
            texte('sous-statut', `Prochaine dans ${duree(secondes)}`);
        }

        texte('info-joueur', etat.joueur);
        texte('info-vip', etat.vip ? 'VIP' : 'Non VIP');
        texte('info-serie', `${etat.serie} jour${etat.serie > 1 ? 's' : ''}`);
        texte('info-total', String(etat.total));
        demarrerMinuteur();
    }

    function afficher(donnees, titre) {
        if (titre) texte('titre', titre);
        appliquer(donnees);
        visible = true;
        app.classList.add('visible');
        app.setAttribute('aria-hidden', 'false');
    }

    function masquer() {
        visible = false;
        clearInterval(minuteur);
        minuteur = null;
        app.classList.remove('visible');
        app.setAttribute('aria-hidden', 'true');
    }

    // Messages du client Lua (SendNUIMessage)
    window.addEventListener('message', (evenement) => {
        const message = evenement.data || {};
        if (message.action === 'ouvrir') afficher(message.donnees, message.titre);
        else if (message.action === 'fermer') masquer();
    });

    // ÉCHAP pour fermer
    document.addEventListener('keydown', (evenement) => {
        if (visible && evenement.key === 'Escape') envoyer('fermer');
    });

    // Onglets
    document.querySelectorAll('.ash-onglet').forEach((onglet) => {
        onglet.addEventListener('click', () => {
            const cible = onglet.dataset.onglet;
            document.querySelectorAll('.ash-onglet').forEach((o) => o.classList.toggle('actif', o === onglet));
            document.querySelectorAll('.ash-page').forEach((p) => p.classList.toggle('actif', p.dataset.page === cible));
        });
    });

    // Récupérer la récompense (le serveur décide de tout)
    const bouton = document.getElementById('btn-recuperer');
    bouton.addEventListener('click', async () => {
        bouton.disabled = true;
        const reponse = await envoyer('action', { type: 'recuperer' });
        if (reponse && reponse.ok && reponse.etat) appliquer(reponse.etat);
        else if (etatCourant) bouton.disabled = !etatCourant.disponible;
    });
})();
