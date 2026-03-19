/**
 * Base message envelope — every wire message includes these fields.
 */
export interface BaseMessage {
  /** Dot-delimited message type discriminator (e.g. "gateway.register") */
  type: string;
  /** UUIDv7 message identifier */
  id: string;
  /** Timestamp in milliseconds since Unix epoch */
  ts: number;
}
