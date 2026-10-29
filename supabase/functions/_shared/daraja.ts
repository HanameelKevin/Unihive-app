import type { MpesaConfig } from "./mpesa-config.mjs";

function stkTimestamp(now = new Date()): string {
  return now.toISOString().replace(/[-:TZ.]/g, "").slice(0, 14);
}

function stkPassword(config: MpesaConfig, timestamp: string): string {
  return btoa(`${config.businessShortcode}${config.passkey}${timestamp}`);
}

/** Requests a short-lived Daraja OAuth access token without logging credentials. */
export async function darajaAccessToken(config: MpesaConfig): Promise<string> {
  const credentials = btoa(`${config.consumerKey}:${config.consumerSecret}`);
  const response = await fetch(
    `${config.apiBaseUrl}/oauth/v1/generate?grant_type=client_credentials`,
    {
      headers: { Authorization: `Basic ${credentials}` },
      signal: AbortSignal.timeout(10_000),
    },
  );
  const body: unknown = await response.json();
  if (
    !response.ok ||
    !body ||
    typeof body !== "object" ||
    !("access_token" in body) ||
    typeof body.access_token !== "string"
  ) {
    throw new Error("Daraja authentication failed");
  }
  return body.access_token;
}

/** Sends an STK push using the trusted order amount and configured merchant account. */
export async function sendStkPush(
  config: MpesaConfig,
  accessToken: string,
  order: { id: string; amountKes: number; phoneNumber: string },
): Promise<Record<string, unknown>> {
  const timestamp = stkTimestamp();
  const response = await fetch(
    `${config.apiBaseUrl}/mpesa/stkpush/v1/processrequest`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        BusinessShortCode: config.businessShortcode,
        Password: stkPassword(config, timestamp),
        Timestamp: timestamp,
        TransactionType: config.transactionType,
        Amount: order.amountKes,
        PartyA: order.phoneNumber,
        PartyB: config.businessShortcode,
        PhoneNumber: order.phoneNumber,
        CallBackURL: config.callbackUrl,
        AccountReference: `UH-${order.id.slice(0, 12)}`,
        TransactionDesc: "UniHive order",
      }),
      signal: AbortSignal.timeout(10_000),
    },
  );
  const body: unknown = await response.json();
  if (!response.ok || !body || typeof body !== "object") {
    throw new Error("Daraja STK request failed");
  }
  return body as Record<string, unknown>;
}

/** Queries Daraja for a previously accepted STK request. */
export async function queryStkPayment(
  config: MpesaConfig,
  accessToken: string,
  checkoutRequestId: string,
): Promise<Record<string, unknown>> {
  const timestamp = stkTimestamp();
  const response = await fetch(
    `${config.apiBaseUrl}/mpesa/stkpushquery/v1/query`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        BusinessShortCode: config.businessShortcode,
        Password: stkPassword(config, timestamp),
        Timestamp: timestamp,
        CheckoutRequestID: checkoutRequestId,
      }),
      signal: AbortSignal.timeout(10_000),
    },
  );
  const body: unknown = await response.json();
  if (!response.ok || !body || typeof body !== "object") {
    throw new Error("Daraja payment verification failed");
  }
  return body as Record<string, unknown>;
}
