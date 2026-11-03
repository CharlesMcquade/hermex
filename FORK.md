# Hermex fork — operating manual

This is Charles's maintained rev of `uzairansaruzi/hermex`. Upstream stays authoritative for
in-repo conventions (`AGENTS.md`, `CONTRIBUTING.md`, `DEVELOPMENT.md`); this file governs the
**fork workflow**. Read it before doing fork work in this checkout.

## Branch model

- **Fork `master`** (`CharlesMcquade/hermex`) mirrors upstream `master`. Fast-forward syncs
  only — it never diverges, so PRs stay clean and syncs are trivial.
- **`charles/main` is the maintained rev**: upstream `master` + Charles's capabilities
  (Duo conformance, rendering fixes, fork docs, the Verity rebrand). Device builds of
  "Verity" come from here. Keep it linear on top of `master` (cherry-pick / rebase, no
  merge commits).
- **Topic branches** (`issue/…`, `fix/…`) are the PR vehicles, cut from upstream `master`.
  A capability is PR'd *selectively* — when Charles wants it upstreamed — and carried in
  `charles/main` regardless of PR state. When a commit lives in both a topic branch and
  `charles/main` (cherry-picked), re-cherry-pick if the topic branch iterates.

## Sync procedure (occasional, pull-driven)

```zsh
git fetch origin master                          # origin = uzairansaruzi/hermex
git push fork origin/master:master               # fast-forward the mirror
git checkout charles/main && git rebase fork/master
scripts/test-sim 33C8C228-7C6E-42FC-95F4-AAC655B3EB9F   # FULL SUITE GATE
git push fork charles/main
```

Full-suite gate before every push of `charles/main`. After a sync, rebuild + reinstall the
device build if the synced changes touch anything the phone uses.

## Deployment — "Verity" → iPhone Duo (`DCI Duo`, UDID `00008160-000C61023E40000A`)

- Identity lives in gitignored `Config/Local.xcconfig` (never edit `project.pbxproj` or
  `Config/Shared.xcconfig`): `DEVELOPMENT_TEAM = 7QHECSARP2`,
  `APP_BUNDLE_IDENTIFIER = com.charlesmcquade.hermex`,
  `APP_GROUP_IDENTIFIER = group.com.charlesmcquade.hermex`.
- Display name: `APP_DISPLAY_NAME = Hermex` is explicit at project level in
  `project.pbxproj`, so it is overridden on the build command line, not in xcconfig:
  `APP_DISPLAY_NAME="Verity"`. (The rebrand keeps the override mechanism; the name needs
  no `[Dev]` suffix since "Verity" cannot collide with the App Store Hermex.) Same
  mechanism as upstream's `branch-testflight` flow.
- Build + install (Wi-Fi works; both provisioning flags required for a device new to the team):
  ```zsh
  xcodebuild -project HermesMobile.xcodeproj -scheme HermesMobile \
    -destination "platform=iOS,id=00008160-000C61023E40000A" \
    -derivedDataPath .build/DerivedData-device \
    -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
    APP_DISPLAY_NAME="Verity" build
  xcrun devicectl device install app --device 00008160-000C61023E40000A \
    .build/DerivedData-device/Build/Products/Debug-iphoneos/HermesMobile.app
  ```
- `device process launch` requires the phone unlocked; installs don't. Paid team
  (`7QHECSARP2`) → provisioning valid ~1 year, no 7-day re-sign. First sign-in on a fresh
  install: server URL + WebUI password, typed on the phone.

## Testing process

- **Full gate**: `scripts/test-sim 33C8C228-7C6E-42FC-95F4-AAC655B3EB9F` (iPhone 17,
  reference/CI device; ~3,800 tests, ~4 min warm). ALWAYS read the runner's `Checkout:` line —
  a stale cwd silently runs the suite in the wrong clone.
- **Focused**: multi `--only` flags only (`--only HermesMobileTests/A --only …`). A **single**
  `--only` flag selects 0 tests on Xcode 27.1.
- Never share `.build/DerivedData` between a device build and the test runner (the simulator
  test product vanishes → `rm -rf .build/DerivedData`, or use `.build/DerivedData-device` for
  device builds as above).
- **Simulator matrix**:
  - iPhone 17 `33C8C228-7C6E-42FC-95F4-AAC655B3EB9F` — reference/CI parity.
  - iPhone Duo `DFEEFDBC-0C5E-418A-A3B3-0DAA8BCE6123` — pose matrix. Poses are DeviceHub
    toolbar buttons (Closed / Partially Open / Open / Rotate Right); inner display captures
    via `xcrun simctl io <udid> screenshot --display 3` (outer default; black while open).
  - iPad mini (A17 Pro) `AB175AB9-60F3-4C83-BF37-CDBC14952A6F` — 744pt portrait: must SPLIT
    (≥ 700pt threshold).
  - iPad Pro 13-inch `F9A0833F-B376-43E2-B0FC-6BE1FD5BE401` — regular split sanity.
- **Size-class invariant**: `HermesHomeLayout.minimumSplitWidth = 700`. iPhone Duo inner
  portrait (measured **626×890pt**) stacks; inner landscape (890pt) and all iPads split.
  A test or refactor that moves this threshold needs Charles's eyes.
- **Device matrix** (Duo): closed / open-portrait / open-landscape / half-fold captures;
  `xcrun devicectl device capture screenshot` (outer by default; inner via
  `--display-unique-id`, uniqueIds are placeholders `987-654-321` / `123-456-789`).

## Dev sign-in (simulators)

Primary sign-in targets a webui-kind server — the production Hermes WebUI at
`http://127.0.0.1:8787` (Keychain item `hermex-webui`; the password is Charles's to type).
The Hermes-kind layer comes from `scripts/local-hermes` (stub, loopback :9199). Full recipe:
`hermes-client` skill → `references/device-sim-workflow.md`.

## PR etiquette (selective upstreaming)

`CONTRIBUTING.md` governs: small fixes with tests welcome directly; anything larger needs an
issue first (Duo work: #1338). Conventional titles; Duo PRs use `Part of #1338` unless they
close it; AI-usage line per CONTRIBUTING. Commit as `Charles McQuade <dcm.inglis@gmail.com>`.
