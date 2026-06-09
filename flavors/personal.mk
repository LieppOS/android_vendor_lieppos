# "mano buildas" — full personal build. = common (lieppos.mk) + microG +
# every personal/hardware-niche app. This reproduces the pre-flavor build.

$(call inherit-product, vendor/lieppos/flavors/microg-common.mk)

# Personal apps (kept OUT of user builds)
PRODUCT_PACKAGES += \
    TinyDisplay \
    TinyDisplayTouchHelper \
    TinyDisplayTouchDaemon \
    SeklysMorka \
    AndroidNfc

# Android Auto (Gearhead) stub + RRO overlay. NikGapps-sourced
# AndroidAutoStubPrebuilt; full APK installed via Aurora. Play Services API
# satisfied by microG GmsCore (wired + wireless AA).
PRODUCT_PACKAGES += \
    AndroidAutoStubPrebuilt \
    AndroidAutoOverlay

PRODUCT_PRODUCT_PROPERTIES += \
    ro.lieppos.flavor=mano
