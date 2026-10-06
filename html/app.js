// Interface NUI — thème ASH
(() => {
    const app = document.getElementById('app');
    const ressource = typeof GetParentResourceName === 'function'
        ? GetParentResourceName()
        : 'ash_vipdaily';

    let visible = false;
    let etat = null;          // dernier état envoyé par le serveur
    let selection = null;     // jour affiché dans le bloc de gauche (null = jour en cours)
    let secondes = 0;
    let minuteur = null;

    const formatArgent = new Intl.NumberFormat('fr-FR');

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

    function el(balise, classe, contenu) {
        const element = document.createElement(balise);
        if (classe) element.className = classe;
        if (contenu !== undefined) element.textContent = contenu;
        return element;
    }

    function duree(total) {
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = total % 60;
        return `${h}h ${String(m).padStart(2, '0')}m ${String(s).padStart(2, '0')}s`;
    }

    function montant(lot) {
        return lot && lot.argent ? `${formatArgent.format(lot.argent.montant)} $` : '—';
    }

    // Jour « à récupérer » (ou de demain si déjà récupéré)
    const jourEnCours = () => (etat ? etat.jourCycle : 1);
    const nbJours = () => (etat && etat.recompenses ? etat.recompenses.length : 0);

    // Le minuteur ne tourne que panneau ouvert -----------------------------------------
    function demarrerMinuteur() {
        clearInterval(minuteur);
        majTemps();
        minuteur = setInterval(() => {
            secondes = Math.max(0, secondes - 1);
            majTemps();
        }, 1000);
    }

    function majTemps() {
        texte('info-reinit', etat && etat.disponible ? 'Disponible' : duree(secondes));
        if (etat && etat.vip && !etat.disponible && selection === null) {
            texte('sous-bouton', `Prochaine récompense dans ${duree(secondes)}`);
        }
    }

    // Calendrier ---------------------------------------------------------------------------
    function construireGrille() {
        const grille = document.getElementById('grille');
        grille.replaceChildren();
        const courant = jourEnCours();

        etat.recompenses.forEach((lot, i) => {
            const numero = i + 1;
            const carte = el('button', 'vip-jour');
            carte.type = 'button';
            if (lot.gros) carte.classList.add('gros');
            if (numero < courant) carte.classList.add('passe');
            if (numero === courant) carte.classList.add('courant');
            if (numero === selection) carte.classList.add('selection');

            carte.appendChild(el('span', 'vip-num', lot.gros ? `J${numero} ★` : `J${numero}`));
            carte.appendChild(el('span', 'vip-montant', montant(lot)));
            if (lot.items && lot.items.length) {
                carte.appendChild(el('span', 'vip-plus', `+${lot.items.length}`));
                carte.title = lot.items.map((it) => `${it.quantite}× ${it.label}`).join(', ');
            }

            carte.addEventListener('click', () => {
                selection = numero === courant || numero === selection ? null : numero;
                rendre();
            });
            grille.appendChild(carte);
        });
        texte('nb-jours', String(nbJours()));
    }

    // Bloc récompense -------------------------------------------------------------------
    function construireHero() {
        const courant = jourEnCours();
        const numero = selection ?? courant;
        const lot = etat.recompenses[numero - 1] || {};
        const hero = document.getElementById('hero');
        const enApercu = selection !== null;

        hero.classList.toggle('gros', !!lot.gros);
        hero.classList.toggle('verrouille', !etat.vip);
        document.getElementById('hero-badge').hidden = !lot.gros;

        let etiquette = 'Récompense du jour';
        if (enApercu) etiquette = numero < courant ? 'Déjà passé' : 'Aperçu';
        else if (etat.dejaRecupere) etiquette = 'Demain';
        texte('hero-etiquette', etiquette);

        texte('hero-num', `Jour ${numero}`);
        texte('hero-sur', `/ ${nbJours()}`);
        texte('hero-montant', montant(lot));
        texte('hero-compte', lot.argent ? (lot.argent.compte === 'cash' ? 'En liquide' : 'Sur le compte bancaire') : '');

        const puces = document.getElementById('hero-items');
        puces.replaceChildren();
        (lot.items || []).forEach((it) => {
            const puce = el('span', 'vip-puce');
            puce.appendChild(el('b', null, `${it.quantite}×`));
            puce.appendChild(document.createTextNode(it.label));
            puces.appendChild(puce);
        });

        // Progression : jours déjà validés dans le cycle
        const faits = Math.max(0, courant - 1);
        texte('hero-progression', `${faits} / ${nbJours()}`);
        document.getElementById('hero-barre').style.width = `${(faits / Math.max(1, nbJours())) * 100}%`;

        const reperes = document.getElementById('hero-reperes');
        reperes.replaceChildren();
        etat.recompenses.forEach((l, i) => {
            if (!l.gros) return;
            const repere = el('i', 'vip-repere');
            if (i + 1 <= faits) repere.classList.add('atteint');
            repere.style.left = `${((i + 1) / nbJours()) * 100}%`;
            reperes.appendChild(repere);
        });

        // Prochain palier
        const palier = document.getElementById('hero-palier');
        palier.replaceChildren();
        const prochain = etat.recompenses.findIndex((l, i) => l.gros && i + 1 >= courant);
        if (prochain >= 0) {
            // Déjà récupéré aujourd'hui : le jour « en cours » est celui de demain
            const ecart = prochain + 1 - courant + (etat.dejaRecupere ? 1 : 0);
            palier.appendChild(document.createTextNode('Prochain palier : '));
            palier.appendChild(el('b', null, `Jour ${prochain + 1}`));
            palier.appendChild(document.createTextNode(ecart === 0 ? ' — c\'est aujourd\'hui !' : ecart === 1 ? ' — demain' : ` — dans ${ecart} jours`));
        }

        // Bouton
        const bouton = document.getElementById('btn-recuperer');
        if (!etat.vip) {
            bouton.disabled = true;
            texte('btn-texte', '🔒 Réservé aux VIP');
            texte('sous-bouton', 'Obtenez le grade VIP pour débloquer les récompenses.');
        } else if (enApercu) {
            bouton.disabled = true;
            texte('btn-texte', numero < courant ? 'Déjà récupéré' : `Disponible au jour ${numero}`);
            texte('sous-bouton', 'Cliquez à nouveau pour revenir au jour en cours.');
        } else if (etat.disponible) {
            bouton.disabled = false;
            texte('btn-texte', 'Récupérer');
            texte('sous-bouton', 'Votre récompense vous attend.');
        } else {
            bouton.disabled = true;
            texte('btn-texte', '✓ Récupérée aujourd\'hui');
            texte('sous-bouton', `Prochaine récompense dans ${duree(secondes)}`);
        }
    }

    function construireSerie() {
        texte('info-joueur', etat.joueur);
        texte('info-vip', etat.vip ? 'VIP' : 'Non VIP');
        texte('info-serie', `${etat.serie} jour${etat.serie > 1 ? 's' : ''}`);
        texte('info-total', String(etat.total));
    }

    function rendre() {
        if (!etat) return;
        construireGrille();
        construireHero();
        construireSerie();
    }

    function appliquer(nouvelEtat) {
        if (!nouvelEtat) return;
        etat = nouvelEtat;
        secondes = etat.secondes || 0;
        rendre();
        demarrerMinuteur();
    }

    // Ouverture / fermeture ------------------------------------------------------------
    function afficher(donnees, titre) {
        if (titre) texte('titre', titre);
        selection = null;
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
        if (!etat || !etat.disponible || selection !== null) return;
        bouton.disabled = true;
        const reponse = await envoyer('action', { type: 'recuperer' });
        if (reponse && reponse.ok && reponse.etat) {
            const hero = document.getElementById('hero');
            hero.classList.remove('recupere');
            void hero.offsetWidth; // relance l'animation
            hero.classList.add('recupere');
            appliquer(reponse.etat);
        } else if (etat) {
            bouton.disabled = !etat.disponible;
        }
    });
})();
