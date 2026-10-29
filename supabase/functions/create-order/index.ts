import {
  adminClient,
  authenticatedUser,
  jsonResponse,
  methodNotAllowed,
  preflightResponse,
} from "../_shared/http.ts";

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const deliveryMethods: ReadonlySet<string> = new Set([
  "pickup",
  "meet_seller",
  "doorstep",
]);

function isDeliveryMethod(value: unknown): value is string {
  return typeof value === "string" && deliveryMethods.has(value);
}

function isOrderItem(
  value: unknown,
): value is { productId: string; quantity: number } {
  if (!value || typeof value !== "object") return false;
  return "productId" in value &&
    typeof value.productId === "string" &&
    uuidPattern.test(value.productId) &&
    "quantity" in value &&
    typeof value.quantity === "number" &&
    Number.isInteger(value.quantity) &&
    value.quantity >= 1 &&
    value.quantity <= 99;
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") return preflightResponse();
  if (request.method !== "POST") return methodNotAllowed();

  try {
    const auth = await authenticatedUser(request);
    if (!auth.ok) return auth.response;

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return jsonResponse({ error: "Request body must be valid JSON" }, 400);
    }

    if (
      !body ||
      typeof body !== "object" ||
      !("items" in body) ||
      !Array.isArray(body.items) ||
      !("deliveryMethod" in body) ||
      !isDeliveryMethod(body.deliveryMethod)
    ) {
      return jsonResponse({
        error: "items and a valid deliveryMethod are required",
      }, 400);
    }
    if (
      body.items.length < 1 ||
      body.items.length > 50 ||
      !body.items.every(isOrderItem)
    ) {
      return jsonResponse({ error: "Order items are invalid" }, 400);
    }

    const { data, error } = await adminClient().rpc("create_order", {
      p_user_id: auth.user.id,
      p_items: body.items,
      p_delivery_method: body.deliveryMethod,
    });
    if (error) {
      console.error(
        JSON.stringify({
          event: "create_order_failed",
          code: error.code ?? "unknown",
        }),
      );
      return jsonResponse({ error: "Unable to create order" }, 400);
    }

    return jsonResponse(data, 201);
  } catch {
    console.error(JSON.stringify({ event: "create_order_internal_error" }));
    return jsonResponse({ error: "Unable to create order" }, 500);
  }
});
