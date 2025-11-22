//
//  LogoutView.swift
//  AskMe
//
//  Logout view to disconnect wallet
//

import SwiftUI

struct LogoutView: View {
    @StateObject private var walletManager = WalletManager.shared
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "person.crop.circle.badge.xmark")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                if walletManager.isConnected {
                    VStack(spacing: 16) {
                        Text("Wallet Connected")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let address = walletManager.walletAddress {
                            Text(address)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        if let walletName = walletManager.connectedWalletName {
                            Text(walletName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("No Wallet Connected")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Connect a wallet to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if walletManager.isConnected {
                    Button(action: {
                        showingLogoutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Disconnect Wallet")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .confirmationDialog(
                        "Disconnect Wallet?",
                        isPresented: $showingLogoutConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Disconnect", role: .destructive) {
                            walletManager.disconnect()
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will disconnect your wallet. You'll need to reconnect to use the app.")
                    }
                } else {
                    NavigationLink(destination: WalletConnectView()) {
                        HStack {
                            Image(systemName: "wallet.pass.fill")
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
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Account")
        }
    }
}

#Preview {
    LogoutView()
}

