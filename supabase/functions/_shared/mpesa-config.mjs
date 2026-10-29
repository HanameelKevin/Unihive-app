const REQUIRED_SETTINGS = [
  "MPESA_ENVIRONMENT",
  "MPESA_CONSUMER_KEY",
  "MPESA_CONSUMER_SECRET",
  "MPESA_BUSINESS_SHORTCODE",
  "MPESA_TRANSACTION_TYPE",
  "MPESA_PASSKEY",
  "MPESA_CALLBACK_URL",
];

/**
 * @typedef {{
 *   environment: 'production' | 'sandbox',
 *   consumerKey: string,
 *   consumerSecret: string,
 *   businessShortcode: string,
 *   transactionType: 'CustomerPayBillOnline' | 'CustomerBuyGoodsOnline',
 *   passkey: string,
 *   callbackUrl: string,
 *   apiBaseUrl: string
 * }} MpesaConfig
 */

/**
 * @param {Record<string, string | undefined>} env
 * @returns {MpesaConfig | null}
 */
export function getMpesaConfig(env) {
  if (env.MPESA_ENABLED !== "true") return null;

  const missing = REQUIRED_SETTINGS.filter((name) => !env[name]?.trim());
  if (missing.length > 0) {
    throw new Error(
      `Missing required M-Pesa configuration: ${missing.join(", ")}`,
    );
  }

  const environment = env.MPESA_ENVIRONMENT;
  if (environment !== "production" && environment !== "sandbox") {
    throw new Error("MPESA_ENVIRONMENT must be production or sandbox");
  }

  if (!/^\d+$/.test(env.MPESA_BUSINESS_SHORTCODE)) {
    throw new Error("MPESA_BUSINESS_SHORTCODE must contain digits only");
  }

  if (
    !["CustomerPayBillOnline", "CustomerBuyGoodsOnline"].includes(
      env.MPESA_TRANSACTION_TYPE,
    )
  ) {
    throw new Error(
      "MPESA_TRANSACTION_TYPE must match the merchant account type",
    );
  }

  let callbackUrl;
  try {
    callbackUrl = new URL(env.MPESA_CALLBACK_URL);
  } catch {
    throw new Error("MPESA_CALLBACK_URL must be an absolute HTTPS URL");
  }
  if (callbackUrl.protocol !== "https:") {
    throw new Error("MPESA_CALLBACK_URL must use HTTPS");
  }

  return {
    environment,
    consumerKey: env.MPESA_CONSUMER_KEY,
    consumerSecret: env.MPESA_CONSUMER_SECRET,
    businessShortcode: env.MPESA_BUSINESS_SHORTCODE,
    transactionType: env.MPESA_TRANSACTION_TYPE,
    passkey: env.MPESA_PASSKEY,
    callbackUrl: callbackUrl.toString(),
    apiBaseUrl: environment === "production"
      ? "https://api.safaricom.co.ke"
      : "https://sandbox.safaricom.co.ke",
  };
}
