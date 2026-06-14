# LieppOS vendor configuration — COMMON base shared by every flavor.
#
# Flavor-specific package sets live in vendor/lieppos/flavors/*.mk and are
# inherited by the per-flavor product makefiles in device/phh/treble:
#   personal.mk -> lineage_arm64_bvNE         (mano buildas, full personal build)
#   vanilla.mk  -> lineage_arm64_bvNE_vanilla (Pure Vanilla, no GMS/microG)
#   semi.mk     -> lineage_arm64_bvNE_semi    (microG + F-Droid)
#   gapps.mk    -> lineage_arm64_bvNE_gapps   (MindTheGapps)
#
# Anything here ships in ALL builds. Keep personal/hardware-niche apps
# (SeklysMorka, AndroidNfc, AndroidAuto, the full TinyDisplay renderer) OUT of
# this file — put them in flavors/personal.mk.

# LieppOS sepolicy (system_ext-side, hosts the lineage health HAL on GSI)
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += vendor/lieppos/sepolicy

# Thermal camera app (Ulefone IR sensor)
PRODUCT_PACKAGES += \
    M170infisens

# Thermal camera default permissions
PRODUCT_COPY_FILES += \
    vendor/lieppos/energy_tc2c/default-permissions-com.energy.tc2c.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/default-permissions/default-permissions-com.energy.tc2c.xml

# sysfs permission rules live in system/core/rootdir/ueventd.rc — chmod on sysfs
# attributes is rejected by the kernel post-boot, so ueventd is the only working
# path. The ueventd.rc.d/ subdir and init.rc chmod approaches do not work.

# Lineage Health: MTK charging control
$(call soong_config_set_bool,lineage_health,charging_control_supports_toggle,true)
$(call soong_config_set_bool,lineage_health,charging_control_supports_bypass,false)
$(call soong_config_set,lineage_health,charging_control_charging_path,/sys/class/power_supply/mtk-master-charger/input_current_limit)
$(call soong_config_set,lineage_health,charging_control_charging_enabled,-1)
$(call soong_config_set,lineage_health,charging_control_charging_disabled,0)

PRODUCT_PACKAGES += \
    vendor.lineage.health-service.default

PRODUCT_PRODUCT_PROPERTIES += \
    ro.vendor.lineage.health.charging_control=true

# Keymapper toggle scripts (camp light LEDs / touchscreen grabber — device HW)
PRODUCT_PACKAGES += \
    toggle_camplight.sh \
    toggle_redled.sh \
    toggle_blueled.sh \
    toggle_touchscreen.sh \
    lieppos-touchscreen-grabber

# Boot animation
PRODUCT_COPY_FILES += \
    vendor/lieppos/bootanimation/bootanimation.zip:$(TARGET_COPY_OUT_SYSTEM)/media/bootanimation.zip

# GNSS defaults for devices whose vendor image leaves AOSP gps.conf absent.
# MTK vendor GNSS primarily uses /vendor/etc/gnss/agps_profiles_conf2.xml,
# but this keeps the system-side fallback explicit for GSIs.
PRODUCT_COPY_FILES += \
    vendor/lieppos/etc/gps.conf:$(TARGET_COPY_OUT_SYSTEM)/etc/gps.conf

# Expose adb-root support to the QS ADB-root tile on all builds.
PRODUCT_PRODUCT_PROPERTIES += \
    ro.lieppos.adb_root_supported=true

