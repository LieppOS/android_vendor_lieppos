# Pure Vanilla — no GMS, no microG, no F-Droid. Just the LieppOS common base.
# Sub-screen kept off via the minimal power-saver (no full TinyScreen renderer).

PRODUCT_PACKAGES += \
    TinyScreenService

PRODUCT_PRODUCT_PROPERTIES += \
    ro.lieppos.flavor=vanilla
