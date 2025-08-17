// android/app/src/main/kotlin/com/example/call_app/CallReceiver.kt
package com.example.call_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

class CallReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "CallReceiver"
        private var lastState = TelephonyManager.CALL_STATE_IDLE
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            val phoneNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

            when (state) {
                TelephonyManager.EXTRA_STATE_IDLE -> {
                    Log.d(TAG, "Call ended")
                    if (lastState != TelephonyManager.CALL_STATE_IDLE) {
                        // Call ended - could trigger overlay here if needed
                    }
                }
                TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                    Log.d(TAG, "Call answered/outgoing: $phoneNumber")
                    // Call started - could trigger overlay here if needed
                }
                TelephonyManager.EXTRA_STATE_RINGING -> {
                    Log.d(TAG, "Incoming call: $phoneNumber")
                    // Incoming call - could trigger overlay here if needed
                }
            }
        }
    }
}