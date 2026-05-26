package com.lieppos.tinyscreen;

import android.util.Log;

import java.lang.reflect.Method;

/**
 * Minimal HIDL wrapper for vendor.yft.hardware.tinylcd@1.0::ITinylcd, trimmed to
 * the power-off path only. Reflection is used to reach the hidden
 * android.os.HwBinder / HwParcel APIs (platform-signed app).
 *
 * Transaction codes (from the HIDL stub symbol ordering in
 * vendor.yft.hardware.tinylcd@1.0.so):
 *   1 = lcd_set_power     (1=on, 0=off)
 *   2 = lcd_set_backlight (brightness level)
 *   3 = lcd_set_bl        (backlight enable/disable)
 *
 * Full rendering (frame writes, touch, test patterns) is intentionally omitted —
 * this app only ever turns the sub-screen OFF to save power.
 */
final class TinyLcdHal {

    private static final String TAG = "TinyLcdSaver";
    private static final String INTERFACE_TOKEN = "vendor.yft.hardware.tinylcd@1.0::ITinylcd";
    private static final String INSTANCE_NAME = "default";

    private static final int TX_POWER     = 1; // lcd_set_power(int)
    private static final int TX_BACKLIGHT  = 2; // lcd_set_backlight(int)
    private static final int TX_BL_ENABLE  = 3; // lcd_set_bl(int)

    private Class<?> hwParcelClass;
    private Method writeInterfaceToken;
    private Method writeInt32;
    private Method verifySuccess;
    private Method readInt32;
    private Method releaseTemporaryStorage;
    private Method releaseParcel;
    private Method transactMethod;

    private Object hwBinder;
    private boolean connected = false;

    boolean connect() {
        try {
            Class<?> hwBinderClass = Class.forName("android.os.HwBinder");
            hwParcelClass = Class.forName("android.os.HwParcel");
            Class<?> iHwBinderClass = Class.forName("android.os.IHwBinder");

            writeInterfaceToken = hwParcelClass.getMethod("writeInterfaceToken", String.class);
            writeInt32 = hwParcelClass.getMethod("writeInt32", int.class);
            verifySuccess = hwParcelClass.getMethod("verifySuccess");
            readInt32 = hwParcelClass.getMethod("readInt32");
            releaseTemporaryStorage = hwParcelClass.getMethod("releaseTemporaryStorage");
            releaseParcel = hwParcelClass.getMethod("release");
            transactMethod = iHwBinderClass.getMethod("transact",
                    int.class, hwParcelClass, hwParcelClass, int.class);

            Method getService = hwBinderClass.getMethod("getService",
                    String.class, String.class, boolean.class);
            hwBinder = getService.invoke(null, INTERFACE_TOKEN, INSTANCE_NAME, true);

            if (hwBinder == null) {
                Log.e(TAG, "getService returned null — tinylcd HAL not registered");
                return false;
            }
            connected = true;
            return true;
        } catch (Exception e) {
            Log.e(TAG, "connect failed", e);
            connected = false;
            return false;
        }
    }

    /** Power the sub-screen fully off: backlight 0, backlight disable, power off. */
    void powerOff() {
        transactInt(TX_BACKLIGHT, 0, "setBacklight");
        transactInt(TX_BL_ENABLE, 0, "setBlEnable");
        transactInt(TX_POWER, 0, "setPower");
        Log.i(TAG, "Sub-screen powered off");
    }

    private int transactInt(int txCode, int value, String name) {
        if (!connected) {
            Log.e(TAG, name + ": not connected");
            return -1;
        }
        Object request = null;
        Object reply = null;
        try {
            request = hwParcelClass.getConstructor().newInstance();
            writeInterfaceToken.invoke(request, INTERFACE_TOKEN);
            writeInt32.invoke(request, value);

            reply = hwParcelClass.getConstructor().newInstance();
            transactMethod.invoke(hwBinder, txCode, request, reply, 0);
            verifySuccess.invoke(reply);
            releaseTemporaryStorage.invoke(request);

            return (int) readInt32.invoke(reply);
        } catch (Exception e) {
            Log.e(TAG, name + " failed", e);
            return -1;
        } finally {
            if (reply != null) {
                try { releaseParcel.invoke(reply); } catch (Exception ignored) {}
            }
        }
    }
}
