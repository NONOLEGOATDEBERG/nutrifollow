-- ============================================================
-- Schéma de base de données — Carnet de nutrition
-- Généré à partir de l'état réel du projet Supabase le 02/09/2026
-- ============================================================
-- Usage : coller ce script dans Supabase → SQL Editor → Run
-- (sur le même projet, ou sur un nouveau projet Supabase si
-- l'intégration se fait avec une base séparée)

-- ALIMENTS : bibliothèque d'aliments
create table aliments (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete cascade,
  nom text not null,
  calories_100 numeric not null,
  proteines_100 numeric not null default 0,
  glucides_100 numeric not null default 0,
  lipides_100 numeric not null default 0,
  fibres_100 numeric not null default 0,
  sucres_100 numeric not null default 0,
  unite text not null default 'g' check (unite in ('g', 'ml', 'unite')),
  code_barres text,
  origine text not null default 'manuel' check (origine in ('manuel', 'externe')),
  created_at timestamptz not null default now()
);

-- RECETTES : plats composés
create table recettes (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete cascade,
  nom text not null,
  created_at timestamptz not null default now()
);

-- Ingrédients d'une recette (table de jointure recette <-> aliment, avec quantité)
create table recette_ingredients (
  id bigint generated always as identity primary key,
  recette_id bigint not null references recettes(id) on delete cascade,
  aliment_id bigint not null references aliments(id) on delete cascade,
  quantite numeric not null
);

-- JOURNAL ALIMENTAIRE : chaque entrée = un aliment OU une recette consigné(e) à un repas donné
create table journal_entries (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete cascade,
  date date not null default current_date,
  type_repas text not null check (type_repas in ('petit-dejeuner', 'dejeuner', 'diner', 'collation')),
  aliment_id bigint references aliments(id) on delete set null,
  recette_id bigint references recettes(id) on delete set null,
  quantite numeric not null,
  created_at timestamptz not null default now(),
  constraint un_seul_type check (
    (aliment_id is not null and recette_id is null) or
    (aliment_id is null and recette_id is not null)
  )
);

-- OBJECTIFS QUOTIDIENS : un objectif de base par jour (reconduit automatiquement
-- côté application tant qu'aucun nouvel objectif n'est saisi pour un jour donné)
create table objectifs_quotidiens (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete cascade,
  date date not null default current_date,
  objectif_kcal numeric not null,
  objectif_proteines numeric not null default 0,
  objectif_glucides numeric not null default 0,
  objectif_lipides numeric not null default 0,
  ajustement_kcal numeric not null default 0,
  objectif_eau_ml numeric not null default 0,
  unique (date)
);

-- SUIVI DU POIDS
create table poids (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete cascade,
  date date not null default current_date,
  valeur_kg numeric not null
);

-- SUIVI DE L'HYDRATATION (chaque ajout rapide = une ligne, horodatée)
create table hydratation (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete cascade,
  quantite_ml numeric not null,
  logged_at timestamptz not null default now()
);

-- ============================================================
-- SÉCURITÉ (IMPORTANT — à lire avant d'intégrer sur un site tiers)
-- ============================================================
-- Sur le projet actuel, la Row Level Security (RLS) a été DÉSACTIVÉE
-- sur les 7 tables ci-dessus : l'appli est strictement personnelle et
-- n'a pas de compte utilisateur, donc n'importe qui disposant de
-- l'URL Supabase + de la clé "anon" (publique par nature) peut lire
-- et écrire toutes les données.
--
-- Si l'intégration sur le site existant doit être accessible
-- publiquement (pas juste pour un usage perso caché derrière une URL
-- obscure), il faut remettre en place une vraie isolation des
-- données AVANT la mise en ligne : réactiver l'authentification
-- Supabase et des policies RLS du type "chacun ne voit que ses
-- propres lignes" (auth.uid() = user_id), ou héberger cette base sur
-- un projet Supabase séparé et non exposé publiquement.
