import {
  adminClient,
  authenticatedUser,
  jsonResponse,
  methodNotAllowed,
  preflightResponse,
} from "../_shared/http.ts";

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") return preflightResponse();
  if (request.method !== "GET") return methodNotAllowed();

  try {
    const auth = await authenticatedUser(request);
    if (!auth.ok) return auth.response;

    const orderId = new URL(request.url).searchParams.get("orderId");
    if (!orderId || !uuidPattern.test(orderId)) {
      return jsonResponse({ error: "A valid orderId is required" }, 400);
    }

    const { data: order, error } = await adminClient()
      .from("orders")
      .select("id, payment_status")
      .eq("id", orderId)
      .eq("user_id", auth.user.id)
      .maybeSingle();

    if (error) throw new Error("Unable to verify order payment");
    if (!order) return jsonResponse({ error: "Order not found" }, 404);
    return jsonResponse({
      verified: order.payment_status === "paid",
      status: order.payment_status,
    });
  } catch {
    console.error(JSON.stringify({ event: "payment_verification_failed" }));
    return jsonResponse({ error: "Unable to verify payment" }, 500);
  }
});
