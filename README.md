# UniHive — Flutter app (demo)

The UniHive web experience (unihive.shop) rebuilt as a native Android/iOS app.
This is a working demo with sample data that mirrors the live site.

## What's inside

| Web (unihive.shop) | App |
|---|---|
| Top nav: Home · Marketplace · My shop + icons | Bottom tabs: Home · Marketplace · The Buzz · My shop · Cart; top bar keeps theme, messages, wishlist, cart |
| Hero "Built by us. For us." + Start Shopping / Open Your Shop + Goods & Buzz pill | Auto-sliding hero carousel with the same CTAs and toggle |
| TIP strip (Little code, PickUp Mtaani, follow shops) | Rotating TIP bar |
| Featured Shops masonry, Follow + share, rating | Two-column staggered grid, Follow state, shop pages |
| Official Partners (Smirnoff, Red Bull, Little, Siwaka, Charge24, Harrison's) | Horizontal partner carousel |
| Browse Categories (Textbooks, Electronics, Stationery, Study Materials) | Tappable category tiles → filtered marketplace |
| /studentmarketplace: search, promo, categories, product cards, Shuffle, Load More | Same, with category chips instead of a sidebar |
| /services "The Buzz": events, Tickets on Little, "It happened" | Buzz tab with event card, ticket link, past events |
| /cart: qty, wishlist, Order Summary, green checkout | Cart → Checkout (PickUp Mtaani / meet seller / doorstep, M-Pesa number) → Order placed |
| /myshop: stats, Customize, Add Product, Terms, Products / Services / Orders | Seller dashboard + working Add Product form that publishes to the marketplace |
| Messages, wishlist, light/dark switch | All included |

**Brand colours** (taken from the site's CSS)

- Background `#040B08` · Header `#06130D` · Cards `#0A1A12`
- Gold accent `#E7C65F` · Text on gold `#113B1E`
- Checkout green `#16A34A`
- Fonts: Playfair Display (serif headings), Open Sans (body), Unbounded (The Buzz)

```
lib/
  main.dart            app entry, theme switching
  theme.dart           colours, fonts, component styles
  data/models.dart     Shop, Product, Partner, HiveEvent, CartLine
  data/mock_data.dart  sample data copied from the live site  ← swap for Supabase
  state/app_state.dart cart, wishlist, follows, listings, orders
  widgets/common.dart  product card, shop card, TIP bar, Goods/Buzz toggle…
  screens/             splash, shell, home, marketplace, product, shop, buzz,
                       cart + checkout, my_shop + add product, wishlist, messages
assets/icon/           launcher icon, adaptive icon, splash logo
```

---

## 1. Run it on your phone (≈15 min the first time)

1. Install **Flutter**: https://docs.flutter.dev/get-started/install. Pick your OS, choose "Android", and follow the steps. They install Android Studio and the Android SDK.
2. Check your setup with `flutter doctor`. Fix anything marked ✗ for Android.
3. In this folder, run the one-time setup:
   ```bash
   bash setup.sh
   ```
   On Windows without Git Bash, run the commands from `setup.sh` one by one in PowerShell. The `perl` lines become manual edits to `android/app/src/main/AndroidManifest.xml`:
   - set `android:label="UniHive"`;
   - add `<uses-permission android:name="android.permission.INTERNET"/>` under `<manifest>`.
4. Connect an Android phone with **USB debugging** on, or start an emulator. Then run:
   ```bash
   flutter run
   ```

## 2. Publish to Google Play

### a) Create an upload key (once, keep it safe forever)
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Create `android/key.properties`:
```
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```
Both files are already in `.gitignore`. Never commit them, and back them up.

### b) Tell Gradle to sign with it
Open `android/app/build.gradle.kts` and make these edits.

At the very top, add the imports, then the code that loads `key.properties`:
```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```
Inside `android { … }`, add the signing config:
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String
    }
}
```
In `buildTypes { release { … } }`, replace `signingConfig = signingConfigs.getByName("debug")` with:
```kotlin
signingConfig = signingConfigs.getByName("release")
```
Also check `applicationId` in the same file. It's set to `shop.unihive.unihive`. You can change it to something like `shop.unihive.app`, but **it can never change after the first upload**.

(If your project has `build.gradle` instead of `.kts`, see https://docs.flutter.dev/deployment/android#configure-signing-in-gradle.)

### c) Build the bundle
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### d) Google Play Console
1. Create a developer account at https://play.google.com/console. There's a one-time US$25 fee and an identity check.
2. **Create app**: enter "UniHive" as the name, choose App, Free.
3. Fill in **App content**:
   - privacy policy URL (e.g. unihive.shop/privacy);
   - ads: No;
   - data safety: the app collects name, phone number and purchase history once real accounts are on;
   - content rating questionnaire. Partner content mentions alcohol (Smirnoff), so answer honestly.
   - target audience: 18+ is simplest because of the alcohol partner and nightlife events.
4. **Store listing**:
   - short and full description;
   - 512×512 icon (`assets/icon/icon.png`, resized);
   - 1024×500 feature graphic;
   - at least 2 phone screenshots (take them with `flutter run` on a phone).
5. **Testing → Closed testing**: upload the `.aab` and add testers. New personal developer accounts must run a closed test with **at least 12 testers for 14 days** before they can publish to Production.
6. **Production → Create release**: upload the `.aab`, then roll out. Review usually takes from a few hours to a few days.

For each update, bump `version:` in `pubspec.yaml` (e.g. `1.0.1+2`; the number after `+` must always go up), rebuild, and upload.

---

## 3. Supabase backend and M-Pesa

The app now has a Supabase schema and Edge Functions for authenticated
registration/sign-in, catalog reads, server-priced order creation, M-Pesa STK
Push, payment callbacks, and payment status checks. Until a Supabase project
and catalog are configured, it remains in demo mode.

### Provision Supabase

1. Create a Supabase project and install the Supabase CLI.
2. Copy the checked-in templates to local-only config files:
   ```sh
   cp config/app.env.example.json config/app.env.json
   cp supabase/functions/.env.example supabase/functions/.env.local
   ```
   Fill `config/app.env.json` with the project URL and **public** anon/publishable
   key. Keep `MPESA_ENABLED=false` and leave payment secrets empty until you
   have rotated credentials and Safaricom has issued the merchant shortcode.
   The copied files are gitignored.
3. Link this folder to the project and apply the database migration:
   ```sh
   supabase login
   supabase link --project-ref YOUR_PROJECT_REF
   supabase db push
   ```
4. Deploy the Edge Functions:
   ```sh
   supabase functions deploy create-order
   supabase functions deploy mpesa-stk-push
   supabase functions deploy mpesa-callback
   supabase functions deploy verify-payment
   ```
5. Add shop and product rows to the new `shops` and `products` tables. Product
   prices are integer KES amounts; the database computes every order total
   from these prices and the selected delivery method.
6. Build the app with the public config file:
   ```sh
   flutter run --dart-define-from-file=config/app.env.json
   flutter build appbundle --release --dart-define-from-file=config/app.env.json
   ```
   The anon/publishable key is public client configuration. Never use a
   service-role key in the app. Supabase supplies `SUPABASE_URL`,
   `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` to deployed Edge
   Functions; do not copy the service-role key into either template.

### M-Pesa secrets and go-live gate

The shared consumer credentials and passkey must be revoked/rotated because
They were exposed in chat. Do not copy the old values into Supabase. Rotate
them with the provider first. Then fill the M-Pesa entries in the ignored
`supabase/functions/.env.local` file and set the variables in deployed
environments with:

```sh
supabase secrets set --env-file supabase/functions/.env.local
```

Only do this after replacing the blank placeholders with valid, rotated
credentials and the real shortcode. For deployment, `MPESA_ENABLED` must remain
`false` until production verification is complete. Never commit the file, put
payment credentials in Flutter `--dart-define` values, or paste secrets into
chat.

The Edge Functions read these server-only secrets:

- `MPESA_ENABLED` — keep `false` until production verification is complete;
- `MPESA_ENVIRONMENT` — `production` or `sandbox`;
- `MPESA_CONSUMER_KEY` and `MPESA_CONSUMER_SECRET` — rotated Daraja app credentials;
- `MPESA_BUSINESS_SHORTCODE` — Safaricom-issued Paybill/Till number;
- `MPESA_TRANSACTION_TYPE` — `CustomerPayBillOnline` or
  `CustomerBuyGoodsOnline`, matching that merchant account;
- `MPESA_PASSKEY` — rotated STK Push passkey;
- `MPESA_CALLBACK_URL` — public HTTPS URL routed to the deployed
  `mpesa-callback` function.

The requested `https://unihive.app/api/payments/mpesa/callback` URL will only
work after that domain is configured to proxy the path to Supabase's
`/functions/v1/mpesa-callback`. Otherwise use the project's HTTPS Edge Function
URL as the Daraja callback. A shortcode has not been issued, so live payments
must remain disabled. The backend returns an explicit unavailable response
instead of silently simulating a live charge. If the STK request times out
after it may have reached Safaricom, the attempt remains blocked to prevent a
duplicate charge; reconcile that attempt against Daraja before retrying.

### Current scope

- The Supabase migration defines shops, products, private user orders, item
  price snapshots, and M-Pesa payment records with row-level security.
- Order creation and payment state changes are performed server-side. The
  client cannot choose the charged amount.
- The Flutter app uses Supabase Auth REST and catalog REST APIs when configured;
  demo data remains available otherwise.
- Events, seller onboarding/listing writes, image uploads, and messaging still
  need their own backend functions and data model before production launch.
