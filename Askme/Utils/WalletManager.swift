//
//  WalletManager.swift
//  AskMe
//
//  Wallet manager using WalletConnect v2
//  For hackathon: Simplified implementation
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
    @Published var pairingURI: String? = nil
    
    private let projectId = "YOUR_WALLETCONNECT_PROJECT_ID"
    
    let useMockMode = true
    
    private init() {}
    
    func connect() async throws {
        isConnecting = true
        connectionError = nil
        
        if useMockMode {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            
            let mockAddress = "0x1234567890123456789012345678901234567890"
            
            await MainActor.run {
                walletAddress = mockAddress
                connectedWalletName = "MetaMask (Demo)"
                isConnected = true
                isConnecting = false
            }
            return
        }
        
        await MainActor.run {
            isConnecting = false
        }
        
        throw WalletError.notImplemented
    }
    
    func disconnect() {
        isConnected = false
        walletAddress = nil
        connectedWalletName = nil
        connectionError = nil
        pairingURI = nil
    }
    
    func signMessage(_ message: String) async throws -> String {
        guard isConnected, let address = walletAddress else {
            throw WalletError.notConnected
        }
        
        if useMockMode {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            let mockSignature = "0x" + String(repeating: "0", count: 128) + "1b"
            return mockSignature
        }
        
        throw WalletError.notImplemented
    }
    
    func signTypedData(_ typedData: [String: Any]) async throws -> String {
        guard isConnected, walletAddress != nil else {
            throw WalletError.notConnected
        }
        
        throw WalletError.notImplemented
    }
    
    func createOwnershipMessage(ensName: String) -> String {
        return "Verify ENS ownership: \(ensName)\n\nThis signature proves you own the ENS name."
    }
}

enum WalletError: Error {
    case notConnected
    case notImplemented
    case signingFailed
    case connectionCancelled
    
    var localizedDescription: String {
        switch self {
        case .notConnected:
            return "Wallet not connected. Please connect your wallet first."
        case .notImplemented:
            return "WalletConnect SDK not yet integrated. Using demo mode."
        case .signingFailed:
            return "Failed to sign message. Please try again."
        case .connectionCancelled:
            return "Wallet connection was cancelled."
        }
    }
}

