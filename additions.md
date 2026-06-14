# LieppOS Additions

This document lists the ROM features and LieppOS-specific additions carried under `vendor/lieppos` and its personal patch stack.

## Build variants / flavors

- **mano buildas / personal** (`lineage_arm64_bvNE`): full personal build with microG plus all personal and hardware-niche apps.
- **Vanilla** (`lineage_arm64_bvNE_vanilla`): no GMS, no microG, no F-Droid; keeps the LieppOS common base.
- **Semi** (`lineage_arm64_bvNE_semi`): microG + F-Droid + F-Droid Privileged Extension + preconfigured repositories.
- **Google's / GApps** (`lineage_arm64_bvNE_gapps`): real GApps via MindTheGapps extraction/integration.
- Per-flavor `ro.lieppos.flavor` property.
- Per-flavor isolated `OUT_DIR=out/<flavor>` build output support.
- Shared product target base for Treble/GSI flavor products.

## Core branding and product identity

- LieppOS vendor product makefile inherited by the PHH/Treble product.
- `LieppOS-` prefix on Lineage display version.
- Product brand changed to **LieppOS**.
- Pixel 9 Pro spoofing / pinned fingerprint for target builds.
- Release-key signing support in the target product.
- Debug fingerprint stripping and user-build hardening.
- Mainline key handling adjusted to avoid shared-UID/signature bootloops.
- `ro.lieppos.adb_root_supported=true` for LieppOS ADB-root UI support.

## Common packages shipped in all builds

- Uses the Lineage/AOSP Android System WebView provider (`com.android.webview`); the previously bundled Google WebView/Trichrome prebuilts were removed.
- Ulefone/Armor thermal camera app (`M170infisens`) with default permissions.
- MTK charging-control Lineage Health HAL (`vendor.lineage.health-service.default`).
- Camp-light / LED / touchscreen helper scripts:
  - `toggle_camplight.sh`
  - `toggle_redled.sh`
  - `toggle_blueled.sh`
  - `toggle_touchscreen.sh`
  - `lieppos-touchscreen-grabber`
- LieppOS boot animation.
- System-side `gps.conf` fallback for GNSS/AGPS.
- RevampedFMRadio (`com.android.fmradio`) with MTK JNI library `libmtkfmjni`.
- LieppOS Settings package/tab and `com.lieppos.settings.xml` permission file.
- Log-spam silencing for noisy MTK/Trustonic vendor components.

## microG / location / app-store features

- microG package set for microG flavors:
  - `GmsCore`
  - `GsfProxy`
  - `FakeStore`
- Restricted signature spoofing gated by `ro.lieppos.microg_restricted_spoofing=true`.
- AppOps compatibility for signed microG phone-package attribution.
- Déjà Vu Network Location Provider (`DejaVuNlpBackend`).
- Default permissions for Déjà Vu NLP backend.
- `lieppos-microg-location-defaults.sh` service to apply microG/network-location defaults.
- microG network/fused-location compatibility fixes.
- F-Droid + F-Droid Privileged Extension support in Semi flavor.
- `additional_repos.xml` for preconfigured F-Droid/microG repositories.
- MindTheGapps extraction helper and generated `vendor/gapps` wiring for GApps flavor.

## Personal / hardware-niche apps

- **TinyDisplay** full sub-screen renderer in personal flavor.
- **TinyDisplayService** minimal sub-screen power-saver in Vanilla/Semi/GApps flavors; turns the secondary LCD fully off at boot.
- **SeklysMorka** personal app.
- **AndroidNfc** privileged app.
- AndroidNfc `MANAGE_USB` privapp allowlist.
- **Android Auto / Gearhead** privileged stub + overlay for wired/wireless Android Auto with microG/GApps.
- Android Auto privileged permission allowlist.
- MeaWallet support work: fingerprint/serial persistence for token quota compatibility.

## LieppOS Settings UI

- Native **LieppOS** Settings homepage/tab.
- Grouped LieppOS dashboard categories:
  - Quick Settings
  - Lock screen
  - Power menu
  - Display
  - Battery & Charging
  - Notifications
  - Gestures
  - Misc
  - MediaTek specific patches
