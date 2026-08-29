#!/bin/bash
#
# Apply LieppOS personal patches.
#
# Run from the Android build tree root (ANDROID_BUILD_TOP), AFTER
# LineageOS_gsi/patches/apply-patches.sh has applied the TrebleDroid patches:
#
#   bash LineageOS_gsi/patches/apply-patches.sh        # trebledroid + staging
#   bash vendor/lieppos/apply-personal.sh              # LieppOS personal
#
# Personal patches moved here from LineageOS_gsi/patches/personal so that all
# LieppOS-owned work lives in the single vendor/lieppos repo. Logic mirrors the
# upstream apply_patch_dir() (git am with a patch -p1 fallback).

set -e

if [ -t 1 ]; then
    RED=$'\033[1;31m'; GREEN=$'\033[1;32m'; ORANGE=$'\033[38;5;208m'; RST=$'\033[0m'
else
    RED=''; GREEN=''; ORANGE=''; RST=''
fi

personal="$(pwd)/vendor/lieppos/patches/personal"

N_APPLIED=0
N_ALREADY=0
N_FAILED=0
FAILED_LIST=""

apply_patch_dir() {
    local patch_dir=$1
    local patch_name=$2

    printf "\n${ORANGE} ### APPLYING %s PATCHES ###${RST}\n" "$patch_name"

    if [ ! -d "$patch_dir" ]; then
        printf "Directory %s not found, skipping...\n" "$patch_dir"
        return 0
    fi

    for path in $(cd "$patch_dir"; echo *); do
        # `echo *` yields the literal '*' for an empty dir; skip it rather than
        # trying to cd into a directory called '*'.
        [ -d "$patch_dir/$path" ] || continue

        tree="$(tr _ / <<<"$path" | sed -e 's;platform/;;g')"
        printf "\n| %s ###\n" "$path"

        [ "$tree" == build ] && tree=build/make
        [ "$tree" == testing ] && tree=platform_testing
        [ "$tree" == vendor/hardware/overlay ] && tree=vendor/hardware_overlay
        [ "$tree" == treble/app ] && tree=treble_app
        [ "$tree" == vendor/partner/gms ] && tree=vendor/partner_gms

        # A missing target tree must not abort the whole run. Under `set -e` an
        # unguarded `pushd` on a renamed/removed manifest project killed every
        # remaining patch directory, and update.sh swallowed the failure, so the
        # tree silently built without most LieppOS patches.
        if ! pushd "$tree" > /dev/null 2>&1; then
            printf "${RED}### MISSING TREE: %s (skipping %s)${RST}\n" "$tree" "$path"
            N_FAILED=$((N_FAILED+1))
            FAILED_LIST="${FAILED_LIST}"$'\n'"  ${path} (tree '${tree}' not found)"
            continue
        fi

        for patch in "$patch_dir"/"$path"/*.patch; do
            [ -f "$patch" ] || continue
            if patch -f -p1 --dry-run -R < "$patch" > /dev/null; then
                printf "${GREEN}### ALREADY APPLIED: %s ${RST}\n" "$patch"
                N_ALREADY=$((N_ALREADY+1))
                continue
            fi

            if git apply --check "$patch"; then
                git am "$patch"
                N_APPLIED=$((N_APPLIED+1))
            elif patch -f -p1 --dry-run < "$patch" > /dev/null; then
                git am "$patch" || true
                patch -f -p1 < "$patch"
                git add -u
                git am --continue
                N_APPLIED=$((N_APPLIED+1))
            else
                printf "${RED}### FAILED APPLYING: %s ${RST}\n" "$patch"
                N_FAILED=$((N_FAILED+1))
                FAILED_LIST="${FAILED_LIST}"$'\n'"  ${patch#"$personal"/}"
            fi
        done

        popd > /dev/null
    done
}

apply_patch_dir "$personal" "LIEPPOS PERSONAL"

printf "\n==============================================================\n"
if [ "$N_FAILED" -eq 0 ]; then
    printf " personal: ${GREEN}%d applied, %d already-applied, 0 failed${RST}\n" "$N_APPLIED" "$N_ALREADY"
else
    printf " personal: %d applied, %d already-applied, ${RED}%d failed${RST}\n" "$N_APPLIED" "$N_ALREADY" "$N_FAILED"
    printf "${RED} FAILED patches:%s${RST}\n" "$FAILED_LIST"
fi
printf "==============================================================\n"
