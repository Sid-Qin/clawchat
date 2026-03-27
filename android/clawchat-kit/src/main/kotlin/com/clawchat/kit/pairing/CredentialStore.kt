package com.clawchat.kit.pairing

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

/** Stored ClawChat credentials. */
data class ClawChatCredentials(
    val deviceToken: String,
    val relayUrl: String,
    val gatewayId: String,
)

private const val PREF_FILE = "clawchat_credentials"
private const val KEY_DEVICE_TOKEN = "deviceToken"
private const val KEY_RELAY_URL = "relayUrl"
private const val KEY_GATEWAY_ID = "gatewayId"

/**
 * Manages credential persistence using EncryptedSharedPreferences.
 */
class CredentialStore(context: Context) {
    private val prefs: SharedPreferences

    init {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        prefs = EncryptedSharedPreferences.create(
            context,
            PREF_FILE,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    /** Save credentials after successful pairing. */
    fun save(deviceToken: String, relayUrl: String, gatewayId: String) {
        prefs.edit()
            .putString(KEY_DEVICE_TOKEN, deviceToken)
            .putString(KEY_RELAY_URL, relayUrl)
            .putString(KEY_GATEWAY_ID, gatewayId)
            .apply()
    }

    /** Load stored credentials, returns null if any are missing. */
    fun load(): ClawChatCredentials? {
        val deviceToken = prefs.getString(KEY_DEVICE_TOKEN, null) ?: return null
        val relayUrl = prefs.getString(KEY_RELAY_URL, null) ?: return null
        val gatewayId = prefs.getString(KEY_GATEWAY_ID, null) ?: return null
        return ClawChatCredentials(deviceToken, relayUrl, gatewayId)
    }

    /** Clear all stored credentials. */
    fun clear() {
        prefs.edit()
            .remove(KEY_DEVICE_TOKEN)
            .remove(KEY_RELAY_URL)
            .remove(KEY_GATEWAY_ID)
            .apply()
    }
}
