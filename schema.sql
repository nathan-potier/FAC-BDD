-- Tables de référence 

CREATE TABLE UTILISATEUR (
    id_utilisateur SERIAL PRIMARY KEY,
    pseudo VARCHAR(50) UNIQUE NOT NULL,
    profil_visibilite VARCHAR(20) DEFAULT 'public' CHECK (profil_visibilite IN ('public', 'buddies_masque')),
    points_engagement INTEGER DEFAULT 0 CHECK (points_engagement >= 0)
);

CREATE TABLE BADGE (
    id_badge SERIAL PRIMARY KEY,
    nom_badge VARCHAR(100) NOT NULL,
    points_requis INTEGER NOT NULL CHECK (points_requis >= 0)
);

CREATE TABLE HASHTAG (
    id_hashtag SERIAL PRIMARY KEY,
    libelle VARCHAR(50) UNIQUE NOT NULL
);

-- La catégorie sportive contient une clé étrangère vers elle-même pour gérer la hiérarchie 
CREATE TABLE CATEGORIE_SPORTIVE (
    id_categorie SERIAL PRIMARY KEY,
    nom_categorie VARCHAR(100) NOT NULL,
    id_categorie_parente INTEGER REFERENCES CATEGORIE_SPORTIVE(id_categorie)
);

-- 2. Tables principales 

CREATE TABLE DEFI (
    id_defi SERIAL PRIMARY KEY,
    titre VARCHAR(100) NOT NULL,
    description TEXT,
    type_defi VARCHAR(20) NOT NULL CHECK (type_defi IN ('individuel', 'collectif')),
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    objectif_type VARCHAR(20) NOT NULL CHECK (objectif_type IN ('distance', 'denivele', 'temps', 'jours')),
    objectif_valeur NUMERIC NOT NULL CHECK (objectif_valeur > 0),
    capacite_max INTEGER CHECK (capacite_max > 0), -- NULL si individuel
    id_createur INTEGER NOT NULL REFERENCES UTILISATEUR(id_utilisateur),
    CONSTRAINT check_dates_defi CHECK (date_fin >= date_debut)
);

CREATE TABLE SEANCE (
    id_seance SERIAL PRIMARY KEY,
    date_heure_debut TIMESTAMP NOT NULL,
    date_heure_fin TIMESTAMP NOT NULL,
    distance NUMERIC NOT NULL CHECK (distance >= 0),
    denivele_positif INTEGER DEFAULT 0 CHECK (denivele_positif >= 0),
    vitesse_max NUMERIC CHECK (vitesse_max >= 0),
    vitesse_moyenne NUMERIC CHECK (vitesse_moyenne >= 0),
    fc_min INTEGER CHECK (fc_min > 0),
    fc_moy INTEGER CHECK (fc_moy > 0),
    fc_max INTEGER CHECK (fc_max > 0),
    calories INTEGER CHECK (calories >= 0),
    temperature NUMERIC,
    cadence INTEGER CHECK (cadence >= 0),
    id_utilisateur INTEGER NOT NULL REFERENCES UTILISATEUR(id_utilisateur),
    id_categorie INTEGER NOT NULL REFERENCES CATEGORIE_SPORTIVE(id_categorie),
    CONSTRAINT check_dates_seance CHECK (date_heure_fin >= date_heure_debut)
);

-- Tables de liaison (pour les associations 0,n - 0,n)

CREATE TABLE SUIVRE (
    id_suiveur INTEGER REFERENCES UTILISATEUR(id_utilisateur),
    id_suivi INTEGER REFERENCES UTILISATEUR(id_utilisateur),
    PRIMARY KEY (id_suiveur, id_suivi),
    CONSTRAINT check_pas_auto_suivi CHECK (id_suiveur != id_suivi)
);

CREATE TABLE INVITER (
    id_inviteur INTEGER REFERENCES UTILISATEUR(id_utilisateur),
    id_invite INTEGER REFERENCES UTILISATEUR(id_utilisateur),
    id_defi INTEGER REFERENCES DEFI(id_defi),
    statut_invitation VARCHAR(20) DEFAULT 'sans_reponse' CHECK (statut_invitation IN ('acceptee', 'refusee', 'sans_reponse')),
    PRIMARY KEY (id_inviteur, id_invite, id_defi)
);

CREATE TABLE PARTICIPER (
    id_utilisateur INTEGER REFERENCES UTILISATEUR(id_utilisateur),
    id_defi INTEGER REFERENCES DEFI(id_defi),
    PRIMARY KEY (id_utilisateur, id_defi)
);

CREATE TABLE COMPTABILISER (
    id_seance INTEGER REFERENCES SEANCE(id_seance),
    id_defi INTEGER REFERENCES DEFI(id_defi),
    PRIMARY KEY (id_seance, id_defi)
);

CREATE TABLE ELIGIBLE (
    id_defi INTEGER REFERENCES DEFI(id_defi),
    id_categorie INTEGER REFERENCES CATEGORIE_SPORTIVE(id_categorie),
    PRIMARY KEY (id_defi, id_categorie)
);

CREATE TABLE TAGUER_SEANCE (
    id_seance INTEGER REFERENCES SEANCE(id_seance),
    id_hashtag INTEGER REFERENCES HASHTAG(id_hashtag),
    PRIMARY KEY (id_seance, id_hashtag)
);

CREATE TABLE TAGUER_DEFI (
    id_defi INTEGER REFERENCES DEFI(id_defi),
    id_hashtag INTEGER REFERENCES HASHTAG(id_hashtag),
    PRIMARY KEY (id_defi, id_hashtag)
);

CREATE TABLE DEBLOQUER (
    id_utilisateur INTEGER REFERENCES UTILISATEUR(id_utilisateur),
    id_badge INTEGER REFERENCES BADGE(id_badge),
    PRIMARY KEY (id_utilisateur, id_badge)
);