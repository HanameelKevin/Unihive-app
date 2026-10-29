import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { getMpesaConfig } from "./mpesa-config.mjs";

const projectRoot = new URL("../../../", import.meta.url);

const enabledEnvironment = {
  MPESA_ENABLED: "true",
  MPESA_ENVIRONMENT: "production",
  MPESA_CONSUMER_KEY: "key",
  MPESA_CONSUMER_SECRET: "secret",
  MPESA_BUSINESS_SHORTCODE: "123456",
  MPESA_TRANSACTION_TYPE: "CustomerPayBillOnline",
  MPESA_PASSKEY: "passkey",
  MPESA_CALLBACK_URL: "https://unihive.app/api/payments/mpesa/callback",
};

test("keeps M-Pesa disabled until explicitly enabled", () => {
  assert.equal(getMpesaConfig({}), null);
});

test("does not silently enable payments when required secrets are missing", () => {
  assert.throws(
    () => getMpesaConfig({ MPESA_ENABLED: "true" }),
    /Missing required M-Pesa configuration/,
  );
});

test("requires HTTPS callback URLs", () => {
  assert.throws(
    () =>
      getMpesaConfig({
        ...enabledEnvironment,
        MPESA_CALLBACK_URL: "http://unihive.app/callback",
      }),
    /must use HTTPS/,
  );
});

test("returns production settings only when the complete server config is present", () => {
  assert.deepEqual(getMpesaConfig(enabledEnvironment), {
    environment: "production",
    consumerKey: "key",
    consumerSecret: "secret",
    businessShortcode: "123456",
    transactionType: "CustomerPayBillOnline",
    passkey: "passkey",
    callbackUrl: "https://unihive.app/api/payments/mpesa/callback",
    apiBaseUrl: "https://api.safaricom.co.ke",
  });
});

test("provides all M-Pesa server variables as disabled, empty secret placeholders", () => {
  const env = readFileSync(
    fileURLToPath(new URL("supabase/functions/.env.example", projectRoot)),
    "utf8",
  );
  const parsed = Object.fromEntries(
    env.split(/\r?\n/)
      .filter((line) => line && !line.startsWith("#"))
      .map((line) => {
        const separator = line.indexOf("=");
        return [line.slice(0, separator), line.slice(separator + 1)];
      }),
  );

  for (
    const name of [
      "MPESA_ENABLED",
      "MPESA_ENVIRONMENT",
      "MPESA_CONSUMER_KEY",
      "MPESA_CONSUMER_SECRET",
      "MPESA_BUSINESS_SHORTCODE",
      "MPESA_TRANSACTION_TYPE",
      "MPESA_PASSKEY",
      "MPESA_CALLBACK_URL",
    ]
  ) {
    assert.ok(name in parsed, `${name} must be present in the server template`);
  }
  assert.equal(parsed.MPESA_ENABLED, "false");
  assert.equal(parsed.MPESA_CONSUMER_KEY, "");
  assert.equal(parsed.MPESA_CONSUMER_SECRET, "");
  assert.equal(parsed.MPESA_BUSINESS_SHORTCODE, "");
  assert.equal(parsed.MPESA_PASSKEY, "");
});

test("Flutter config template exposes only public Supabase build variables", () => {
  const config = JSON.parse(
    readFileSync(
      fileURLToPath(
        new URL("config/app.env.example.json", projectRoot),
      ),
      "utf8",
    ),
  );
  assert.deepEqual(Object.keys(config).sort(), [
    "SUPABASE_ANON_KEY",
    "SUPABASE_URL",
  ]);
  assert.match(
    config.SUPABASE_URL,
    /^https:\/\/YOUR_PROJECT_REF\.supabase\.co$/,
  );
  assert.match(config.SUPABASE_ANON_KEY, /^YOUR_PUBLIC_/);
});
