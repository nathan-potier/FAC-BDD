import os
import csv
import random
from datetime import timedelta, date
from faker import Faker

fake = Faker('fr_FR')

# Création du dossier CSV s'il n'existe pas
os.makedirs('CSV', exist_ok=True)

# --- CONFIGURATION DES QUANTITÉS ---
NUM_UTILISATEURS = 50
NUM_DEFIS = 40
NUM_SEANCES = 150

def write_csv(filename, headers, data):
    with open(f'CSV/{filename}.csv', 'w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerow(headers)
        writer.writerows(data)

# ==========================================
# 1. TABLES DE RÉFÉRENCE
# ==========================================

utilisateurs = []
pseudos_utilises = set()
for i in range(1, NUM_UTILISATEURS + 1):
    pseudo = fake.user_name()
    while pseudo in pseudos_utilises:
        pseudo = fake.user_name() + str(random.randint(1, 999))
    pseudos_utilises.add(pseudo)
    
    profil = random.choice(['public', 'buddies_masque'])
    points = random.randint(0, 5000)
    utilisateurs.append([i, pseudo, profil, points])

noms_badges = ["Marathonien", "Sprinteur", "Grimpeur fou", "Lève-tôt", "Oiseau de nuit", "Régularité", "100km club", "Ironman"]
badges = [[i+1, nom, random.randint(50, 1000)] for i, nom in enumerate(noms_badges)]

noms_hashtags = ["running", "trail", "cycling", "swimming", "fitness", "nevergiveup", "morningrun", "nopainnogain", "nature"]
hashtags = [[i+1, nom] for i, nom in enumerate(noms_hashtags)]

categories = [
    [1, "Course à pied", None],
    [2, "Trail", 1], 
    [3, "Cyclisme", None],
    [4, "VTT", 3],   
    [5, "Natation", None]
]

# ==========================================
# 2. TABLES PRINCIPALES
# ==========================================

defis = []
for i in range(1, NUM_DEFIS + 1):
    titre = "Défi " + fake.word().capitalize()
    description = fake.sentence()
    type_defi = random.choice(['individuel', 'collectif'])
    
    date_debut = fake.date_this_year()
    date_fin = date_debut + timedelta(days=random.randint(7, 60))
    
    objectif_type = random.choice(['distance', 'denivele', 'temps', 'jours'])
    objectif_valeur = random.randint(10, 500)
    capacite_max = random.randint(5, 100) if type_defi == 'collectif' else None
    
    # --- TRICHE POUR LES REQUÊTES ---
    if i == 5: # Pour la requête 18 (Progression)
        objectif_type = 'distance'
        type_defi = 'individuel'
        capacite_max = None
        objectif_valeur = 100
    elif i in [6, 7]: # Pour la requête 16 (Algorithme de recommandation)
        date_fin = date(2027, 12, 31) # Forcer à être dans le futur
        type_defi = 'collectif'
        capacite_max = 50

    id_createur = random.randint(1, NUM_UTILISATEURS)
    defis.append([i, titre, description, type_defi, date_debut, date_fin, objectif_type, objectif_valeur, capacite_max, id_createur])

seances = []
for i in range(1, NUM_SEANCES + 1):
    debut = fake.date_time_this_year()
    fin = debut + timedelta(minutes=random.randint(20, 240))
    distance = round(random.uniform(2.0, 42.0), 2)
    denivele = random.randint(0, 1500)
    v_max = round(random.uniform(10.0, 35.0), 2)
    v_moy = round(v_max * 0.7, 2)
    fc_min = random.randint(60, 90)
    fc_max = random.randint(160, 195)
    fc_moy = random.randint(fc_min, fc_max)
    calories = random.randint(200, 1500)
    cadence = random.randint(80, 180)
    
    # --- TRICHE POUR REQUÊTE 12/13 (NULLs) ---
    temperature = None if random.random() < 0.2 else round(random.uniform(-5.0, 35.0), 1)
    
    id_utilisateur = random.randint(1, NUM_UTILISATEURS)
    
    # --- TRICHE POUR REQUÊTE 18 ---
    if i in [1, 2, 3]: # Les 3 premières séances appartiennent à l'utilisateur 1 (pour le défi 5)
        id_utilisateur = 1
        distance = 25.0

    id_categorie = random.randint(1, len(categories))
    seances.append([i, debut, fin, distance, denivele, v_max, v_moy, fc_min, fc_moy, fc_max, calories, temperature, cadence, id_utilisateur, id_categorie])

# ==========================================
# 3. TABLES DE LIAISON
# ==========================================

# --- TRICHE POUR REQUÊTE 14 (Récursive) : Création d'un chemin 1 -> 3 -> 4 -> 10 ---
suivre_set = {(1, 2), (2, 1), (1, 3), (3, 1), (3, 4), (4, 3), (4, 10), (10, 4)}
while len(suivre_set) < 80:
    u1, u2 = random.sample(range(1, NUM_UTILISATEURS + 1), 2)
    suivre_set.add((u1, u2))
suivre = list(suivre_set)

inviter_set = set()
while len(inviter_set) < 60:
    u1, u2 = random.sample(range(1, NUM_UTILISATEURS + 1), 2)
    d = random.randint(1, NUM_DEFIS)
    inviter_set.add((u1, u2, d, random.choice(['acceptee', 'refusee', 'sans_reponse'])))
inviter = list(inviter_set)

# --- TRICHE POUR REQUÊTE 16 (Algorithme) ---
participer_set = {(1, 5), (2, 6), (3, 6), (2, 7)} # Les amis (2 et 3) font les défis 6 et 7, mais pas le 1.
while len(participer_set) < 100:
    u = random.randint(1, NUM_UTILISATEURS)
    d = random.randint(1, NUM_DEFIS)
    if not (u == 1 and d in [6, 7]): # On empêche le 1 de faire le 6 et 7
        participer_set.add((u, d))
participer = list(participer_set)

# --- TRICHE POUR REQUÊTE 18 ---
comptabiliser_set = {(1, 5), (2, 5), (3, 5)} # On associe les séances 1, 2, 3 au défi 5
while len(comptabiliser_set) < 80:
    comptabiliser_set.add((random.randint(1, NUM_SEANCES), random.randint(1, NUM_DEFIS)))
comptabiliser = list(comptabiliser_set)

eligible_set = set()
while len(eligible_set) < 50:
    eligible_set.add((random.randint(1, NUM_DEFIS), random.randint(1, len(categories))))
eligible = list(eligible_set)

taguer_seance_set = set()
while len(taguer_seance_set) < 100:
    taguer_seance_set.add((random.randint(1, NUM_SEANCES), random.randint(1, len(hashtags))))
taguer_seance = list(taguer_seance_set)

taguer_defi_set = set()
while len(taguer_defi_set) < 50:
    taguer_defi_set.add((random.randint(1, NUM_DEFIS), random.randint(1, len(hashtags))))
taguer_defi = list(taguer_defi_set)

# --- TRICHE POUR REQUÊTES 10 & 11 (Totalité) ---
debloquer_set = {(1, b) for b in range(1, len(badges) + 1)} # L'utilisateur 1 débloque TOUT
while len(debloquer_set) < 70:
    debloquer_set.add((random.randint(1, NUM_UTILISATEURS), random.randint(1, len(badges))))
debloquer = list(debloquer_set)

# ==========================================
# 4. ÉCRITURE DES FICHIERS CSV
# ==========================================
write_csv('utilisateur', ['id_utilisateur', 'pseudo', 'profil_visibilite', 'points_engagement'], utilisateurs)
write_csv('badge', ['id_badge', 'nom_badge', 'points_requis'], badges)
write_csv('hashtag', ['id_hashtag', 'libelle'], hashtags)
write_csv('categorie_sportive', ['id_categorie', 'nom_categorie', 'id_categorie_parente'], categories)
write_csv('defi', ['id_defi', 'titre', 'description', 'type_defi', 'date_debut', 'date_fin', 'objectif_type', 'objectif_valeur', 'capacite_max', 'id_createur'], defis)
write_csv('seance', ['id_seance', 'date_heure_debut', 'date_heure_fin', 'distance', 'denivele_positif', 'vitesse_max', 'vitesse_moyenne', 'fc_min', 'fc_moy', 'fc_max', 'calories', 'temperature', 'cadence', 'id_utilisateur', 'id_categorie'], seances)
write_csv('suivre', ['id_suiveur', 'id_suivi'], suivre)
write_csv('inviter', ['id_inviteur', 'id_invite', 'id_defi', 'statut_invitation'], inviter)
write_csv('participer', ['id_utilisateur', 'id_defi'], participer)
write_csv('comptabiliser', ['id_seance', 'id_defi'], comptabiliser)
write_csv('eligible', ['id_defi', 'id_categorie'], eligible)
write_csv('taguer_seance', ['id_seance', 'id_hashtag'], taguer_seance)
write_csv('taguer_defi', ['id_defi', 'id_hashtag'], taguer_defi)
write_csv('debloquer', ['id_utilisateur', 'id_badge'], debloquer)

print("Succès ! Les fichiers CSV ont été mis à jour avec des données idéales pour les requêtes.")