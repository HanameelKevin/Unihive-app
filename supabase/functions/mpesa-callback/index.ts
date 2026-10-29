import { getMpesaConfig } from "../_shared/mpesa-config.mjs";
import {
  adminClient,
  jsonResponse,
  methodNotAllowed,
} from "../_shared/http.ts";
import { darajaAccessToken, queryStkPayment } from "../_shared/daraja.ts";

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function callbackValue(items: unknown, name: string): unknown {
  if (!Array.isArray(items)) return undefined;
  const entry = items.find((value) => isRecord(value) && value.Name === name);
  return isRecord(entry) ? entry.Value : undefined;
}

function normalizePhone(value: unknown): string | null {
  if (typeof value !== "string" && typeof value !== "number") return null;
  const digits = `${value}`.replace(/[\s+()-]/g, "");
  if (/^0[17]\d{8}$/.test(digits)) return `254${digits.slice(1)}`;
  if (/^254[17]\d{8}$/.test(digits)) return digits;
  return null;
}

function parseResultCode(value: unknown): number | null {
  const parsed = typeof value === "number"
    ? value
    : typeof value === "string" && /^\d+$/.test(value)
    ? Number(value)
    : Number.NaN;
  return Number.isInteger(parsed) ? parsed : null;
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method !== "POST") return methodNotAllowed();

  let config;
  try {
    config = getMpesaConfig(Deno.env.toObject());
  } catch {
    console.error(
      JSON.stringify({ event: "mpesa_callback_configuration_invalid" }),
    );
    return jsonResponse({ error: "Payment callback is unavailable" }, 503);
  }
  if (!config) {
    return jsonResponse({ error: "Payment callback is unavailable" }, 503);
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ error: "Invalid callback body" }, 400);
  }

  const stkCallback = isRecord(body) &&
      isRecord(body.Body) &&
      isRecord(body.Body.stkCallback)
    ? body.Body.stkCallback
    : null;
  if (
    !stkCallback ||
    typeof stkCallback.CheckoutRequestID !== "string" ||
    typeof stkCallback.MerchantRequestID !== "string" ||
    !Number.isInteger(stkCallback.ResultCode)
  ) {
    return jsonResponse({ error: "Invalid M-Pesa callback" }, 400);
  }

  const admin = adminClient();
  const { data: payment, error: paymentError } = await admin
    .from("mpesa_payments")
    .select("id, order_id, amount_kes, phone_number, status")
    .eq("checkout_request_id", stkCallback.CheckoutRequestID)
    .eq("merchant_request_id", stkCallback.MerchantRequestID)
    .maybeSingle();

  if (paymentError) {
    console.error(JSON.stringify({ event: "mpesa_callback_lookup_failed" }));
    return jsonResponse(
      { error: "Payment callback could not be processed" },
      503,
    );
  }
  if (!payment || payment.status !== "pending") {
    return jsonResponse({ ResultCode: 0, ResultDesc: "Accepted" });
  }

  const resultCode = stkCallback.ResultCode as number;
  const resultDescription = typeof stkCallback.ResultDesc === "string"
    ? stkCallback.ResultDesc.slice(0, 500)
    : "No result description";

  let queryResult: Record<string, unknown>;
  try {
    const accessToken = await darajaAccessToken(config);
    queryResult = await queryStkPayment(
      config,
      accessToken,
      stkCallback.CheckoutRequestID,
    );
  } catch {
    console.error(
      JSON.stringify({ event: "mpesa_callback_daraja_verification_failed" }),
    );
    return jsonResponse({
      error: "Payment verification is temporarily unavailable",
    }, 503);
  }
  if (
    parseResultCode(queryResult.ResultCode) !== resultCode ||
    (typeof queryResult.CheckoutRequestID === "string" &&
      queryResult.CheckoutRequestID !== stkCallback.CheckoutRequestID)
  ) {
    return jsonResponse(
      { error: "Payment verification is still pending" },
      503,
    );
  }

  if (resultCode !== 0) {
    const { error } = await admin.from("mpesa_payments")
      .update({
        status: "failed",
        result_code: resultCode,
        result_description: resultDescription,
        updated_at: new Date().toISOString(),
      })
      .eq("id", payment.id)
      .eq("status", "pending");
    if (error) {
      console.error(
        JSON.stringify({ event: "mpesa_failure_callback_save_failed" }),
      );
      return jsonResponse(
        { error: "Payment callback could not be processed" },
        503,
      );
    }
    return jsonResponse({ ResultCode: 0, ResultDesc: "Accepted" });
  }

  const metadata = isRecord(stkCallback.CallbackMetadata)
    ? stkCallback.CallbackMetadata
    : null;
  const amount = callbackValue(metadata?.Item, "Amount");
  const receiptNumber = callbackValue(metadata?.Item, "MpesaReceiptNumber");
  const phoneNumber = normalizePhone(
    callbackValue(metadata?.Item, "PhoneNumber"),
  );
  if (
    typeof amount !== "number" ||
    amount !== payment.amount_kes ||
    typeof receiptNumber !== "string" ||
    !/^[A-Z0-9]{6,20}$/.test(receiptNumber) ||
    phoneNumber !== payment.phone_number
  ) {
    console.error(
      JSON.stringify({ event: "mpesa_callback_metadata_mismatch" }),
    );
    return jsonResponse(
      { error: "Payment callback could not be verified" },
      400,
    );
  }

  const { data: confirmed, error: confirmError } = await admin.rpc(
    "confirm_mpesa_payment",
    {
      p_payment_id: payment.id,
      p_receipt_number: receiptNumber,
    },
  );
  if (confirmError || confirmed !== true) {
    console.error(
      JSON.stringify({ event: "mpesa_payment_confirmation_failed" }),
    );
    return jsonResponse(
      { error: "Payment callback could not be processed" },
      503,
    );
  }

  return jsonResponse({ ResultCode: 0, ResultDesc: "Accepted" });
});
