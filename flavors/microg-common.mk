# Shared microG package set — inherited by personal.mk (mano) and semi.mk.
# microG signature spoofing in frameworks is gated on
# ro.lieppos.microg_restricted_spoofing (see platform_frameworks_base patch
# 0003); flavors without microG never set it, so spoofing stays off there.

PRODUCT_PACKAGES += \
    GmsCore \
    GsfProxy \
    FakeStore

# microG network location backend (Déjà Vu) + its default permissions
PRODUCT_PACKAGES += \
    DejaVuNlpBackend

PRODUCT_COPY_FILES += \
    vendor/lieppos/default-permissions/default-permissions-org.fitchfamily.android.dejavu.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/default-permissions/default-permissions-org.fitchfamily.android.dejavu.xml

# microG location defaults applier
PRODUCT_PACKAGES += \
    lieppos-microg-location-defaults.sh

PRODUCT_PRODUCT_PROPERTIES += \
    ro.lieppos.microg_restricted_spoofing=true