- Native Settings homepage entries for LieppOS apps:
  - TinyDisplay
  - SeklysMorka
  - AndroidNfc / NFC cards
  - Messaging/SMS entry icons
- Restored native Display page in LieppOS Settings.
- MediaTek-specific patches placeholder page.
- Treble App placement adjusted lower in Settings.
- LieppOS Settings gateway allowlist entries.

## Display and refresh-rate features

- **Smooth Display** LieppOS Settings screen.
- Dynamic refresh rate with peak Hz, idle Hz, and idle timeout controls.
- Per-app refresh-rate override screen.
- SeekBar row/layout fix for Smooth Display controls.
- Battery percentage Settings toggle wired to the Lineage status-bar setting.
- Disabled Bluetooth by default.
- Disabled duplicate `NoCutoutOverlay` build target.

## Quick Settings additions

- QS layout overlay: **Quick QS 3x4** / 12 quick tiles.
- Full QS layout overlay: **5x4** full panel.
- LieppOS Settings controls for:
  - Quick QS columns
  - Quick QS rows
  - Full QS columns
  - Full QS rows
  - QS tile height
- Custom QS tiles for:
  - Super Flashlight
  - Red Light
  - Blue Light
  - Split Screen
  - ADB Debugging
  - ADB Root
  - GPS Refresh
  - USB Mode
  - Screen Timeout
- Custom QS edit-mode category **LieppOS** with proper labels and icons instead of Unknown/star icons.
- Camp-light tile support for red/blue/flashy modes.
- ADB QS tile fixes so toggling ADB does not destroy the USB gadget.
- ADB Root QS tile guarded so it does not brick ADB on user builds.
- USB-mode tile fixes for Android 16 settable-function restrictions.

## Power menu / reboot features

- Advanced reboot menu support.
- Added **Fastbootd** entry to advanced reboot.
- **Restart SystemUI** entry in the power menu.
- Settings toggles/links for advanced reboot and Restart SystemUI.

## Gestures and lock-screen features

- Three-finger screenshot gesture.
- Volume long-press skip-track gesture.
- Evolution-style Sleep mode.
- Lock-screen widgets 3-up support noted as already present in base.
- Touchscreen gesture section/linking in LieppOS Settings.

## Notifications and sound/vibration features

- Custom notification vibration patterns.
- Notification-light settings link/section.
- Charging sound settings link/section.
- Heads-up / notification settings section hooks.
- Messaging fix to properly mark conversations as read from wearable/read actions.

## Battery and charging features

- MTK charging-control HAL integrated through Lineage Health.
- Charging enable/disable path set to `/sys/class/power_supply/mtk-master-charger/input_current_limit`.
- Charging-control Settings link under LieppOS Battery & Charging.
- Charging-control SELinux policy for GSI/system_ext placement.
- Adaptive Charging polish noted as already present in base.

## Radio / connectivity / hardware features

- RevampedFMRadio replaces stock FMRadio.
- MTK FM JNI support and `/dev/fm` access policy.
- FM chip pinned to MT6635 via `ro.fm.chip=0x6635`.
- Boot-time `/dev/fm` ownership/permission repair for the system FM app.
- NFC applyRouting watchdog mitigation.
- NFC crash fix for HAL death restart / zygisk vector path.
- GPS/GNSS fallback configuration and log-noise reduction.
- Smart 5G feature work.
- MediaTek-specific patch section for future device toggles.
- Samsung gatekeeper vendor-data SELinux access fix.

## ADB / USB / root behavior

- ADB root toggle exposed on LieppOS user builds.
- ADB authentication behavior reads `ro.adb.secure` correctly.
- Dev Options ADB toggle forces `ro.adb.secure=0` behavior as intended for this ROM.
- Boot-script repair for ADB USB mode.
- ADB kept across Settings, reboot, and vendor USB init.
- Direct uncached ADB setting reads to avoid stale Settings cache in `system_server`.
- Removed unsafe auto-ADB-root-at-boot behavior.
- Prevented ADB-root service from running adbd in the wrong `su` SELinux domain on user builds.
- USB menu crash fix: do not pass `FUNCTION_ADB` to `setCurrentFunctions`.
- USB gadget teardown race fixed by making ADB tiles behave like Developer Options.

