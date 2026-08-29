#!/system/bin/sh
#
# Toggle the LieppOS touchscreen grabber.
#
# While the grabber service runs it holds /dev/input exclusively, so the
# touchscreen is effectively disabled. Stopping the service releases it.

SERVICE=lieppos_touchscreen_grabber

# ctl.start / ctl.stop are asynchronous: init picks them up on its own loop.
# The old code slept a flat 1s and then checked once, which reported a spurious
# failure whenever init was busy (and wasted ~1s when it was not). Poll instead.
POLL_TRIES=20      # 20 x 0.1s = 2s ceiling
POLL_DELAY=0.1

svc_state() {
    getprop "init.svc.${SERVICE}"
}

# True when the grabber actually holds the touchscreen right now.
# NOTE: "restarting" is deliberately NOT counted here. A crash-looping grabber
# is not holding the device between respawns, so reporting it as "disabled"
# claimed the touchscreen was off while it was intermittently live.
touchscreen_disabled() {
    [ "$(svc_state)" = "running" ]
}

touchscreen_unstable() {
    [ "$(svc_state)" = "restarting" ]
}

# wait_for running|stopped — returns 0 as soon as the state is reached.
wait_for() {
    want="$1"
    i=0
    while [ "$i" -lt "$POLL_TRIES" ]; do
        state="$(svc_state)"
        if [ "$want" = "running" ]; then
            [ "$state" = "running" ] && return 0
        else
            case "$state" in
                running|restarting) ;;
                *) return 0 ;;
            esac
        fi
        sleep "$POLL_DELAY"
        i=$((i + 1))
    done
    return 1
}

enable_touchscreen() {
    setprop ctl.stop "$SERVICE"
    if ! wait_for stopped; then
        echo "failed to enable touchscreen: ${SERVICE} is still $(svc_state)" >&2
        exit 1
    fi
    echo "touchscreen enabled"
}

disable_touchscreen() {
    setprop ctl.start "$SERVICE"
    if ! wait_for running; then
        echo "failed to disable touchscreen: ${SERVICE} is $(svc_state)" >&2
        exit 1
    fi
    echo "touchscreen disabled"
}

case "${1:-toggle}" in
    toggle)
        # A crash-looping grabber counts as "meant to be off", so a toggle from
        # that state stops it rather than trying to start it again.
        if touchscreen_disabled || touchscreen_unstable; then
            enable_touchscreen
        else
            disable_touchscreen
        fi
        ;;
    disable|off)
        if touchscreen_disabled; then
            echo "touchscreen already disabled"
        else
            disable_touchscreen
        fi
        ;;
    enable|on)
        if touchscreen_disabled || touchscreen_unstable; then
            enable_touchscreen
        else
            echo "touchscreen already enabled"
        fi
        ;;
    status)
        if touchscreen_unstable; then
            echo "unstable (${SERVICE} restarting)"
            exit 3
        elif touchscreen_disabled; then
            echo "disabled"
        else
            echo "enabled"
        fi
        ;;
    *)
        echo "Usage: toggle_touchscreen.sh [toggle|disable|enable|off|on|status]" >&2
        exit 2
        ;;
esac
