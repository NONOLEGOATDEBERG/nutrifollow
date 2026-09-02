// Fonction Supabase Edge : "search-food"
// Rôle : interroger Open Food Facts côté serveur (le navigateur ne peut pas
// le faire directement à cause du blocage CORS d'Open Food Facts), avec
// pagination réelle via l'API search-a-licious.
//
// Déploiement (Supabase CLI) :
//   supabase functions deploy search-food --project-ref <ref-du-projet> --no-verify-jwt
//
// Ou directement depuis le dashboard Supabase → Edge Functions → New Function
// (coller ce contenu dans index.ts), avec "Verify JWT" désactivé — cette
// fonction ne fait que relayer une recherche publique, elle ne touche à
// aucune donnée utilisateur.
//
// Appel côté client :
//   GET {SUPABASE_URL}/functions/v1/search-food?term=<recherche>&page=<n°page>
//   headers: { apikey: <clé publique>, Authorization: `Bearer <clé publique>` }
//   Réponse : { hits: [...produits...], count: <nombre total de résultats> }

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const term = url.searchParams.get("term") || "";
    const page = url.searchParams.get("page") || "1";
    const pageSize = 20;

    // API de recherche moderne d'Open Food Facts (search-a-licious), avec
    // une vraie pagination — plus fiable que l'ancien endpoint cgi/search.pl.
    const offUrl = `https://search.openfoodfacts.org/search?q=${encodeURIComponent(term)}&page_size=${pageSize}&page=${page}&fields=code,product_name,brands,nutriments`;

    const res = await fetch(offUrl, {
      headers: {
        "User-Agent": "CarnetNutritionPerso/1.0 (usage personnel)",
      },
    });

    if (!res.ok) {
      return new Response(JSON.stringify({ error: `Open Food Facts a répondu ${res.status}`, hits: [], count: 0 }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const data = await res.json();

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err), hits: [], count: 0 }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
