/**
 * SyncWave Mesh - Main Application Controller
 */
document.addEventListener('DOMContentLoaded', async () => {
  // 1. Initialize Core Engines
  const ntp = new NTPEngine();
  const audioMesh = new AudioMeshEngine(ntp);
  const meshNet = new MeshNetwork(ntp);
  
  // UI References
  const connectionPill = document.getElementById('connectionPill');
  const connectionText = document.getElementById('connectionText');
  const btnModeHost = document.getElementById('btnModeHost');
  const btnModeJoin = document.getElementById('btnModeJoin');
  const hostPanel = document.getElementById('hostPanel');
  const joinPanel = document.getElementById('joinPanel');
  const btnCreateRoom = document.getElementById('btnCreateRoom');
  const btnJoinRoom = document.getElementById('btnJoinRoom');
  const inputRoomCode = document.getElementById('inputRoomCode');
  const displayRoomCode = document.getElementById('displayRoomCode');
  const qrCodeContainer = document.getElementById('qrCodeContainer');
  const qrcodeDiv = document.getElementById('qrcode');
  const peersList = document.getElementById('peersList');
  const peerCount = document.getElementById('peerCount');
  const syncJitterDisplay = document.getElementById('syncJitterDisplay');
  const currentTrackTitle = document.getElementById('currentTrackTitle');
  const currentTimeEl = document.getElementById('currentTime');
  const durationEl = document.getElementById('duration');
  const progressBar = document.getElementById('progressBar');
  const progressFill = document.getElementById('progressFill');
  const btnPlayPause = document.getElementById('btnPlayPause');
  const playIcon = document.getElementById('playIcon');
  const pauseIcon = document.getElementById('pauseIcon');
  const btnPrevTrack = document.getElementById('btnPrevTrack');
  const btnNextTrack = document.getElementById('btnNextTrack');
  const fileInput = document.getElementById('fileInput');
  const trackPills = document.querySelectorAll('.track-pill');
  const channelBtns = document.querySelectorAll('.channel-btn');
  const latencySlider = document.getElementById('latencySlider');
  const trimValueDisplay = document.getElementById('trimValueDisplay');
  const btnSyncMetronome = document.getElementById('btnSyncMetronome');
  const visualizerCanvas = document.getElementById('visualizerCanvas');

  // Initialize Canvas Visualizer
  const visualizer = new Visualizer(visualizerCanvas, audioMesh);

  // App State
  let currentTrackIndex = 0;
  const trackNames = [
    'Synthwave - Neon Horizon (110 BPM)',
    'Chillout - Sunset Ambient (85 BPM)',
    'Techno - Driving Pulse (128 BPM)'
  ];

  let synth = null;
  let isHost = true;
  let currentTrackDuration = 180;
  let qrCodeInstance = null;

  // Helper: Format seconds to MM:SS
  function formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
  }

  // Load track preset
  async function loadPresetTrack(index) {
    currentTrackIndex = index;
    currentTrackTitle.textContent = trackNames[index] || 'Custom Audio';
    
    trackPills.forEach((p, i) => {
      p.classList.toggle('active', i === index);
    });

    await audioMesh.initAudioContext();
    if (!synth) {
      synth = new SynthEngine(audioMesh.ctx);
    }

    const buffer = synth.generateTrack(index, 180);
    audioMesh.setAudioBuffer(buffer);
    currentTrackDuration = buffer.duration;
    durationEl.textContent = formatTime(currentTrackDuration);

    if (isHost && meshNet.connections.size > 0) {
      meshNet.broadcastCommand({
        action: 'SELECT_TRACK',
        trackIndex: index
      });
    }
  }

  // Initial load
  await loadPresetTrack(0);

  // 2. Tab Mode Switcher (Host vs Join)
  btnModeHost.addEventListener('click', () => {
    btnModeHost.classList.add('active');
    btnModeJoin.classList.remove('active');
    hostPanel.classList.remove('hidden');
    joinPanel.classList.add('hidden');
    isHost = true;
  });

  btnModeJoin.addEventListener('click', () => {
    btnModeJoin.classList.add('active');
    btnModeHost.classList.remove('active');
    joinPanel.classList.remove('hidden');
    hostPanel.classList.add('hidden');
    isHost = false;
  });

  // 3. Create Room (Host)
  btnCreateRoom.addEventListener('click', async () => {
    try {
      btnCreateRoom.textContent = 'Creating...';
      btnCreateRoom.disabled = true;

      const code = await meshNet.createRoom();
      displayRoomCode.textContent = code;
      btnCreateRoom.textContent = 'Room Active';
      
      // Generate QR code for instant phone camera scanning
      const joinUrl = `${window.location.origin}${window.location.pathname}?room=${code}`;
      qrCodeContainer.classList.remove('hidden');
      qrcodeDiv.innerHTML = '';
      qrCodeInstance = new QRCode(qrcodeDiv, {
        text: joinUrl,
        width: 140,
        height: 140,
        colorDark: '#000000',
        colorLight: '#ffffff',
        correctLevel: QRCode.CorrectLevel.M
      });

      connectionPill.className = 'status-pill status-connected';
      connectionText.textContent = `HOSTING ROOM: ${code}`;
    } catch (err) {
      console.error(err);
      btnCreateRoom.textContent = 'Retry Room';
      btnCreateRoom.disabled = false;
      alert('Could not start room. Check internet/network connection.');
    }
  });

  // 4. Join Room (Guest)
  btnJoinRoom.addEventListener('click', async () => {
    const code = inputRoomCode.value.trim().toUpperCase();
    if (!code) {
      alert('Please enter a room code.');
      return;
    }

    try {
      btnJoinRoom.textContent = 'Syncing...';
      btnJoinRoom.disabled = true;

      await meshNet.joinRoom(code);
      btnJoinRoom.textContent = 'Connected!';
      
      connectionPill.className = 'status-pill status-connected';
      connectionText.textContent = `SYNCED: ROOM ${code}`;
    } catch (err) {
      console.error(err);
      btnJoinRoom.textContent = 'Join & Sync';
      btnJoinRoom.disabled = false;
      alert(`Could not connect to Room ${code}. Make sure Host is online!`);
    }
  });

  // Auto-join if '?room=CODE' in URL
  const urlParams = new URLSearchParams(window.location.search);
  const autoRoom = urlParams.get('room');
  if (autoRoom) {
    btnModeJoin.click();
    inputRoomCode.value = autoRoom;
    setTimeout(() => btnJoinRoom.click(), 400);
  }

  // 5. Mesh Network Event Handlers
  meshNet.onPeerListChange = (peerIds) => {
    peerCount.textContent = peerIds.length;
    
    // Update connected devices UI
    const hostHtml = `
      <div class="peer-item host-peer">
        <span class="peer-icon">👑</span>
        <span class="peer-name">${isHost ? 'Host Phone (This Device)' : 'Party Host (Master Clock)'}</span>
        <span class="peer-badge">MASTER</span>
      </div>
    `;

    const clientsHtml = peerIds.map((id, index) => `
      <div class="peer-item">
        <span class="peer-icon">📱</span>
        <span class="peer-name">Phone #${index + 1} (${id.slice(-4).toUpperCase()})</span>
        <span class="peer-badge">SYNCED</span>
      </div>
    `).join('');

    peersList.innerHTML = hostHtml + clientsHtml;

    // Update boost multiplier badge based on phone count
    const totalPhones = peerIds.length + 1;
    const boostDb = Math.round(20 * Math.log10(totalPhones));
    const boostDisplay = document.getElementById('boostMultiplier');
    if (boostDisplay) {
      boostDisplay.textContent = `+${boostDb} dB (${totalPhones}x)`;
    }
  };

  ntp.onSyncUpdate = (data) => {
    syncJitterDisplay.textContent = `±${data.jitter.toFixed(1)} ms`;
  };

  meshNet.onCommandReceived = async (payload) => {
    console.log('[MeshNetwork] Received Command:', payload);
    switch (payload.action) {
      case 'PLAY':
        await audioMesh.schedulePlaybackAtMasterTime(payload.targetMasterTime, payload.offsetSeconds);
        playIcon.classList.add('hidden');
        pauseIcon.classList.remove('hidden');
        break;

      case 'PAUSE':
        audioMesh.stopPlayback();
        playIcon.classList.remove('hidden');
        pauseIcon.classList.add('hidden');
        break;

      case 'SELECT_TRACK':
        await loadPresetTrack(payload.trackIndex);
        break;

      case 'CALIBRATION_PULSE':
        audioMesh.playCalibrationPulse();
        break;
    }
  };

  meshNet.onAudioDataReceived = async (arrayBuffer, metadata) => {
    await audioMesh.loadAudioData(arrayBuffer);
    currentTrackTitle.textContent = metadata.name || 'Shared Audio File';
    durationEl.textContent = formatTime(audioMesh.duration);
  };

  // 6. Play / Pause Control
  btnPlayPause.addEventListener('click', async () => {
    await audioMesh.initAudioContext();

    if (audioMesh.isPlaying) {
      // Pause
      audioMesh.stopPlayback();
      playIcon.classList.remove('hidden');
      pauseIcon.classList.add('hidden');

      if (isHost) {
        meshNet.broadcastCommand({ action: 'PAUSE' });
      }
    } else {
      // Play in sync across all phones
      // Schedule playback 350ms in the future to allow network propagation
      const leadTimeMs = 350;
      const targetMasterTime = ntp.getMasterTime() + leadTimeMs;

      await audioMesh.schedulePlaybackAtMasterTime(targetMasterTime, 0);
      playIcon.classList.add('hidden');
      pauseIcon.classList.remove('hidden');

      if (isHost) {
        meshNet.broadcastCommand({
          action: 'PLAY',
          targetMasterTime: targetMasterTime,
          offsetSeconds: 0
        });
      }
    }
  });

  // Track Selector buttons
  trackPills.forEach((btn) => {
    btn.addEventListener('click', () => {
      const idx = parseInt(btn.getAttribute('data-track'), 10);
      loadPresetTrack(idx);
    });
  });

  // Next / Prev track
  btnNextTrack.addEventListener('click', () => {
    const nextIdx = (currentTrackIndex + 1) % trackNames.length;
    loadPresetTrack(nextIdx);
  });

  btnPrevTrack.addEventListener('click', () => {
    const prevIdx = (currentTrackIndex - 1 + trackNames.length) % trackNames.length;
    loadPresetTrack(prevIdx);
  });

  // User Local File Upload
  fileInput.addEventListener('change', async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const arrayBuffer = await file.arrayBuffer();
    await audioMesh.loadAudioData(arrayBuffer);
    currentTrackTitle.textContent = `📁 ${file.name}`;
    durationEl.textContent = formatTime(audioMesh.duration);

    if (isHost && meshNet.connections.size > 0) {
      meshNet.broadcastAudioData(arrayBuffer, { name: file.name });
    }
  });

  // 7. Channel Role Selection
  channelBtns.forEach((btn) => {
    btn.addEventListener('click', () => {
      channelBtns.forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');
      const role = btn.getAttribute('data-channel');
      audioMesh.setChannelRole(role);
    });
  });

  // 8. Latency Trim Slider
  latencySlider.addEventListener('input', (e) => {
    const val = parseInt(e.target.value, 10);
    trimValueDisplay.textContent = `${val > 0 ? '+' : ''}${val} ms`;
    audioMesh.setHardwareTrim(val);
  });

  // 9. Sync Calibration Pulse Metronome
  btnSyncMetronome.addEventListener('click', () => {
    audioMesh.playCalibrationPulse();
    if (isHost) {
      meshNet.broadcastCommand({ action: 'CALIBRATION_PULSE' });
    }
  });

  // 10. Progress Bar Animation Loop
  setInterval(() => {
    if (audioMesh.isPlaying && audioMesh.duration > 0) {
      const nowMaster = ntp.getMasterTime();
      const elapsed = Math.max(0, (nowMaster - audioMesh.startMasterTime) / 1000.0);
      const currentPos = Math.min(elapsed, audioMesh.duration);
      
      currentTimeEl.textContent = formatTime(currentPos);
      const pct = (currentPos / audioMesh.duration) * 100;
      progressFill.style.width = `${pct}%`;
    }
  }, 100);
});
