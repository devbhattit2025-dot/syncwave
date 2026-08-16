/**
 * AudioMeshEngine - Sample-Accurate Web Audio Engine with Room Role Filtering
 * Supports scheduled playback, micro-drift phase alignment, and 24-band FFT analysis.
 */
class AudioMeshEngine {
  constructor(ntpEngine) {
    this.ntp = ntpEngine;
    this.ctx = null;
    
    // Audio Nodes
    this.sourceNode = null;
    this.gainNode = null;
    this.pannerNode = null;
    this.lowPassNode = null;
    this.highPassNode = null;
    this.analyserNode = null;
    this.delayNode = null;

    // State
    this.currentBuffer = null;
    this.isPlaying = false;
    this.startMasterTime = 0; // The master NTP timestamp when playback started
    this.startOffsetSeconds = 0; // Where in the track playback started
    this.duration = 0;
    this.hardwareTrimMs = 0; // User slider offset (-100ms to +100ms)
    this.channelRole = 'boost'; // 'boost', 'left', 'right', 'sub', 'vocal'
    
    // Periodic drift monitoring timer
    this.driftMonitorTimer = null;
  }

  /**
   * Initializes the Web Audio Context on first user gesture
   */
  async initAudioContext() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      this.ctx = new AudioCtx({ latencyHint: 'interactive' });
      
      // Build Audio Graph:
      // Source -> Delay (Trim) -> HighPass -> LowPass -> Panner -> Gain -> Analyser -> Destination
      this.delayNode = this.ctx.createDelay(1.0);
      this.delayNode.delayTime.setValueAtTime(0.05, this.ctx.currentTime); // Base 50ms buffer

      this.highPassNode = this.ctx.createBiquadFilter();
      this.highPassNode.type = 'highpass';
      this.highPassNode.frequency.setValueAtTime(20, this.ctx.currentTime);

      this.lowPassNode = this.ctx.createBiquadFilter();
      this.lowPassNode.type = 'lowpass';
      this.lowPassNode.frequency.setValueAtTime(20000, this.ctx.currentTime);

      this.pannerNode = this.ctx.createStereoPanner ? this.ctx.createStereoPanner() : null;

      this.gainNode = this.ctx.createGain();
      this.gainNode.gain.setValueAtTime(1.0, this.ctx.currentTime);

      this.analyserNode = this.ctx.createAnalyser();
      this.analyserNode.fftSize = 1024;
      this.analyserNode.smoothingTimeConstant = 0.8;

      // Connect graph
      this.delayNode.connect(this.highPassNode);
      this.highPassNode.connect(this.lowPassNode);
      
      if (this.pannerNode) {
        this.lowPassNode.connect(this.pannerNode);
        this.pannerNode.connect(this.gainNode);
      } else {
        this.lowPassNode.connect(this.gainNode);
      }

