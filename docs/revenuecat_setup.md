# RevenueCat Setup Guide

## 1) Create products

- Create subscriptions in App Store Connect and Google Play Console:
  - Monthly (`viral_pro_monthly`)
  - Yearly (`viral_pro_yearly`)
- Add an introductory free trial to at least one package.

## 2) Configure RevenueCat

- Create a RevenueCat project.
- Add iOS and Android apps.
- Create entitlement: `premium`.
- Create offering: `default`.
- Attach monthly/yearly packages to `default`.

## 3) App keys

- Set:
  - `REVENUECAT_APPLE_API_KEY`
  - `REVENUECAT_GOOGLE_API_KEY`
- Keep the entitlement identifier exactly `premium`.

## 4) Restore and compliance

- Keep a visible restore button (already included in paywall).
- Link Terms and Privacy from paywall/footer.