## Launcher / recents features

- Recents Clear All button / placement support.
- Launcher3 Recents dependency-scope initialization fix.
- Blank Clear All page / grey action-button fix.

## Security, SELinux, and policy changes

- LieppOS system_ext sepolicy directory.
- Lineage Health HAL policy.
- FM radio device policy.
- microG policy.
- system_suspend dontaudit/policy cleanup.
- TrebleDroid permissive-domain handling for user builds.
- crash_dump ptrace allowance for GSI tombstone capture.
- SELinux fixes for `gatekeeper_vendor_data_file` and Samsung TEE path.
- Backuptool permissive policy removed for user-build compatibility.
- LieppOS `.te` files moved out of the private subdirectory.

## Build-system and source-tree fixes

- Soong/AIDL host-fuzzer panic workaround.
- VNDK duplicate apex/module fixes.
- Dropped broken VNDK v30 apex/staging patch when no v30 snapshot exists.
- Serializer.cpp duplicate-definition build fix.
- fs_mgr duplicate `utsname` / `major, minor` block fix.
- TelephonyManager duplicate method fix.
- Federated Compute LTO disabled to avoid linker/debug-info failure.
- ART imgdiag debug-section compression workaround.
- QPR2 / lineage-23.2 upgrade support and patch rebases.
- Treble app source prep and staging conflict handling.
- Removed stripped/non-Ulefone targets from the tree.
- Local manifest cleanup for removed project paths.

## LieppOS patch/repo workflow

- All personal ROM changes consolidated into `vendor/lieppos`.
- Personal patch stack stored under `vendor/lieppos/patches/personal`.
- `apply-personal.sh` applies LieppOS personal patches after TrebleDroid patches.
- `apply-personal.sh` colored output:
  - orange applying headers
  - red failures
  - green already-applied status
  - end summary with applied/already/failed counts
- `LineageOS_gsi/patches/apply-patches.sh` adjusted to avoid double-applying personal patches.
- Patch workflow documentation added (`docs/patch.md`).
- Suggestions / feature-spelunking docs added.
- Docs split into a separate docs repo while still available under `vendor/lieppos/docs` on disk.

## Build and maintenance tooling

- `build.sh` flavor menu for mano / Vanilla / Semi / Google's / compress-only.
- Build manifest and CHANGES integration.
- Build-end desktop notifications.
- Build duration shown in exit notification.
- Build-finish notification timeout increased to 30 seconds.
- Optional build audio beeps.
- Swaync notification support.
- Preflight RAM/disk warnings.
- Threadripper 2990WX JVM/NUMA prompt/fix.
- Default job cap after transient `rustc` segfaults.
- tmpfs-backed per-flavor `OUT_DIR` support, enabled by default with `notmpfs` opt-out.
- Clean/wipe logic aware of per-flavor OUT_DIR and tmpfs mounts.
- `wipe` argument for forced full clean.
- Explicit flash-to-slot-A handling.
- `xz` auto-threading for image compression.
- Build backup timestamp format with separated hour/minute/second fields.
- VEIKIA known-good backup marker prompt.
- `flash-veikia.sh` to flash the latest known-good backup image.
- `update.sh` to repo-sync the full tree and re-apply LieppOS patches.
- `update.sh` dirty-tree reset/clean handling before sync.
- `update.sh` options for reset, jobs, yes-mode, sync-only/no-reapply.
- Corrupt/truncated build-output cleanup guidance and fixes.

## Documented but not source-changing planning/notes

- Iconify-style customization plan.
- PixelXpert / Settings theming TODOs.
- GPS slow/inaccurate diagnosis notes.
- Feature-spelunking guide and candidate list.
- LieppOS improvement suggestions document.
- New-build-changes reminder/TODOs.
