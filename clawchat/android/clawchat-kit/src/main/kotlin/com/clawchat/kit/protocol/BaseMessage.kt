package com.clawchat.kit.protocol

/** Base interface for all wire protocol messages. */
interface BaseMessage {
    val type: String
    val id: String
    val ts: Long
}
