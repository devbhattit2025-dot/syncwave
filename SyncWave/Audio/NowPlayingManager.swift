//
//  NowPlayingManager.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import Foundation
import MediaPlayer
import UIKit

/// Manages system Lock Screen and Control Center Now Playing integration.
final class NowPlayingManager {
    static let shared = NowPlayingManager()
    
    var onPlayCommand: (() -> Void)?
    var onPauseCommand: (() -> Void)?
    var onToggleCommand: (() -> Void)?
    var onNextCommand: (() -> Void)?
    var onPreviousCommand: (() -> Void)?
    var onSeekCommand: ((TimeInterval) -> Void)?
    
    private init() {
        setupRemoteCommands()
    }
    
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.onPlayCommand?()
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.onPauseCommand?()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.onToggleCommand?()
            return .success
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.onNextCommand?()
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.onPreviousCommand?()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let posEvent = event as? MPChangePlaybackPositionCommandEvent {
                self?.onSeekCommand?(posEvent.positionTime)
                return .success
            }
            return .commandFailed
        }
    }
    
    /// Updates MPNowPlayingInfoCenter with current track information
    func updateNowPlaying(track: Track?, isPlaying: Bool, currentTime: TimeInterval, duration: TimeInterval) {
        guard let track = track else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = track.title
        info[MPMediaItemPropertyArtist] = track.artist
        info[MPMediaItemPropertyAlbumTitle] = track.album
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // Render artwork
        let artworkImage = generateArtworkImage(symbolName: track.artworkSystemName)
        let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 512, height: 512)) { _ in
            return artworkImage
        }
        info[MPMediaItemPropertyArtwork] = artwork
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func generateArtworkImage(symbolName: String) -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Dark gradient background
            let colors = [
                UIColor(red: 0.04, green: 0.06, blue: 0.09, alpha: 1.0).cgColor,
                UIColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 1.0).cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 512, y: 512), options: [])
            
            // Draw Icon
            let config = UIImage.SymbolConfiguration(pointSize: 180, weight: .bold)
            if let symbol = UIImage(systemName: symbolName, withConfiguration: config)?
                .withTintColor(UIColor(red: 0.02, green: 0.71, blue: 0.83, alpha: 1.0), renderingMode: .alwaysOriginal) {
                let rect = CGRect(x: (512 - symbol.size.width) / 2, y: (512 - symbol.size.height) / 2, width: symbol.size.width, height: symbol.size.height)
                symbol.draw(in: rect)
            }
        }
    }
}
