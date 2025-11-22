//
//  WalletConnectView.swift
//  AskMe
//
//  WalletConnect connection UI
//

import SwiftUI

@MainActor
struct WalletConnectView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var walletManager = WalletManager.shared
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Connect Wallet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Connect your wallet to verify ENS ownership and approve verification requests")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if walletManager.isConnecting {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Connecting to wallet...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Please approve the connection in your wallet app")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if walletManager.isConnected {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 50))
                        Text("Connected!")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        if let walletName = walletManager.connectedWalletName {
                            Text(walletName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let address = walletManager.walletAddress {
                            VStack(spacing: 4) {
                                Text("Address:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(address)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding()
                        }
                        
                        Button(action: {
                            walletManager.disconnect()
                            dismiss()
                        }) {
                            Text("Disconnect")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                } else {
                    Button(action: {
                        connectWallet()
                    }) {
                        HStack {
                            Image(systemName: "qrcode")
                            Text("Connect Wallet")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    if walletManager.useMockMode {
                        VStack(spacing: 8) {
                            Text("Demo Mode")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                            Text("Using mock wallet connection for demo. Add WalletConnect SDK for production.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Wallet Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                if walletManager.isConnected {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func connectWallet() {
        errorMessage = nil
        
        Task {
            do {
                try await walletManager.connect()
                if walletManager.isConnected {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        dismiss()
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

