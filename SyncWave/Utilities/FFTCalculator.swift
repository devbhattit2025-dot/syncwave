//
//  FFTCalculator.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import Foundation
import Accelerate
import AVFoundation

/// Fast Fourier Transform and Audio Spectrum Calculator using Accelerate (vDSP)
final class FFTCalculator {
    private let fftSize: Int
    private let log2n: vDSP_Length
    private var fftSetup: vDSP_DFT_Setup?
    
    private var window: [Float]
    private var realBuffer: [Float]
    private var imagBuffer: [Float]
    private var magnitudes: [Float]
    private var smoothedBands: [Float]
    
    let numberOfBands: Int
    
    init(fftSize: Int = 1024, numberOfBands: Int = 24) {
        self.fftSize = fftSize
        self.numberOfBands = numberOfBands
        self.log2n = vDSP_Length(log2(Double(fftSize)))
        
        self.window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        
        self.realBuffer = [Float](repeating: 0, count: fftSize)
        self.imagBuffer = [Float](repeating: 0, count: fftSize)
        self.magnitudes = [Float](repeating: 0, count: fftSize / 2)
        self.smoothedBands = [Float](repeating: 0.05, count: numberOfBands)
        
        self.fftSetup = vDSP_DFT_zrop_CreateSetup(
            nil,
            vDSP_Length(fftSize),
            vDSP_DFT_Direction.FORWARD
        )
    }
    
    deinit {
        if let setup = fftSetup {
            vDSP_DFT_DestroySetup(setup)
        }
    }
    
    /// Processes an incoming PCM buffer into normalized frequency spectrum bands [0.0 ... 1.0]
    func calculateSpectrum(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData?[0] else {
            return decayBands()
        }
        
        let frameCount = Int(buffer.frameLength)
        guard frameCount >= fftSize else {
            return decayBands()
        }
        
        // 1. Copy sample frames and apply Hann Window
        var windowedSamples = [Float](repeating: 0, count: fftSize)
        for i in 0..<fftSize {
            windowedSamples[i] = channelData[i] * window[i]
        }
        
        // 2. Separate into real/imaginary parts
        windowedSamples.withUnsafeBufferPointer { ptr in
            ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftSize / 2) { complexPtr in
                var splitComplex = DSPSplitComplex(
                    realp: &realBuffer,
                    imagp: &imagBuffer
                )
                vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
            }
        }
        
        // 3. Execute DFT
        if let setup = fftSetup {
            var splitComplex = DSPSplitComplex(
                realp: &realBuffer,
                imagp: &imagBuffer
            )
            vDSP_DFT_Execute(setup, splitComplex.realp, splitComplex.imagp, splitComplex.realp, splitComplex.imagp)
            
            // 4. Calculate magnitudes
            vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
        }
        
        // 5. Convert to Logarithmic Scale & Bin into Frequency Bands
        var newBands = [Float](repeating: 0, count: numberOfBands)
        let binCount = fftSize / 2
        
        for bandIndex in 0..<numberOfBands {
            // Log-scale band distribution across frequencies (20Hz to 20kHz)
            let lowFreqRatio = pow(Double(bandIndex) / Double(numberOfBands), 2.5)
            let highFreqRatio = pow(Double(bandIndex + 1) / Double(numberOfBands), 2.5)
            
            let startBin = max(1, min(Int(lowFreqRatio * Double(binCount)), binCount - 1))
            let endBin = max(startBin + 1, min(Int(highFreqRatio * Double(binCount)), binCount))
            
            var sum: Float = 0
            for bin in startBin..<endBin {
                sum += magnitudes[bin]
            }
            let avg = sum / Float(max(1, endBin - startBin))
            
            // Normalize with logarithmic compression (decibel-like response)
            let dB = 10 * log10(max(avg, 1e-6))
            // Clamp and map dB roughly -60dB -> 0dB to 0.0 -> 1.0
            let normalized = max(0.02, min(1.0, (dB + 50.0) / 50.0))
            newBands[bandIndex] = normalized
        }
        
        // 6. Smooth transitions (fast rise, gentle exponential decay)
        for i in 0..<numberOfBands {
            if newBands[i] > smoothedBands[i] {
                smoothedBands[i] = smoothedBands[i] * 0.3 + newBands[i] * 0.7
            } else {
                smoothedBands[i] = smoothedBands[i] * 0.75 + newBands[i] * 0.25
            }
            smoothedBands[i] = max(0.04, min(1.0, smoothedBands[i]))
        }
        
        return smoothedBands
    }
    
    /// Smooth decay when audio is paused or silent
    func decayBands() -> [Float] {
        for i in 0..<numberOfBands {
            smoothedBands[i] = max(0.02, smoothedBands[i] * 0.85)
        }
        return smoothedBands
    }
    
    /// Calculate peak RMS level for stereo balance meters
    static func calculateRMS(from buffer: AVAudioPCMBuffer) -> (left: Float, right: Float) {
        guard let channelData = buffer.floatChannelData else { return (0, 0) }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return (0, 0) }
        
        var leftRMS: Float = 0
        vDSP_rmsqv(channelData[0], 1, &leftRMS, vDSP_Length(frameLength))
        
        var rightRMS: Float = leftRMS
        if buffer.format.channelCount > 1 {
            vDSP_rmsqv(channelData[1], 1, &rightRMS, vDSP_Length(frameLength))
        }
        
        return (min(1.0, leftRMS * 2.5), min(1.0, rightRMS * 2.5))
    }
}
