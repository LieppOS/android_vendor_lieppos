#!/system/bin/sh

SERVICE=lieppos_touchscreen_grabber

touchscreen_disabled() {
    case "$(getprop init.svc.${SERVICE})" in
        running|restarting)
            return 0
            ;;
    esac
    return 1
}

enable_touchscreen() {
    setprop ctl.stop "$SERVICE"
    sleep 1
    if touchscreen_disabled; then
        echo "failed to enable touchscreen: ${SERVICE} is still running" >&2
        exit 1
    fi
    echo "touchscreen enabled"
}

disable_touchscreen() {
    setprop ctl.start "$SERVICE"
    sleep 1
    if ! touchscreen_disabled; then
        echo "failed to disable touchscreen: ${SERVICE} did not start" >&2
        exit 1
    fi
    echo "touchscreen disabled"
}

case "${1:-toggle}" in
    toggle)
        if touchscreen_disabled; then
            enable_touchscreen
        else
            disable_touchscreen
        fi
        ;;
    disable|off)
        if ! touchscreen_disabled; then
            disable_touchscreen
        else
            echo "touchscreen already disabled"
        fi
        ;;
    enable|on)
        if touchscreen_disabled; then
            enable_touchscreen
        else
            echo "touchscreen already enabled"
        fi
        ;;
    status)
        if touchscreen_disabled; then
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
