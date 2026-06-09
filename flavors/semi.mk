# Semi — microG + F-Droid (with Privileged Extension for silent updates) and the
# microG/F-Droid repos preconfigured (additional_repos.xml). No personal apps.

$(call inherit-product, vendor/lieppos/flavors/microg-common.mk)

# F-Droid client + privileged extension + repo config (restored from
# lineageos4microg into vendor/partner_gms).
PRODUCT_PACKAGES += \
    FDroid \
    FDroidPrivilegedExtension \
    additional_repos.xml

# Sub-screen power-saver (no full TinyDisplay renderer)
PRODUCT_PACKAGES += \
    TinyScreenService

PRODUCT_PRODUCT_PROPERTIES += \
    ro.lieppos.flavor=semi
