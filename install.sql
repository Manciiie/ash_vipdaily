-- ash_vipdaily — à importer une fois (la table est aussi créée automatiquement au démarrage)

CREATE TABLE IF NOT EXISTS `ash_vipdaily_joueurs` (
    `identifiant`   VARCHAR(64) NOT NULL,
    `dernier_jour`  VARCHAR(10) NULL,          -- jour de la dernière récupération (AAAA-MM-JJ)
    `serie`         INT NOT NULL DEFAULT 0,     -- jours consécutifs
    `total`         INT NOT NULL DEFAULT 0,     -- récompenses récupérées au total
    `maj_le`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifiant`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
