# SyncWave: Synchronized Audio for iOS (iPhone 11)

**SyncWave** is a professional, futuristic iOS application built with **Swift & SwiftUI** designed specifically for iPhone 11 (and compatible with iOS 15.0+ / 16 / 17 / 18).

The app explores synchronized audio playback through multiple connected audio devices, while strictly respecting Apple's public iOS audio-routing limitations.

---

## 🎯 Important Architectural Integrity & Technical Reality

iOS does **not** allow third-party applications to stream audio simultaneously to arbitrary independent Bluetooth A2DP devices using public APIs.
* **Apple Audio Sharing**: Handled exclusively at the operating system kernel level for supported Apple/Beats devices (H1/H2/W1 chipsets) via Control Center.
* **AVAudioSessionCategoryMultiRoute**: Allows simultaneous output only to physically supported multi-port configurations (e.g. USB Audio + Built-in Headphone Jack), but **not** multiple Bluetooth A2DP endpoints.
* **Public APIs Only**: SyncWave uses only standard public Apple APIs (`AVAudioSession`, `AVAudioEngine`, `AVAudioPlayerNode`, `MPNowPlayingInfoCenter`, `MPRemoteCommandCenter`, `Accelerate/vDSP`). No private frameworks, no jailbreak daemons, no DRM bypasses.

---

## ✨ Features

1. **Precision Audio Engine (`AVAudioEngine`)**:
   - Multi-node audio graph with player node, delay calibration, EQ, and time-pitch processing.
   - Real-time Accelerate/vDSP FFT spectrum visualizer (24 log frequency bands) and dual-channel VU meters.
   - Built-in procedural demo synth tracks (Synthwave, Electro Bass, Ambient Lo-Fi) and local audio file importer (`.mp3`, `.wav`, `.m4a`, `.flac`).

2. **Live Audio Route Diagnostics (`AVAudioSession`)**:
   - Real-time discovery and classification of Bluetooth A2DP, AirPlay, Wired Headphones, USB Audio, and Built-in Speakers.
   - Live route change notifications and port description inspections.
   - Hardware sample rate, I/O buffer duration, and driver latency metrics.

3. **MultiRoute Capability Probing**:
   - Runtime test suite to probe `AVAudioSessionCategoryMultiRoute` feasibility and display exact hardware diagnostic logs.

4. **Latency Synchronization Lab**:
   - Dynamic signal delay gauge (Buffer Latency + Driver Latency + User Offset).
   - Manual delay compensation slider (0ms – 400ms) to calibrate external speaker acoustic alignment.
   - Audible sync click pulse (metronome) for acoustic room synchronization.

5. **Official Apple Audio Sharing Guide**:
   - Interactive step-by-step visual walkthrough for enabling native dual Bluetooth audio on iPhone 11 via Control Center.

6. **Lock Screen & Control Center Integration**:
   - Full `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter` support for playback control and dynamic artwork.

---

## 📱 Sideloading on iPhone 11 (via Sideloadly)

SyncWave is 100% compliant with Sideloadly and standard free Apple ID developer certificates.

### Installation Steps:
1. **Download Sideloadly** on macOS or Windows: [https://sideloadly.io](https://sideloadly.io)
2. **Connect your iPhone 11** to your computer via USB-to-Lightning cable and trust the computer.
3. Open the project in Xcode and archive/export `SyncWave.ipa` (or drag the `SyncWave.app` / `.ipa` directly into Sideloadly).
4. Enter your Apple ID in Sideloadly to sign the application with a free 7-day personal provisioning profile.
5. Click **Start**.
6. Once installed on your iPhone 11:
   - Go to **Settings > General > VPN & Device Management**.
   - Select your Apple ID under *Developer App* and tap **Trust**.
   - Launch **SyncWave**!

---

## 📂 Project Structure

```
SyncWave/
├── SyncWave.xcodeproj/
│   └── project.pbxproj               # Xcode project build file
├── SyncWave/
│   ├── App/
│   │   └── SyncWaveApp.swift         # App entrypoint and lifecycle
│   ├── Models/
│   │   ├── AudioDevice.swift         # Detected port descriptions & metadata
│   │   ├── AudioRouteInfo.swift      # Live route snapshot & hardware metrics
│   │   ├── Track.swift               # Audio track model & waveform preview
│   │   └── SyncStatus.swift          # Honest synchronization status enum
│   ├── Audio/
│   │   ├── AudioManager.swift        # Central coordinator
│   │   ├── AudioSessionManager.swift # AVAudioSession & MultiRoute probe
│   │   ├── AudioRouteManager.swift   # Port monitoring & classification
│   │   ├── AudioEngineService.swift  # AVAudioEngine, player node & FFT tap
│   │   ├── AudioSynchronizer.swift   # Latency alignment & sync metronome
│   │   ├── NowPlayingManager.swift   # MPNowPlayingInfoCenter & MPRemote
│   │   └── AudioFileGenerator.swift  # Procedural WAV demo tracks
│   ├── Views/
│   │   ├── MainTabView.swift         # Glassmorphic floating tab bar
│   │   ├── Home/
│   │   │   ├── HomeView.swift        # Dashboard & active route summary
│   │   │   └── AudioVisualizerView.swift # FFT spectrum, orb & waveforms
│   │   ├── Player/
│   │   │   └── FullPlayerView.swift  # Full screen player & scrubber
│   │   ├── Devices/
│   │   │   ├── DevicesView.swift     # Audio routes & device cards
│   │   │   └── SyncLabView.swift     # Latency calibration & MultiRoute probe
│   │   ├── AudioSharing/
│   │   │   └── AudioSharingGuideView.swift # Apple Audio Sharing guide
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift    # Buffer & sample rate configuration
│   │   │   └── TechnicalLimitationsView.swift # iOS whitepaper
│   │   └── Components/
│   │       ├── GlowingBadge.swift
│   │       └── RoutePickerWrapper.swift
│   ├── Utilities/
│   │   ├── Theme.swift               # Design tokens, colors & modifiers
│   │   ├── HapticManager.swift       # Tactile feedback
│   │   ├── FFTCalculator.swift       # Accelerate vDSP spectrum analyzer
│   │   └── Extensions.swift          # Formatting & port helpers
│   └── Resources/
│       ├── Info.plist                # Background audio & file sharing
│       └── Assets.xcassets           # App icon & color sets
```
