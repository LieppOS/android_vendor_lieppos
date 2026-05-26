package com.lieppos.tinyscreen;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

/**
 * One-shot sub-screen power saver. On BOOT_COMPLETED it connects to the tinylcd
 * HIDL HAL and powers the sub-screen off, then exits. No persistent service, no
 * rendering, no settings — the sub-screen stays dark to save power.
 */
public class BootReceiver extends BroadcastReceiver {

    private static final String TAG = "TinyScreenSaver";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (!Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            return;
        }
        // HAL transactions are blocking binder calls; run off the main thread.
        final PendingResult result = goAsync();
        new Thread(() -> {
            try {
                TinyLcdHal hal = new TinyLcdHal();
                if (hal.connect()) {
                    hal.powerOff();
                } else {
                    Log.w(TAG, "tinylcd HAL unavailable; sub-screen left untouched");
                }
            } catch (Throwable t) {
                Log.e(TAG, "power-off failed", t);
            } finally {
                result.finish();
            }
        }, "tinyscreen-poweroff").start();
    }
}
