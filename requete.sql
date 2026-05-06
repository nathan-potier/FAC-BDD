



-- 1. Requête portant sur au moins trois tables
-- Objectif : Afficher le pseudo des créateurs, le titre du défi et les hashtags associés.

SELECT u.pseudo, d.titre, h.libelle
FROM UTILISATEUR u
JOIN DEFI d ON u.id_utilisateur = d.id_createur
JOIN TAGUER_DEFI td ON d.id_defi = td.id_defi
JOIN HASHTAG h ON td.id_hashtag = h.id_hashtag;


-- 2. Auto-jointure (Jointure réflexive)
-- Objectif : Trouver toutes les paires d'utilisateurs qui sont "buddies" (suivi mutuel).

SELECT s1.id_suiveur AS utilisateur_A, s1.id_suivi AS utilisateur_B
FROM SUIVRE s1
JOIN SUIVRE s2 ON s1.id_suiveur = s2.id_suivi AND s1.id_suivi = s2.id_suiveur
WHERE s1.id_suiveur < s1.id_suivi; -- Évite les doublons (A-B et B-A)


-- 3. Sous-requête dans le WHERE
-- Objectif : Trouver les utilisateurs qui n'ont encore jamais enregistré de séance.

SELECT pseudo 
FROM UTILISATEUR 
WHERE id_utilisateur NOT IN (
    SELECT DISTINCT id_utilisateur FROM SEANCE
);


-- 4. Sous-requête dans le FROM
-- Objectif : Calculer la moyenne des points des utilisateurs ayant un profil public.

SELECT AVG(points) AS moyenne_points_publics 
FROM (
    SELECT points_engagement AS points 
    FROM UTILISATEUR 
    WHERE profil_visibilite = 'public'
) AS profils_publics;


-- 5. Sous-requête corrélée
-- Objectif : Trouver les séances où la distance est supérieure à la moyenne des 
-- distances de CE MÊME utilisateur.

SELECT s1.id_utilisateur, s1.id_seance, s1.distance
FROM SEANCE s1
WHERE s1.distance > (
    SELECT AVG(s2.distance) 
    FROM SEANCE s2 
    WHERE s1.id_utilisateur = s2.id_utilisateur
);


-- 6. Agrégat nécessitant GROUP BY et HAVING (1/2)
-- Objectif : Trouver les catégories sportives ayant plus de 5 séances enregistrées.

SELECT c.nom_categorie, COUNT(s.id_seance) AS nombre_seances
FROM SEANCE s
JOIN CATEGORIE_SPORTIVE c ON s.id_categorie = c.id_categorie
GROUP BY c.id_categorie, c.nom_categorie
HAVING COUNT(s.id_seance) > 5;


-- 7. Agrégat nécessitant GROUP BY et HAVING (2/2)
-- Objectif : Trouver les défis collectifs ayant accumulé plus de 100km au total.

SELECT d.titre, SUM(s.distance) AS distance_totale
FROM DEFI d
JOIN COMPTABILISER c ON d.id_defi = c.id_defi
JOIN SEANCE s ON c.id_seance = s.id_seance
WHERE d.type_defi = 'collectif'
GROUP BY d.id_defi, d.titre
HAVING SUM(s.distance) > 100;


-- 8. Requête impliquant le calcul de deux agrégats imbriqués
-- Objectif : Calculer la moyenne des vitesses maximales atteintes par chaque utilisateur.

SELECT AVG(max_vitesse_perso) AS moyenne_des_records_vitesse
FROM (
    SELECT MAX(vitesse_max) AS max_vitesse_perso 
    FROM SEANCE 
    GROUP BY id_utilisateur
) AS records_utilisateurs;


-- 9. Jointure externe (LEFT JOIN)
-- Objectif : Lister TOUS les défis (même ceux sans invitations) et compter le nombre 
-- d'invitations envoyées pour chacun.

SELECT d.titre, COUNT(i.id_invite) AS nombre_invitations
FROM DEFI d
LEFT JOIN INVITER i ON d.id_defi = i.id_defi
GROUP BY d.id_defi, d.titre;


-- 10. Condition de totalité avec SOUS-REQUÊTES CORRÉLÉES (Division relationnelle)
-- Objectif : Trouver les utilisateurs qui ont débloqué TOUS les badges existants.

SELECT u.pseudo 
FROM UTILISATEUR u 
WHERE NOT EXISTS (
    SELECT b.id_badge 
    FROM BADGE b 
    WHERE NOT EXISTS (
        SELECT d.id_badge 
        FROM DEBLOQUER d 
        WHERE d.id_utilisateur = u.id_utilisateur 
        AND d.id_badge = b.id_badge
    )
);


-- 11. Condition de totalité ÉQUIVALENTE avec de L'AGRÉGATION
-- Objectif : La même chose, mais en comptant si le nombre de badges débloqués 
-- est égal au nombre total de badges.

SELECT u.pseudo 
FROM UTILISATEUR u
JOIN DEBLOQUER d ON u.id_utilisateur = d.id_utilisateur
GROUP BY u.id_utilisateur, u.pseudo
HAVING COUNT(DISTINCT d.id_badge) = (SELECT COUNT(*) FROM BADGE);


-- 12 & 13. Jeu sur les valeurs NULL
-- L'attribut 'temperature' de SEANCE est optionnel (peut être NULL).
-- 
-- Requête 12 : Compte absolument toutes les séances.

SELECT COUNT(*) AS total_seances FROM SEANCE;


