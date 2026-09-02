# Carnet de nutrition — notes d'intégration

Appli de suivi nutritionnel personnel (V1 complète + refonte UI/UX), pensée pour être
déployée telle quelle mais aussi facile à reprendre/adapter dans un autre site.

## Ce que contient ce dossier

- **`index.html`** — l'application entière (HTML + CSS + JS, aucune étape de build,
  aucune dépendance npm). Un seul fichier, à ouvrir tel quel ou à servir statiquement.
- **`schema.sql`** — le schéma complet de la base de données (7 tables), à exécuter
  dans Supabase → SQL Editor pour recréer la base ailleurs si besoin.
- **`search-food-edge-function.ts`** — la fonction serveur (Supabase Edge Function)
  qui interroge Open Food Facts pour la recherche d'aliments.

## Architecture technique

- **Frontend** : HTML/CSS/JS pur, sans framework ni bundler. Polices Google Fonts
  (Oswald, Inter, JetBrains Mono) chargées par CDN.
- **Backend** : [Supabase](https://supabase.com) (Postgres hébergé) pour toutes les
  données, appelé directement depuis le navigateur via `supabase-js` (CDN, pas de npm).
- **Recherche d'aliments** : [Open Food Facts](https://world.openfoodfacts.org) via
  une Edge Function Supabase (nécessaire car Open Food Facts bloque les appels
  directs depuis un navigateur).
- **Config** : l'URL du projet Supabase et la clé publique ("anon"/"publishable")
  sont codées en dur tout en haut du `<script>` dans `index.html` :
  ```js
  const SUPABASE_URL = "https://duyqydpogpuureuvbheq.supabase.co";
  const SUPABASE_ANON_KEY = "sb_publishable_...";
  ```
  Si le site cible utilise un projet Supabase différent, il suffit de remplacer
  ces deux valeurs (Supabase → Settings → API) une fois `schema.sql` exécuté sur
  le nouveau projet, et de redéployer la fonction `search-food` dessus aussi.

## ⚠️ Sécurité — à traiter avant intégration publique

L'appli est actuellement **sans compte utilisateur** (usage strictement personnel) :
la sécurité au niveau des lignes (Row Level Security) est désactivée sur les 7 tables,
et la clé publique visible dans le code donne un accès en lecture/écriture à tout le
monde qui la trouve. C'est un compromis acceptable pour un usage perso derrière une
URL non partagée, mais **pas pour une intégration ouverte au public**. Avant de mettre
ça en ligne sur un site avec de vrais visiteurs, il faut réintroduire :
- soit une authentification Supabase + des policies RLS (`auth.uid() = user_id`),
- soit héberger cette base sur un projet Supabase séparé, non exposé publiquement.

## Fonctionnalités (V1 complète)

- **Accueil** : timeline de la semaine, jauges calories/macros avec dépassement,
  journal alimentaire par repas (Petit-déjeuner / Déjeuner / Dîner / Collations / Eau).
- **Saisie** : recherche Open Food Facts + bibliothèque personnelle + création de
  recettes, aliments récents, ajout manuel.
- **Progression** : vue quotidienne/hebdomadaire, camembert par repas, tableau
  nutriments (protéines/glucides/fibres/sucres/lipides), suivi de l'eau, historique.
- **Paramètres** : objectifs (calories, macros, eau, ajustement du jour), bibliothèques
  (aliments/recettes), suivi du poids.

## Base de données — les 7 tables

| Table | Rôle |
|---|---|
| `aliments` | bibliothèque personnelle (valeurs nutritionnelles pour 100g/ml) |
| `recettes` | plats composés |
| `recette_ingredients` | ingrédients d'une recette (aliment + quantité) |
| `journal_entries` | ce qui a été mangé, par jour et par repas |
| `objectifs_quotidiens` | objectifs caloriques/macros/eau, par jour |
| `poids` | suivi du poids corporel |
| `hydratation` | consommation d'eau, horodatée |

Détail complet des colonnes dans `schema.sql`.
