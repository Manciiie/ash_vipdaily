-- ash_vipdaily — optionnel : la table est créée, et complétée en v2.0.0, automatiquement au démarrage

CREATE TABLE IF NOT EXISTS `ash_vipdaily_joueurs` (
    `identifiant`     VARCHAR(64) NOT NULL,          -- licence Rockstar du compte (citizenid avant la v1.3.1)
    `dernier_jour`    VARCHAR(10) NULL,              -- jour du dernier coffre ouvert (AAAA-MM-JJ)
    `serie`           INT NOT NULL DEFAULT 0,        -- jours consécutifs
    `total`           INT NOT NULL DEFAULT 0,        -- coffres ouverts au total
    `nom`             VARCHAR(64) NULL,              -- nom affiché dans le classement (prénom + initiale)
    `meilleure_serie` INT NOT NULL DEFAULT 0,
    `boucliers`       INT NOT NULL DEFAULT 0,        -- boucliers de série en réserve
    `cles`            INT NOT NULL DEFAULT 0,        -- clés du coffre légendaire
    `semaine`         VARCHAR(10) NULL,              -- lundi de la semaine des défis (AAAA-MM-JJ)
    `coffres_semaine` INT NOT NULL DEFAULT 0,
    `temps_semaine`   INT NOT NULL DEFAULT 0,        -- secondes de jeu cette semaine
    `palier_semaine`  INT NOT NULL DEFAULT 0,
    `defis_semaine`   INT NOT NULL DEFAULT 0,        -- défis déjà validés (un bit par défi)
    `maj_le`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifiant`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
