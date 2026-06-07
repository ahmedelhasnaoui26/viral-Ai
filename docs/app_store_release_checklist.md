# App Store Release Checklist

## Product

- Finalize onboarding copy, paywall pricing copy, and sharing CTA wording.
- Verify watermark behavior for free tier and entitlement behavior for paid tier.
- Ensure first-generation success rate target is at least 95% on production backend.

## iOS Build and Compliance

- Set release signing and provisioning profiles.
- Configure app icons, launch screen, and dark mode screenshots.
- Add privacy manifest and required tracking/privacy disclosures.
- Validate all required `Info.plist` usage descriptions before media imports.

## Performance

- Time-to-interactive under 2 seconds on recent iPhones.
- Maintain 60fps feed scroll and interaction path on iPhone 13+ baseline.
- Validate memory usage during repeated generation and share flows.

## Reliability

- Verify retry/backoff behavior for network/API failures.
- Validate graceful empty/error states for feed and generation result polling.
- Confirm fallback handling if Fal/Replicate provider is degraded.

## Analytics and Monetization

- Confirm event taxonomy fires once and with required properties.
- Verify Mixpanel and PostHog receive identical event names.
- Validate RevenueCat offerings, entitlement IDs, and purchase restore flow.

## App Store Optimization

- Title/subtitle and keyword set aligned with top creator intent queries.
- Promo text and screenshots emphasize one-tap image-to-video virality.
- Review in-app event strategy for post-launch growth campaigns.
