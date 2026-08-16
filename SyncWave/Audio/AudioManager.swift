//
//  AudioManager.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

/// Central coordinator for SyncWave audio services, route handling, playback, and visualizer stream.
@MainActor
final class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    // Sub-services
    let sessionManager = AudioSessionManager.shared
    let routeManager = AudioRouteManager.shared
    let audioEngine = AudioEngineService.shared
    let synchronizer = AudioSynchronizer.shared
    let nowPlaying = NowPlayingManager.shared
    
    // MARK: - Published State
    
    @Published var playlist: [Track] = []
    @Published var currentTrack: Track?
    @Published var currentTrackIndex: Int = 0
    
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 1.0 {
        didSet {
            audioEngine.volume = volume
        }
    }
    
    @Published var spectrumBands: [Float] = [Float](repeating: 0.05, count: 24)
    @Published var leftMeterLevel: Float = 0.0
    @Published var rightMeterLevel: Float = 0.0
    
    @Published var syncStatus: SyncStatus = .noDevice
    @Published var routeInfo: AudioRouteInfo = AudioRouteInfo()
    @Published var multiRouteProbeLog: String = ""
    @Published var isFilePickerPresented: Bool = false
    @Published var showingAudioSharingGuide: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
        setupNowPlayingCommands()
        initializeAudio()
    }
    
    // MARK: - Initialization & Bindings
    
    private func setupBindings() {
        // Audio Engine bindings
        audioEngine.onSpectrumCalculated = { [weak self] bands in
            self?.spectrumBands = bands
        }
        
        audioEngine.onLevelsCalculated = { [weak self] left, right in
            self?.leftMeterLevel = left
            self?.rightMeterLevel = right
        }
        
        audioEngine.onPlaybackFinished = { [weak self] in
            self?.playNextTrack()
        }
        
        // Route Manager bindings
        routeManager.$currentRouteInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                self?.routeInfo = info
                self?.synchronizer.updateLatencies()
            }
            .store(in: &cancellables)
        
        routeManager.$currentSyncStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.syncStatus = status
            }
            .store(in: &cancellables)
        
        // Progress observation
        audioEngine.$currentTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                guard let self = self else { return }
                self.currentTime = time
                self.updateNowPlayingState()
            }
            .store(in: &cancellables)
        
        audioEngine.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playing in
                self?.isPlaying = playing
                self?.updateNowPlayingState()
            }
            .store(in: &cancellables)
    }
    
    private func setupNowPlayingCommands() {
        nowPlaying.onPlayCommand = { [weak self] in
            self?.play()
        }
        nowPlaying.onPauseCommand = { [weak self] in
            self?.pause()
        }
        nowPlaying.onToggleCommand = { [weak self] in
            self?.togglePlayPause()
        }
        nowPlaying.onNextCommand = { [weak self] in
            self?.playNextTrack()
        }
        nowPlaying.onPreviousCommand = { [weak self] in
            self?.playPreviousTrack()
        }
        nowPlaying.onSeekCommand = { [weak self] time in
            self?.seek(to: time)
        }
    }
    
    private func initializeAudio() {
        _ = sessionManager.configurePlaybackSession()
        routeManager.refreshRoutes(reasonDescription: "Engine Launch")
        
        // Load synthesized demo tracks
        let demoTracks = AudioFileGenerator.shared.prepareDemoTracks()
        self.playlist = demoTracks
        
        if let first = demoTracks.first {
            selectTrack(first, autoPlay: false)
        }
    }
    
    // MARK: - Playback Actions
    
    func selectTrack(_ track: Track, autoPlay: Bool = true) {
        guard let url = track.fileURL else { return }
        
        let success = audioEngine.loadFile(url: url)
        if success {
            self.currentTrack = track
            self.duration = audioEngine.duration
            self.currentTime = 0
            if let idx = playlist.firstIndex(where: { $0.id == track.id }) {
                self.currentTrackIndex = idx
            }
            
            if autoPlay {
                play()
            }
            updateNowPlayingState()
            HapticManager.selectionChanged()
        }
    }
    
    func play() {
        guard currentTrack != nil else {
            if let first = playlist.first {
                selectTrack(first, autoPlay: true)
            }
            return
        }
        audioEngine.play()
        HapticManager.lightImpact()
        updateNowPlayingState()
    }
    
    func pause() {
        audioEngine.pause()
        HapticManager.lightImpact()
        updateNowPlayingState()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func playNextTrack() {
        guard !playlist.isEmpty else { return }
        let nextIndex = (currentTrackIndex + 1) % playlist.count
        selectTrack(playlist[nextIndex], autoPlay: isPlaying)
    }
    
    func playPreviousTrack() {
        guard !playlist.isEmpty else { return }
        if currentTime > 3.0 {
            seek(to: 0)
        } else {
            let prevIndex = (currentTrackIndex - 1 + playlist.count) % playlist.count
            selectTrack(playlist[prevIndex], autoPlay: isPlaying)
        }
    }
    
    func seek(to time: TimeInterval) {
        audioEngine.seek(to: time)
        self.currentTime = time
        updateNowPlayingState()
    }
    
    // MARK: - Track Import
    
    /// Imports a user audio file from UIDocumentPicker / SwiftUI fileImporter
    func importTrack(from sourceURL: URL) {
        let isSecurityScoped = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
            let destinationURL = documentsDir.appendingPathComponent(sourceURL.lastPathComponent)
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            // Read duration using AVURLAsset
            let asset = AVURLAsset(url: destinationURL)
            let durationSeconds = CMTimeGetSeconds(asset.duration)
            let validDuration = (durationSeconds.isNaN || durationSeconds.isInfinite) ? 180.0 : durationSeconds
            
            let trackTitle = sourceURL.deletingPathExtension().lastPathComponent
            let newTrack = Track(
                title: trackTitle,
                artist: "Imported Local Audio",
                album: "User Library",
                duration: validDuration,
                fileURL: destinationURL,
                isLocalDemo: false,
                artworkSystemName: "music.note",
                accentGradient: [Theme.accentGreen, Theme.accentCyan],
                waveformSamples: Track.generateDefaultWaveform(count: 50),
                formatDescription: destinationURL.pathExtension.uppercased() + " Audio"
            )
            
            playlist.append(newTrack)
            selectTrack(newTrack, autoPlay: true)
            HapticManager.success()
        } catch {
            print("[AudioManager] Failed to import audio file: \(error.localizedDescription)")
            HapticManager.error()
        }
    }
    
    // MARK: - MultiRoute & Diagnostic Testing
    
    /// Executes the MultiRoute probe on the underlying AVAudioSession
    func probeMultiRoute() {
        let result = sessionManager.probeMultiRouteCategory()
        self.multiRouteProbeLog = result.message
        routeManager.refreshRoutes(reasonDescription: "MultiRoute Probe")
        if result.success {
            HapticManager.success()
        } else {
            HapticManager.warning()
        }
    }
    
    func revertToStandardSession() {
        sessionManager.revertToStandardPlayback()
        self.multiRouteProbeLog = "Reverted to standard AVAudioSessionCategoryPlayback."
        routeManager.refreshRoutes(reasonDescription: "Reverted to Standard")
        HapticManager.lightImpact()
    }
    
    // MARK: - Now Playing
    
    private func updateNowPlayingState() {
        nowPlaying.updateNowPlaying(
            track: currentTrack,
            isPlaying: isPlaying,
            currentTime: currentTime,
            duration: duration
        )
    }
}
