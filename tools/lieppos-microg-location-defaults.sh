#!/system/bin/sh

PREF_DIR=/data/user/0/com.google.android.gms/shared_prefs
PREF_FILE=${PREF_DIR}/com.google.android.gms_preferences.xml

wait_for_data() {
    i=0
    while [ "$i" -lt 60 ]; do
        [ -d /data/user/0/com.google.android.gms ] && return 0
        sleep 1
        i=$((i + 1))
    done
    return 1
}

set_bool_pref() {
    key="$1"
    value="$2"

    if grep -q "name=\"${key}\"" "$PREF_FILE"; then
        sed -i "s|<boolean name=\"${key}\" value=\"[^\"]*\" />|<boolean name=\"${key}\" value=\"${value}\" />|" "$PREF_FILE"
    else
        sed -i "/<\/map>/i\\    <boolean name=\"${key}\" value=\"${value}\" />" "$PREF_FILE"
    fi
}

set_int_pref() {
    key="$1"
    value="$2"

    if grep -q "name=\"${key}\"" "$PREF_FILE"; then
        sed -i "s|<int name=\"${key}\" value=\"[^\"]*\" />|<int name=\"${key}\" value=\"${value}\" />|" "$PREF_FILE"
    else
        sed -i "/<\/map>/i\\    <int name=\"${key}\" value=\"${value}\" />" "$PREF_FILE"
    fi
}

set_string_pref_if_missing() {
    key="$1"
    value="$2"

    if ! grep -q "name=\"${key}\"" "$PREF_FILE"; then
        sed -i "/<\/map>/i\\    <string name=\"${key}\">${value}</string>" "$PREF_FILE"
    fi
}

wait_for_data || exit 0
mkdir -p "$PREF_DIR"

if [ ! -f "$PREF_FILE" ]; then
    cat > "$PREF_FILE" <<EOF
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
</map>
EOF
fi

# Offline location only works after RF observations have been learned or cached.
# Keep both microG's local cache learning and online bootstrap paths enabled.
set_bool_pref location_wifi_learning true
set_bool_pref location_wifi_mls true
set_bool_pref location_cell_mls true
set_string_pref_if_missing location_online_source positon
set_int_pref gcm_learnt_wifi 900000
set_int_pref gcm_learnt_mobile 900000

chown -R "$(stat -c %u:%g /data/user/0/com.google.android.gms)" "$PREF_DIR"
chmod 771 "$PREF_DIR"
chmod 660 "$PREF_FILE"

log -t lieppos-location "Ensured microG network-location cache defaults"