      this.gainNode.connect(this.analyserNode);
      this.analyserNode.connect(this.ctx.destination);
    }

    if (this.ctx.state === 'suspended') {
      await this.ctx.resume();
    }
  }

  /**
   * Loads an ArrayBuffer (e.g. from user file or network chunk)
   */
  async loadAudioData(arrayBuffer) {
    await this.initAudioContext();
    this.currentBuffer = await this.ctx.decodeAudioData(arrayBuffer);
    this.duration = this.currentBuffer.duration;
    return this.duration;
  }

  /**
   * Set procedural buffer directly
   */
  setAudioBuffer(audioBuffer) {
    this.currentBuffer = audioBuffer;
    this.duration = audioBuffer.duration;
  }

  /**
   * Schedules audio to start exactly at targetMasterTimeMs at given track offset
   */
  async schedulePlaybackAtMasterTime(targetMasterTimeMs, offsetSeconds = 0) {
    await this.initAudioContext();
    this.stopPlayback();

    if (!this.currentBuffer) return;

    this.startMasterTime = targetMasterTimeMs;
    this.startOffsetSeconds = offsetSeconds;

    // Calculate how many milliseconds from NOW (in local audio context time) to start
    const nowMaster = this.ntp.getMasterTime();
    const timeDeltaMs = targetMasterTimeMs - nowMaster + this.hardwareTrimMs;
    
    // Map ms to AudioContext seconds
    const startAudioTime = Math.max(this.ctx.currentTime, this.ctx.currentTime + (timeDeltaMs / 1000.0));

    this.sourceNode = this.ctx.createBufferSource();
    this.sourceNode.buffer = this.currentBuffer;
    this.sourceNode.connect(this.delayNode);

    // Schedule sample-accurate start
    this.sourceNode.start(startAudioTime, offsetSeconds);
    this.isPlaying = true;

    // Start drift monitor loop
    this.startDriftMonitoring();
  }

  /**
   * Stops current playback immediately
   */
  stopPlayback() {
    this.stopDriftMonitoring();
    if (this.sourceNode) {
      try {
        this.sourceNode.stop();
        this.sourceNode.disconnect();
      } catch (e) {}
      this.sourceNode = null;
    }
    this.isPlaying = false;
  }

  /**
   * Monitor phase drift between this phone and master clock
   */
  startDriftMonitoring() {
    this.stopDriftMonitoring();
    this.driftMonitorTimer = setInterval(() => {
      if (!this.isPlaying || !this.startMasterTime) return;

      const currentMasterTime = this.ntp.getMasterTime();
      const elapsedMasterSeconds = (currentMasterTime - this.startMasterTime) / 1000.0;
      const expectedTrackPosition = this.startOffsetSeconds + elapsedMasterSeconds;

      if (expectedTrackPosition >= this.duration) {
        this.stopPlayback();
      }
    }, 200);
  }

  stopDriftMonitoring() {
    if (this.driftMonitorTimer) {
      clearInterval(this.driftMonitorTimer);
      this.driftMonitorTimer = null;
    }
  }

  /**
   * Applies Speaker Channel Role filters
   */
  setChannelRole(role) {
    this.channelRole = role;
    if (!this.ctx) return;

    const t = this.ctx.currentTime;
    switch (role) {
      case 'left':
        if (this.pannerNode) this.pannerNode.pan.setValueAtTime(-1.0, t);
        this.highPassNode.frequency.setValueAtTime(20, t);
        this.lowPassNode.frequency.setValueAtTime(20000, t);
        break;
      case 'right':
        if (this.pannerNode) this.pannerNode.pan.setValueAtTime(1.0, t);
        this.highPassNode.frequency.setValueAtTime(20, t);
        this.lowPassNode.frequency.setValueAtTime(20000, t);
        break;
      case 'sub':
        if (this.pannerNode) this.pannerNode.pan.setValueAtTime(0, t);
        this.highPassNode.frequency.setValueAtTime(20, t);
        this.lowPassNode.frequency.setValueAtTime(280, t); // Hard low-pass cutoff at 280 Hz
        break;
      case 'vocal':
        if (this.pannerNode) this.pannerNode.pan.setValueAtTime(0, t);
        this.highPassNode.frequency.setValueAtTime(450, t); // Cut boomy bass
        this.lowPassNode.frequency.setValueAtTime(12000, t);
        break;
      case 'boost':
      default:
        if (this.pannerNode) this.pannerNode.pan.setValueAtTime(0, t);
        this.highPassNode.frequency.setValueAtTime(20, t);
        this.lowPassNode.frequency.setValueAtTime(20000, t);
        break;
    }
  }

  /**
   * Sets hardware trim slider (-100ms to +100ms)
   */
  setHardwareTrim(trimMs) {
    this.hardwareTrimMs = trimMs;
    if (this.delayNode && this.ctx) {
      const baseDelay = 0.05; // 50ms base
      const targetDelay = Math.max(0.001, baseDelay + (trimMs / 1000.0));
      this.delayNode.delayTime.setValueAtTime(targetDelay, this.ctx.currentTime);
    }
  }

  /**
   * Plays a sharp 1000Hz calibration metronome click pulse to test phase
   */
  async playCalibrationPulse() {
    await this.initAudioContext();
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(1000, this.ctx.currentTime);
    gain.gain.setValueAtTime(0.5, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.08);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start();
    osc.stop(this.ctx.currentTime + 0.08);
  }

  /**
   * Returns current 24-band frequency spectrum array
   */
  getSpectrumData() {
    if (!this.analyserNode) return new Uint8Array(24);
    const dataArray = new Uint8Array(this.analyserNode.frequencyBinCount);
    this.analyserNode.getByteFrequencyData(dataArray);
    
    // Bin into 24 distinct logarithmic bands
    const bands = new Array(24).fill(0);
    const binCount = dataArray.length;
    for (let b = 0; b < 24; b++) {
      const startIdx = Math.floor(Math.pow(b / 24, 2) * binCount);
      const endIdx = Math.max(startIdx + 1, Math.floor(Math.pow((b + 1) / 24, 2) * binCount));
      let sum = 0;
      for (let i = startIdx; i < endIdx; i++) {
        sum += dataArray[i];
      }
      bands[b] = sum / (endIdx - startIdx);
    }
    return bands;
  }
}

window.AudioMeshEngine = AudioMeshEngine;
