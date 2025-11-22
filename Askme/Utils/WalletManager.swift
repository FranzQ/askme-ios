//
//  WalletManager.swift
//  AskMe
//
//  Simple mock wallet manager for hackathon demo
//  TODO: Replace with real WalletConnect integration later
//

import Foundation
import SwiftUI
import Combine

@MainActor
class WalletManager: ObservableObject {
    static let shared = WalletManager()
    
    @Published var isConnected = false
    @Published var walletAddress: String? = nil
    @Published var connectedWalletName: String? = nil
    @Published var isConnecting = false
    @Published var connectionError: String? = nil
    
    // Real Sepolia wallet address with ENS names for demo
    private let demoWalletAddress = "0xC273AeC12Ea77df19c3C60818c962f7624Dc764A"
    
    private init() {
        // Check if we have a saved wallet address, otherwise use demo address
        if let savedAddress = UserDefaults.standard.string(forKey: "mockWalletAddress") {
            walletAddress = savedAddress
            isConnected = true
        }
    }
    
    func connect() async throws {
        isConnecting = true
        connectionError = nil
        
        // Simulate connection delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Use real Sepolia wallet address with ENS names
        walletAddress = demoWalletAddress
        connectedWalletName = "Demo Wallet (Sepolia)"
        isConnected = true
        isConnecting = false
        
        // Save for persistence
        UserDefaults.standard.set(demoWalletAddress, forKey: "mockWalletAddress")
    }
    
    func disconnect() {
        isConnected = false
        walletAddress = nil
        connectedWalletName = nil
        connectionError = nil
        UserDefaults.standard.removeObject(forKey: "mockWalletAddress")
    }
    
    func signMessage(_ message: String) async throws -> String {
        guard isConnected, walletAddress != nil else {
            throw WalletError.notConnected
        }
        
        // Mock signature - in real implementation, this would use WalletConnect signing
        // For demo purposes, return a mock signature
        let mockSignature = "0x" + (0..<130).map { _ in String("0123456789abcdef".randomElement()!) }.joined()
        return mockSignature
    }
    
    func signTypedData(_ typedData: [String: Any]) async throws -> String {
        guard isConnected, walletAddress != nil else {
            throw WalletError.notConnected
        }
        
        // Mock signature - in real implementation, this would use WalletConnect signing
        let mockSignature = "0x" + (0..<130).map { _ in String("0123456789abcdef".randomElement()!) }.joined()
        return mockSignature
    }
    
    func createOwnershipMessage(ensName: String) -> String {
        return "Verify ENS ownership: \(ensName)\n\nThis signature proves you own the ENS name."
    }
}

enum WalletError: Error {
    case notConnected
    case notConfigured
    case notImplemented
    case signingFailed
    case connectionCancelled
    case connectionTimeout
    
    var localizedDescription: String {
        switch self {
        case .notConnected:
            return "Wallet not connected. Please connect your wallet first."
        case .notConfigured:
            return "WalletConnect not configured. Please set WALLETCONNECT_PROJECT_ID."
        case .notImplemented:
            return "WalletConnect integration not yet implemented. Please check ReownAppKit documentation."
        case .signingFailed:
            return "Failed to sign message. Please try again."
        case .connectionCancelled:
            return "Wallet connection was cancelled."
        case .connectionTimeout:
            return "Connection timeout. Please try again."
        }
    }
}
