/**
 * SynthEngine - High-fidelity mathematical procedural audio generator.
 * Synthesizes dynamic 44.1kHz stereo waveforms instantly in memory.
 */
class SynthEngine {
  constructor(audioContext) {
    this.ctx = audioContext;
    this.sampleRate = audioContext.sampleRate || 44100;
  }

  /**
   * Generates a dynamic audio buffer based on track preset index
   * @param {number} trackIndex - 0: Neon Horizon, 1: Chill Sunset, 2: Techno Pulse
   * @param {number} durationSeconds - length of track (default 180s)
   */
  generateTrack(trackIndex = 0, durationSeconds = 180) {
    const totalFrames = Math.floor(this.sampleRate * durationSeconds);
    const audioBuffer = this.ctx.createBuffer(2, totalFrames, this.sampleRate);
    const leftChannel = audioBuffer.getChannelData(0);
    const rightChannel = audioBuffer.getChannelData(1);

    const bpm = trackIndex === 2 ? 128 : (trackIndex === 0 ? 110 : 85);
    const beatDuration = 60.0 / bpm;
    const chordDuration = beatDuration * 4.0;

    // Chords definitions (Hz)
    const chordProgressions = [
      // Synthwave: Am - F - C - G
      [
        [220.0, 261.63, 329.63, 440.0],
        [174.61, 220.0, 261.63, 349.23],
        [261.63, 329.63, 392.0, 523.25],
        [196.0, 246.94, 293.66, 392.0]
      ],
      // Ambient Sunset: Dm9 - Bbmaj7 - Fmaj7 - C
      [
        [146.83, 220.0, 261.63, 329.63],
        [116.54, 174.61, 220.0, 293.66],
        [174.61, 220.0, 261.63, 329.63],
        [130.81, 196.0, 246.94, 329.63]
      ],
      // Techno Pulse: Em driving bass + resonant fifths
      [
        [164.81, 246.94, 329.63],
        [164.81, 246.94, 329.63],
        [146.83, 220.0, 293.66],
        [174.61, 261.63, 349.23]
      ]
    ];

    const currentProgression = chordProgressions[trackIndex] || chordProgressions[0];

    for (let i = 0; i < totalFrames; i++) {
      const t = i / this.sampleRate;
      const chordIndex = Math.floor(t / chordDuration) % currentProgression.length;
      const chord = currentProgression[chordIndex];
      const beatPos = (t % beatDuration) / beatDuration;
      const beatIndex = Math.floor(t / beatDuration);

      let sampleL = 0;
      let sampleR = 0;

      // 1. Pad / Chord Oscillators
      for (let c = 0; c < chord.length; c++) {
        const note = chord[c];
        const detuneL = 1.002;
        const detuneR = 0.998;
        const sawL = (2 * ((note * detuneL * t) % 1) - 1) * 0.05;
        const sawR = (2 * ((note * detuneR * t) % 1) - 1) * 0.05;
        const sine = Math.sin(2 * Math.PI * note * t) * 0.08;
        sampleL += sawL + sine;
        sampleR += sawR + sine;
      }

      // 2. Bassline (Arpeggiated)
      const bassRoot = chord[0] * 0.5; // Octave down
      const bassEnv = Math.exp(-beatPos * 4.0);
      const bassWave = Math.sin(2 * Math.PI * bassRoot * t) * 0.22 * bassEnv;
      sampleL += bassWave;
      sampleR += bassWave;

      // 3. Kick Drum (on every beat for techno/synthwave)
      if (trackIndex !== 1) { // Synthwave and Techno have kick
        const kickPitch = Math.max(45, 150 * Math.exp(-beatPos * 30.0));
        const kickEnv = Math.exp(-beatPos * 8.0);
        const kick = Math.sin(2 * Math.PI * kickPitch * t) * 0.35 * kickEnv;
        sampleL += kick;
        sampleR += kick;
      }

      // 4. Snare / Claps (on beats 2 & 4)
      if (beatIndex % 2 === 1 && beatPos < 0.2) {
        const noise = (Math.random() * 2 - 1) * 0.12 * Math.exp(-beatPos * 15.0);
        sampleL += noise;
        sampleR += noise;
      }

      // Soft Limiter / Saturation
      leftChannel[i] = Math.tanh(sampleL * 0.85);
      rightChannel[i] = Math.tanh(sampleR * 0.85);
    }

    return audioBuffer;
  }
}

window.SynthEngine = SynthEngine;
