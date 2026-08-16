//
//  MeshWebView.swift
//  SyncWave
//
//  Cross-Platform Synchronized Music Mesh Engine for iOS
//  Interoperable with Android APK and Web Mesh Nodes
//

import SwiftUI
import WebKit
import AVFoundation

struct MeshWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        // Configure AVAudioSession for background music playback and zero attenuation
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            try session.setActive(true)
        } catch {
            print("AVAudioSession configuration error: \(error)")
        }
        
        // Prevent iPhone from locking during party audio sync
        UIApplication.shared.isIdleTimerDisabled = true
        
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = preferences
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 10/255, green: 15/255, blue: 30/255, alpha: 1.0)
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // Find index.html inside the app bundle
        var loaded = false
        
        // 1. Check for index.html in main bundle root or app subdirectory
        if let localIndex = Bundle.main.url(forResource: "index", withExtension: "html") {
            let dir = localIndex.deletingLastPathComponent()
            webView.loadFileURL(localIndex, allowingReadAccessTo: dir)
            loaded = true
        } else if let localSub = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "app") {
            let dir = Bundle.main.bundleURL
            webView.loadFileURL(localSub, allowingReadAccessTo: dir)
            loaded = true
        } else if let resourceURL = Bundle.main.resourceURL {
            let appIndex = resourceURL.appendingPathComponent("app").appendingPathComponent("index.html")
            if FileManager.default.fileExists(atPath: appIndex.path) {
                webView.loadFileURL(appIndex, allowingReadAccessTo: resourceURL)
                loaded = true
            } else {
                let directIndex = resourceURL.appendingPathComponent("index.html")
                if FileManager.default.fileExists(atPath: directIndex.path) {
                    webView.loadFileURL(directIndex, allowingReadAccessTo: resourceURL)
                    loaded = true
                }
            }
        }
        
        // Fallback: If bundle assets were not packaged, load the hosted SyncWave web mesh
        if !loaded {
            if let webURL = URL(string: "https://devbhattit2025-dot.github.io/syncwave/app/") {
                let req = URLRequest(url: webURL)
                webView.load(req)
            }
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("SyncWave Mesh Audio Engine initialized on iOS successfully")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("SyncWave navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
    }
}