-- Requête 13 : Compte uniquement les séances où la température a été renseignée.
-- (Le résultat sera inférieur si des NULLs sont présents).

SELECT COUNT(temperature) AS seances_avec_temperature FROM SEANCE;

-- MODIFICATION POUR LES RENDRE ÉGALES : 
-- On force une valeur par défaut avec COALESCE si c'est NULL.
-- SELECT COUNT(COALESCE(temperature, 0)) FROM SEANCE;


-- 14. Requête Récursive
-- Objectif : Trouver le plus court chemin social (degré de séparation) 
-- entre l'utilisateur 1 et l'utilisateur 10 via la relation "buddy".

WITH RECURSIVE buddies AS (
    -- Étape 1 : Créer une vue temporaire des "buddies" (suivi mutuel)
    SELECT s1.id_suiveur AS u1, s1.id_suivi AS u2
    FROM SUIVRE s1
    JOIN SUIVRE s2 ON s1.id_suiveur = s2.id_suivi AND s1.id_suivi = s2.id_suiveur
),
chemin(u1, u2, distance) AS (
    -- Cas de base : les buddies directs de l'utilisateur 1 (distance 1)
    SELECT u1, u2, 1
    FROM buddies
    WHERE u1 = 1 
    UNION
    -- Étape récursive : on saute de buddy en buddy en ajoutant +1 à la distance
    SELECT c.u1, b.u2, c.distance + 1
    FROM chemin c
    JOIN buddies b ON c.u2 = b.u1
    WHERE c.distance < 5 -- Sécurité pour éviter les boucles infinies
)
SELECT MIN(distance) AS degre_de_separation
FROM chemin
WHERE u2 = 10;


-- 15. Requête utilisant du FENÊTRAGE (Window functions)
-- Objectif : Identifier pour chaque utilisateur ses 3 records de distance (PR).

SELECT pseudo, distance, rang
FROM (
    SELECT u.pseudo, s.distance, 
           ROW_NUMBER() OVER(PARTITION BY u.id_utilisateur ORDER BY s.distance DESC) as rang
    FROM SEANCE s
    JOIN UTILISATEUR u ON s.id_utilisateur = u.id_utilisateur
) AS classements
WHERE rang <= 3;


-- 16. SECTION 4 : ALGORITHME DE RECOMMANDATION (Filtrage collaboratif)
-- Objectif : Suggérer des défis à l'utilisateur 1 en calculant un "Indice".
-- L'indice augmente d'un point pour chaque "buddy" de l'utilisateur 1 qui y participe.

WITH mes_buddies AS (
    SELECT s1.id_suivi AS id_buddy 
    FROM SUIVRE s1 
    JOIN SUIVRE s2 ON s1.id_suiveur = s2.id_suivi AND s1.id_suivi = s2.id_suiveur
    WHERE s1.id_suiveur = 1
)
SELECT d.titre, COUNT(p.id_utilisateur) AS indice_recommandation
FROM DEFI d
JOIN PARTICIPER p ON d.id_defi = p.id_defi
JOIN mes_buddies mb ON p.id_utilisateur = mb.id_buddy
WHERE d.id_defi NOT IN (SELECT id_defi FROM PARTICIPER WHERE id_utilisateur = 1) 
AND d.date_fin >= CURRENT_DATE
GROUP BY d.id_defi, d.titre
ORDER BY indice_recommandation DESC;


-- 17. Manipulation de dates (Intervalles)
-- Objectif : Afficher la durée de chaque séance en soustrayant le début de la fin.

SELECT id_seance, (date_heure_fin - date_heure_debut) AS duree_seance 
FROM SEANCE;


-- 18. Requête de gestion de progression
-- Objectif : Trouver le pourcentage de complétion d'un défi individuel (ex: Défi n°5)
-- basé sur l'objectif de distance.

SELECT d.titre, d.objectif_valeur, SUM(s.distance) AS distance_actuelle,
       (SUM(s.distance) / d.objectif_valeur) * 100 AS pourcentage_completion
FROM DEFI d
JOIN COMPTABILISER c ON d.id_defi = c.id_defi
JOIN SEANCE s ON c.id_seance = s.id_seance
WHERE d.id_defi = 5 AND d.objectif_type = 'distance'
GROUP BY d.id_defi, d.titre, d.objectif_valeur;


-- 19. Recherche filtrée sur hiérarchie
-- Objectif : Trouver les séances de Cyclisme et de toutes ses sous-catégories (ex: VTT).

SELECT s.id_seance, s.distance, c.nom_categorie
FROM SEANCE s
JOIN CATEGORIE_SPORTIVE c ON s.id_categorie = c.id_categorie
WHERE c.nom_categorie = 'Cyclisme' 
   OR c.id_categorie_parente = (SELECT id_categorie FROM CATEGORIE_SPORTIVE WHERE nom_categorie = 'Cyclisme');


-- 20. Requête complexe croisée
-- Objectif : Quels sont les hashtags les plus populaires dans les séances des 
-- utilisateurs ayant un profil "buddies_masque" ?

SELECT h.libelle, COUNT(ts.id_hashtag) AS popularite
FROM TAGUER_SEANCE ts
JOIN HASHTAG h ON ts.id_hashtag = h.id_hashtag
JOIN SEANCE s ON ts.id_seance = s.id_seance
JOIN UTILISATEUR u ON s.id_utilisateur = u.id_utilisateur
WHERE u.profil_visibilite = 'buddies_masque'
GROUP BY h.libelle
ORDER BY popularite DESC;