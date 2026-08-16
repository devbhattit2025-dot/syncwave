/**
 * NTP Engine - Sub-millisecond Monotonic Clock Synchronization
 * Calculates Round Trip Time (RTT), one-way latency, and precise Clock Offset (theta)
 * across connected Android & iOS devices.
 */
class NTPEngine {
  constructor() {
    this.clockOffset = 0; // HostTime = LocalTime + clockOffset (in ms)
    this.rtt = 0;
    this.jitter = 0;
    this.sampleHistory = [];
    this.maxSamples = 12;
    this.isCalibrated = false;
    this.onSyncUpdate = null;
  }

  /**
   * Returns current high-precision monotonic timestamp in milliseconds
   */
  now() {
    return performance.now() + (performance.timeOrigin || 0);
  }

  /**
   * Returns estimated synchronized Master (Host) time
   */
  getMasterTime() {
    return this.now() + this.clockOffset;
  }

  /**
   * Client sends ping with t0
   */
  createPingPacket() {
    return {
      type: 'NTP_PING',
      t0: this.now()
    };
  }

  /**
   * Host processes ping and attaches t1 (receive) and t2 (transmit)
   */
  handlePingOnHost(packet) {
    const t1 = this.now();
    return {
      type: 'NTP_PONG',
      t0: packet.t0,
      t1: t1,
      t2: this.now()
    };
  }

  /**
   * Client receives pong at t3, calculates RTT and Clock Offset
   */
  handlePongOnClient(packet) {
    const t3 = this.now();
    const t0 = packet.t0;
    const t1 = packet.t1;
    const t2 = packet.t2;

    const rtt = (t3 - t0) - (t2 - t1);
    const offset = ((t1 - t0) + (t2 - t3)) / 2;

    // Filter out aberrant RTT spikes (e.g. WiFi packet retries)
    this.sampleHistory.push({ rtt, offset });
    if (this.sampleHistory.length > this.maxSamples) {
      this.sampleHistory.shift();
    }

    // Sort by lowest RTT (lowest RTT contains lowest asymmetry error)
    const sorted = [...this.sampleHistory].sort((a, b) => a.rtt - b.rtt);
    // Take average of the best 3 samples
    const bestSamples = sorted.slice(0, Math.min(3, sorted.length));
    const avgOffset = bestSamples.reduce((sum, s) => sum + s.offset, 0) / bestSamples.length;
    const avgRTT = bestSamples.reduce((sum, s) => sum + s.rtt, 0) / bestSamples.length;

    // Calculate jitter
    const jitter = Math.abs(rtt - avgRTT);

    this.clockOffset = avgOffset;
    this.rtt = avgRTT;
    this.jitter = jitter;
    this.isCalibrated = true;

    if (this.onSyncUpdate) {
      this.onSyncUpdate({
        offset: this.clockOffset,
        rtt: this.rtt,
        jitter: this.jitter,
        calibrated: this.isCalibrated
      });
    }
  }

  reset() {
    this.clockOffset = 0;
    this.rtt = 0;
    this.jitter = 0;
    this.sampleHistory = [];
    this.isCalibrated = false;
  }
}

window.NTPEngine = NTPEngine;
