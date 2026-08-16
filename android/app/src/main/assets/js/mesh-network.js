/**
 * MeshNetwork - WebRTC Peer-to-Peer Multi-Device Sync Broker
 * Connects Android & iOS devices directly over local network / internet without servers.
 */
class MeshNetwork {
  constructor(ntpEngine) {
    this.ntp = ntpEngine;
    this.peer = null;
    this.isHost = false;
    this.roomCode = null;
    this.connections = new Map(); // peerId -> DataConnection
    this.onPeerListChange = null;
    this.onCommandReceived = null;
    this.onAudioDataReceived = null;
  }

  /**
   * Generates a clean 4-digit room code
   */
  generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < 4; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
  }

  /**
   * Host creates a room
   */
  createRoom(roomCode = null) {
    this.isHost = true;
    this.roomCode = roomCode || this.generateRoomCode();
    const peerId = `syncwave-${this.roomCode.toLowerCase()}`;

    return new Promise((resolve, reject) => {
      this.peer = new Peer(peerId, {
        debug: 1,
        config: {
          iceServers: [
            { urls: 'stun:stun.l.google.com:19302' },
            { urls: 'stun:global.stun.twilio.com:3478' }
          ]
        }
      });

      this.peer.on('open', (id) => {
        console.log(`[MeshNetwork] Room created with code: ${this.roomCode} (Peer: ${id})`);
        resolve(this.roomCode);
      });

      this.peer.on('connection', (conn) => {
        this.setupConnection(conn);
      });

      this.peer.on('error', (err) => {
        console.warn('[MeshNetwork] Peer error:', err);
        // If room code taken, generate new one and retry
        if (err.type === 'unavailable-id') {
          resolve(this.createRoom());
        } else {
          reject(err);
        }
      });
    });
  }

  /**
   * Client joins a host's room
   */
  joinRoom(roomCode) {
    this.isHost = false;
    this.roomCode = roomCode.toUpperCase().trim();
    const targetPeerId = `syncwave-${this.roomCode.toLowerCase()}`;

    return new Promise((resolve, reject) => {
      this.peer = new Peer({
        debug: 1,
        config: {
          iceServers: [
            { urls: 'stun:stun.l.google.com:19302' },
            { urls: 'stun:global.stun.twilio.com:3478' }
          ]
        }
      });

      this.peer.on('open', () => {
        console.log(`[MeshNetwork] Connecting to Host: ${targetPeerId}...`);
        const conn = this.peer.connect(targetPeerId, {
          reliable: true
        });

        conn.on('open', () => {
          console.log('[MeshNetwork] Connected to Room Host successfully!');
          this.setupConnection(conn);
          // Start continuous NTP sync pings
          this.startNTPClientLoop(conn);
          resolve(this.roomCode);
        });

        conn.on('error', (err) => {
          reject(err);
        });
      });

      this.peer.on('error', (err) => {
        reject(err);
      });
    });
  }

  /**
   * Sets up event listeners on a peer DataConnection
   */
  setupConnection(conn) {
    this.connections.set(conn.peer, conn);
    this.notifyPeerList();

    conn.on('data', (data) => {
      this.handleIncomingData(conn, data);
    });

    conn.on('close', () => {
      this.connections.delete(conn.peer);
      this.notifyPeerList();
    });

    conn.on('error', () => {
      this.connections.delete(conn.peer);
      this.notifyPeerList();
    });
  }

  /**
   * Handles incoming message packet
   */
  handleIncomingData(conn, data) {
    if (!data) return;

    // 1. NTP Ping on Host
    if (data.type === 'NTP_PING' && this.isHost) {
      const pong = this.ntp.handlePingOnHost(data);
      conn.send(pong);
      return;
    }

    // 2. NTP Pong on Client
    if (data.type === 'NTP_PONG' && !this.isHost) {
      this.ntp.handlePongOnClient(data);
      return;
    }

    // 3. Playback / State Commands
    if (data.type === 'COMMAND') {
      if (this.onCommandReceived) {
        this.onCommandReceived(data.payload);
      }
      return;
    }

    // 4. Raw Audio Buffer Data
    if (data.type === 'AUDIO_PAYLOAD') {
      if (this.onAudioDataReceived) {
        this.onAudioDataReceived(data.buffer, data.metadata);
      }
      return;
    }
  }

  /**
   * Starts high-frequency NTP ping loop from client to host
   */
  startNTPClientLoop(conn) {
    const sendPing = () => {
      if (conn.open) {
        conn.send(this.ntp.createPingPacket());
      }
    };

    // Rapid burst of 10 pings at start to converge clock quickly
    for (let i = 0; i < 8; i++) {
      setTimeout(sendPing, i * 80);
    }

    // Periodic heartbeat sync every 1.5 seconds
    setInterval(sendPing, 1500);
  }

  /**
   * Broadcasts a command to all connected peers
   */
  broadcastCommand(payload) {
    const packet = {
      type: 'COMMAND',
      payload: payload
    };

    for (const [peerId, conn] of this.connections) {
      if (conn.open) {
        conn.send(packet);
      }
    }
  }

  /**
   * Broadcasts audio file / buffer to all peers
   */
  broadcastAudioData(arrayBuffer, metadata) {
    const packet = {
      type: 'AUDIO_PAYLOAD',
      buffer: arrayBuffer,
      metadata: metadata
    };

    for (const [peerId, conn] of this.connections) {
      if (conn.open) {
        conn.send(packet);
      }
    }
  }

  notifyPeerList() {
    if (this.onPeerListChange) {
      this.onPeerListChange(Array.from(this.connections.keys()));
    }
  }
}

window.MeshNetwork = MeshNetwork;