# Armor 29 Pro / MTK Treble compatibility defaults.
#
# As of LieppOS 1.1 every phone-specific patch ships DISABLED by default. The
# user enables what their device actually needs from LieppOS Settings ->
# Phone specific patches -> <device>. Keeping these here (set to off values)
# rather than omitting them pins the install-time state explicitly so a
# previous build's persist values don't leak through.
PRODUCT_PRODUCT_PROPERTIES += \
    persist.lieppos.device_patches=none \
    persist.sys.overlay.devinputjack=false \
    persist.sys.phh.disable_audio_effects=0 \
    persist.sys.phh.mtk_ged_kpi=0 \
    persist.bluetooth.system_audio_hal.enabled=false \
    persist.sys.phh.allow_binder_thread_on_incoming_calls=0 \
    persist.sys.phh.disable_voice_call_in=false \
    persist.sys.phh.patch_smsc=false \
    persist.sys.phh.virtual_sensors_are_real=0 \
    persist.dbg.volte_avail_ovr=0 \
    persist.dbg.vt_avail_ovr=0 \
    persist.dbg.wfc_avail_ovr=0 \
    persist.dbg.allow_ims_off=0

# Armor 29 Thermal Pro hardware-feature gates. All disabled at install; the
# user opts in from LieppOS Settings -> Phone specific patches -> Ulefone
# Armor 29 Thermal Pro -> Hardware features.
# Consumers: camp_lights/super_flashlight -> SystemUI tile isAvailable()
# (fb patch 0008); nfc_routing_watchdog -> NfcService 6s/60s watchdog (Nfc
# 9001 patch); thermal_cam/sub_screen/fm_radio/touchscreen_grabber -> package
# enable/disable via Armor29FeatureGates (LieppOS app); charging_control ->
# Lineage Health off-switch. Props are labeled lieppos_prop (sepolicy/).
PRODUCT_PRODUCT_PROPERTIES += \
    persist.lieppos.armor29.thermal_cam=false \
    persist.lieppos.armor29.sub_screen=false \
    persist.lieppos.armor29.camp_lights=false \
    persist.lieppos.armor29.super_flashlight=false \
    persist.lieppos.armor29.fm_radio=false \
    persist.lieppos.armor29.charging_control=false \
    persist.lieppos.armor29.touchscreen_grabber=false \
    persist.lieppos.armor29.nfc_routing_watchdog=false

# IMS / 4G calling feature gates are present but intentionally OFF by default.
# Users can enable the matching controls from LieppOS Settings -> System ->
# Patches -> IMS features when testing VoLTE/VT/WFC on a carrier/SIM.
PRODUCT_PRODUCT_PROPERTIES += \
    ro.config.hw_volte_enable=false \
    ro.config.hw_video_call_enable=false \
    ro.config.hw_wifi_call_enable=false

# Silence vendor log spam: trustonic IPC retries (TEE keymaster path
# unavailable on this kernel) and MTK GNSS geofence_dev_open retries
# (geofencing HAL not wired). Both are vendor-binary issues, harmless
# at runtime, only noisy.
PRODUCT_PRODUCT_PROPERTIES += \
    log.tag.mtk_storageproxyd=SILENT \
    log.tag.android.hardware.gnss-service.mediatek=WARN

# QS layout overrides: Quick QS 3x4 (12 tiles), Full QS 5x4
PRODUCT_PACKAGE_OVERLAYS += vendor/lieppos/overlay

# RevampedFMRadio (com.android.fmradio) — MTK SoC build.
# Overrides packages/apps/FMRadio via LOCAL_OVERRIDES_PACKAGES.
# JNI libmtkfmjni talks to /dev/fm (fmradio_drv_connac2x kernel driver).
PRODUCT_PACKAGES += \
    RevampedFMRadio \
    libmtkfmjni

# RevampedFMRadio chip config. libfmcust reads persist.vendor.connsys.fm_chipid
# first; vendor sets it to "connac2x" which the lib doesn't map, so cfg->chip
# stays UNSUPPORTED. Fallback ro.fm.chip lets us pin MT6635 explicitly so
# FMR_open_dev's chip-match check passes (kernel reports 0x6635 / MT6635).
PRODUCT_PRODUCT_PROPERTIES += \
    ro.fm.chip=0x6635

# LieppOS Settings tab
PRODUCT_PACKAGES += LieppOS

PRODUCT_COPY_FILES += \
    packages/apps/LieppOS/com.lieppos.settings.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/com.lieppos.settings.xml
