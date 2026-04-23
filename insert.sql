-- Tables de référence
\copy UTILISATEUR FROM 'CSV/utilisateur.csv' WITH (FORMAT csv, HEADER);
\copy CATEGORIE_SPORTIVE FROM 'CSV/categorie_sportive.csv' WITH (FORMAT csv, HEADER);
\copy HASHTAG FROM 'CSV/hashtag.csv' WITH (FORMAT csv, HEADER);
\copy BADGE FROM 'CSV/badge.csv' WITH (FORMAT csv, HEADER);

-- Tables principales
\copy DEFI FROM 'CSV/defi.csv' WITH (FORMAT csv, HEADER);
\copy SEANCE FROM 'CSV/seance.csv' WITH (FORMAT csv, HEADER);

-- Tables de liaison
\copy SUIVRE FROM 'CSV/suivre.csv' WITH (FORMAT csv, HEADER);
\copy INVITER FROM 'CSV/inviter.csv' WITH (FORMAT csv, HEADER);
\copy PARTICIPER FROM 'CSV/participer.csv' WITH (FORMAT csv, HEADER);
\copy COMPTABILISER FROM 'CSV/comptabiliser.csv' WITH (FORMAT csv, HEADER);
\copy ELIGIBLE FROM 'CSV/eligible.csv' WITH (FORMAT csv, HEADER);
\copy TAGUER_SEANCE FROM 'CSV/taguer_seance.csv' WITH (FORMAT csv, HEADER);
\copy TAGUER_DEFI FROM 'CSV/taguer_defi.csv' WITH (FORMAT csv, HEADER);
\copy DEBLOQUER FROM 'CSV/debloquer.csv' WITH (FORMAT csv, HEADER);