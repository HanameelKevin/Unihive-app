import { createClient } from "npm:@supabase/supabase-js@2.118.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Cache-Control": "no-store",
};

/** Returns a JSON response with the function's CORS and cache headers. */
export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Handles browser preflight requests without running a function handler. */
export function preflightResponse(): Response {
  return new Response("ok", { headers: corsHeaders });
}

/** Creates the privileged client used only after request authentication. */
export function adminClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) {
    throw new Error("Supabase function secrets are not configured");
  }
  return createClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

/** Validates the bearer token and returns the signed-in Supabase user. */
export async function authenticatedUser(request: Request) {
  const authorization = request.headers.get("Authorization");
  const token = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!token) {
    return {
      ok: false as const,
      response: jsonResponse({ error: "Authentication required" }, 401),
    };
  }

  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !anonKey) {
    throw new Error("Supabase function secrets are not configured");
  }

  const client = createClient(url, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data, error } = await client.auth.getUser(token);
  if (error || !data.user) {
    return {
      ok: false as const,
      response: jsonResponse({ error: "Invalid or expired session" }, 401),
    };
  }
  return { ok: true as const, user: data.user };
}

/** Ensures only the declared methods are accepted. */
export function methodNotAllowed(): Response {
  return jsonResponse({ error: "Method not allowed" }, 405);
}
