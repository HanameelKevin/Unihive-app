import { getMpesaConfig } from "../_shared/mpesa-config.mjs";
import {
  adminClient,
  authenticatedUser,
  jsonResponse,
  methodNotAllowed,
  preflightResponse,
} from "../_shared/http.ts";
import { darajaAccessToken, sendStkPush } from "../_shared/daraja.ts";

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function normalizeKenyanPhone(value: string): string | null {
  const digits = value.replace(/[\s+()-]/g, "");
  if (/^[17]\d{8}$/.test(digits)) return `254${digits}`;
  if (/^0[17]\d{8}$/.test(digits)) return `254${digits.slice(1)}`;
  if (/^254[17]\d{8}$/.test(digits)) return digits;
  return null;
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") return preflightResponse();
  if (request.method !== "POST") return methodNotAllowed();

  let config;
  try {
    config = getMpesaConfig(Deno.env.toObject());
  } catch (error) {
    console.error(JSON.stringify({
      event: "mpesa_configuration_invalid",
      message: error instanceof Error ? error.message : "unknown",
    }));
    return jsonResponse({
      error: "M-Pesa configuration is incomplete",
      code: "MPESA_CONFIG_INCOMPLETE",
    }, 503);
  }
  if (!config) {
    return jsonResponse({
      error: "M-Pesa payments are not enabled",
      code: "MPESA_DISABLED",
    }, 503);
  }

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
      !("orderId" in body) ||
      typeof body.orderId !== "string" ||
      !uuidPattern.test(body.orderId) ||
      !("phoneNumber" in body) ||
      typeof body.phoneNumber !== "string"
    ) {
      return jsonResponse(
        { error: "orderId and phoneNumber are required" },
        400,
      );
    }

    const phoneNumber = normalizeKenyanPhone(body.phoneNumber);
    if (!phoneNumber) {
      return jsonResponse({ error: "Enter a valid Kenyan M-Pesa number" }, 400);
    }

    const admin = adminClient();
    const { data: order, error: orderError } = await admin
      .from("orders")
      .select("id, total_amount_kes, payment_status")
      .eq("id", body.orderId)
      .eq("user_id", auth.user.id)
      .maybeSingle();

    if (orderError) throw new Error("Unable to load order");
    if (!order) return jsonResponse({ error: "Order not found" }, 404);
    if (order.payment_status !== "pending") {
      return jsonResponse({ error: "Order is not awaiting payment" }, 409);
    }

    const { data: existingPayment, error: existingError } = await admin
      .from("mpesa_payments")
      .select("id, status")
      .eq("order_id", order.id)
      .in("status", ["initiating", "pending", "paid"])
      .maybeSingle();
    if (existingError) throw new Error("Unable to check payment status");
    if (existingPayment) {
      return jsonResponse({
        error: "A payment attempt already exists for this order",
      }, 409);
    }

    const { data: payment, error: insertError } = await admin
      .from("mpesa_payments")
      .insert({
        order_id: order.id,
        user_id: auth.user.id,
        amount_kes: order.total_amount_kes,
        phone_number: phoneNumber,
        status: "initiating",
      })
      .select("id")
      .single();
    if (insertError) {
      if (insertError.code === "23505") {
        return jsonResponse({
          error: "A payment attempt already exists for this order",
        }, 409);
      }
      throw new Error("Unable to create payment attempt");
    }

    const markPaymentFailed = async (description: string) => {
      const { error } = await admin.from("mpesa_payments")
        .update({
          status: "failed",
          result_description: description,
          updated_at: new Date().toISOString(),
        })
        .eq("id", payment.id);
      if (error) {
        console.error(JSON.stringify({ event: "mpesa_attempt_update_failed" }));
      }
    };

    let accessToken: string;
    try {
      accessToken = await darajaAccessToken(config);
    } catch {
      await markPaymentFailed("Daraja authentication failed");
      console.error(JSON.stringify({ event: "mpesa_authentication_failed" }));
      return jsonResponse({ error: "Unable to start M-Pesa payment" }, 502);
    }

    let result: Record<string, unknown>;
    try {
      result = await sendStkPush(config, accessToken, {
        id: order.id,
        amountKes: order.total_amount_kes,
        phoneNumber,
      });
    } catch {
      // The request may have reached Safaricom; keep the attempt active to
      // prevent a second charge while its outcome is unknown.
      console.error(JSON.stringify({ event: "mpesa_stk_outcome_unknown" }));
      return jsonResponse({
        error: "Payment outcome is being checked; do not retry yet",
        code: "PAYMENT_OUTCOME_UNKNOWN",
      }, 503);
    }

    if (
      result.ResponseCode !== "0" ||
      typeof result.MerchantRequestID !== "string" ||
      typeof result.CheckoutRequestID !== "string"
    ) {
      await markPaymentFailed("Daraja did not accept the STK request");
      return jsonResponse({
        error: "M-Pesa could not start the payment prompt",
      }, 502);
    }

    const { error: updateError } = await admin.from("mpesa_payments")
      .update({
        status: "pending",
        merchant_request_id: result.MerchantRequestID,
        checkout_request_id: result.CheckoutRequestID,
        updated_at: new Date().toISOString(),
      })
      .eq("id", payment.id);
    if (updateError) {
      console.error(JSON.stringify({ event: "mpesa_request_ids_save_failed" }));
      return jsonResponse({
        error: "Payment outcome is being checked; do not retry yet",
        code: "PAYMENT_OUTCOME_UNKNOWN",
      }, 503);
    }

    return jsonResponse({ orderId: order.id, status: "pending" }, 202);
  } catch {
    console.error(JSON.stringify({ event: "mpesa_stk_push_failed" }));
    return jsonResponse({ error: "Unable to start M-Pesa payment" }, 502);
  }
});
