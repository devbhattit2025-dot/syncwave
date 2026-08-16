/**
 * Visualizer - Real-time 24-Band Neon Spectrum Canvas Analyzer
 */
class Visualizer {
  constructor(canvasElement, audioMeshEngine) {
    this.canvas = canvasElement;
    this.ctx = canvasElement.getContext('2d');
    this.audioMesh = audioMeshEngine;
    this.decayBands = new Array(24).fill(0);
    this.peakBands = new Array(24).fill(0);
    this.animationId = null;

    this.resize();
    window.addEventListener('resize', () => this.resize());
    this.start();
  }

  resize() {
    const rect = this.canvas.getBoundingClientRect();
    this.canvas.width = rect.width * (window.devicePixelRatio || 1);
    this.canvas.height = rect.height * (window.devicePixelRatio || 1);
  }

  start() {
    if (this.animationId) return;
    const render = () => {
      this.draw();
      this.animationId = requestAnimationFrame(render);
    };
    render();
  }

  stop() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
      this.animationId = null;
    }
  }

  draw() {
    const width = this.canvas.width;
    const height = this.canvas.height;
    const ctx = this.ctx;

    // Clear background
    ctx.clearRect(0, 0, width, height);

    // Get current spectrum
    const currentBands = this.audioMesh.getSpectrumData();
    const barCount = 24;
    const totalSpacing = 4 * (barCount - 1);
    const barWidth = Math.max(3, (width - totalSpacing - 20) / barCount);
    const startX = 10;

    for (let i = 0; i < barCount; i++) {
      const rawVal = (currentBands[i] || 0) / 255.0;
      
      // Decay physics
      if (rawVal > this.decayBands[i]) {
        this.decayBands[i] = rawVal;
      } else {
        this.decayBands[i] = Math.max(0, this.decayBands[i] - 0.04);
      }

      // Peak hold physics
      if (this.decayBands[i] > this.peakBands[i]) {
        this.peakBands[i] = this.decayBands[i];
      } else {
        this.peakBands[i] = Math.max(0, this.peakBands[i] - 0.015);
      }

      const val = this.decayBands[i];
      const barHeight = Math.max(4, val * (height - 30));
      const x = startX + i * (barWidth + 4);
      const y = height - barHeight - 10;

      // Color gradient per frequency band: Cyan (Bass) -> Purple (Mids) -> Magenta (Highs)
      const gradient = ctx.createLinearGradient(0, height, 0, 0);
      if (i < 8) {
        gradient.addColorStop(0, '#00f2fe');
        gradient.addColorStop(1, '#4facfe');
      } else if (i < 16) {
        gradient.addColorStop(0, '#9d4edd');
        gradient.addColorStop(1, '#c77dff');
      } else {
        gradient.addColorStop(0, '#ff007f');
        gradient.addColorStop(1, '#ff758c');
      }

      // Draw glowing bar
      ctx.fillStyle = gradient;
      ctx.shadowColor = i < 8 ? '#00f2fe' : (i < 16 ? '#9d4edd' : '#ff007f');
      ctx.shadowBlur = val > 0.4 ? 12 : 0;
      
      ctx.beginPath();
      ctx.roundRect(x, y, barWidth, barHeight, [4, 4, 0, 0]);
      ctx.fill();

      // Draw peak hold dot
      const peakY = height - (this.peakBands[i] * (height - 30)) - 14;
      ctx.fillStyle = '#ffffff';
      ctx.shadowBlur = 4;
      ctx.shadowColor = '#ffffff';
      ctx.fillRect(x, Math.max(4, peakY), barWidth, 2);
    }
  }
}

window.Visualizer = Visualizer;
