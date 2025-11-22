//
//  MyFieldsView.swift
//  AskMe
//
//  Created by Franz Quarshie on 11/22/2025.
//

import SwiftUI
import Combine

struct MyFieldsView: View {
    @StateObject private var viewModel = FieldsViewModel()
    @StateObject private var walletManager = WalletManager.shared
    @State private var subjectEns: String = ""
    @State private var verifiedOwner: String? = nil
    @State private var isVerifying = false
    @State private var verificationError: String? = nil
    @State private var showingVerificationAlert = false
    @State private var showingWalletConnect = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Subject ENS")) {
                    TextField("example.eth", text: $subjectEns)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: subjectEns) { oldValue, newValue in
                            try? KeychainManager.shared.storeSubjectEns(newValue)
                            if oldValue != newValue {
                                verifiedOwner = nil
                                try? KeychainManager.shared.deleteVerifiedEnsOwner()
                            }
                        }
                    
                    if walletManager.isConnected, let address = walletManager.walletAddress {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Wallet Connected")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(address.prefix(6) + "..." + address.suffix(4))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    
                    if let owner = verifiedOwner {
                        HStack {
                            Text("Verified Owner:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(owner)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.green)
                        }
                        .padding(.top, 4)
                    }
                    
                    if !walletManager.isConnected {
                        Button(action: {
                            showingWalletConnect = true
                        }) {
                            HStack {
                                Image(systemName: "wallet.pass.fill")
                                Text("Connect Wallet")
                            }
                        }
                        .disabled(subjectEns.isEmpty)
                    }
                    
                    if walletManager.isConnected {
                        Button(action: {
                            verifyOwnershipWithWallet()
                        }) {
                            HStack {
                                if isVerifying {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Text(isVerifying ? "Verifying..." : verifiedOwner != nil ? "Re-verify Ownership" : "Verify Ownership with Wallet")
                            }
                        }
                        .disabled(isVerifying || subjectEns.isEmpty)
                    }
                    
                    if let error = verificationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Personal Fields")) {
                    if verifiedOwner == nil {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Please verify ENS ownership above before adding field values")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    ForEach(FieldType.allCases) { fieldType in
                        FieldRowView(
                            fieldType: fieldType,
                            value: viewModel.getValue(for: fieldType),
                            onSave: { newValue in
                                viewModel.save(field: fieldType, value: newValue)
                            },
                            isDisabled: verifiedOwner == nil
                        )
                    }
                }
                
                Section(header: Text("Coming Soon (Post-Hackathon)")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Custom Field")
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("custom_* (e.g., custom_contract, custom_certificate)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    }
                    .opacity(0.5)
                    .disabled(true)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Standard File")
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("Document, Image, or other file upload")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    }
                    .opacity(0.5)
                    .disabled(true)
                }
            }
            .navigationTitle("My Fields")
            .onAppear {
                loadSubjectEns()
                loadVerifiedOwner()
                viewModel.loadFields()
            }
            .alert("Verify Ownership", isPresented: $showingVerificationAlert) {
                Button("Cancel", role: .cancel) { }
                Button("I Own This Address") {
                    confirmOwnership()
                }
            } message: {
                if let owner = verifiedOwner {
                    Text("This ENS name resolves to:\n\n\(owner)\n\nDo you own this address? You'll need to sign with this wallet to approve requests.")
                }
            }
            .sheet(isPresented: $showingWalletConnect) {
                WalletConnectView()
            }
        }
    }
    
    private func loadSubjectEns() {
        do {
            subjectEns = try KeychainManager.shared.retrieveSubjectEns() ?? ""
        } catch {
            print("Error loading subject ENS: \(error)")
        }
    }
    
    private func loadVerifiedOwner() {
        do {
            verifiedOwner = try KeychainManager.shared.retrieveVerifiedEnsOwner()
        } catch {
            print("Error loading verified owner: \(error)")
        }
    }
    
    private func verifyOwnership() {
        guard !subjectEns.isEmpty else { return }
        
        isVerifying = true
        verificationError = nil
        
        Task {
            do {
                let info = try await APIClient.shared.resolveEnsOwner(subjectEns)
                
                await MainActor.run {
                    if let owner = info.owner, info.isValid {
                        verifiedOwner = owner
                        showingVerificationAlert = true
                    } else {
                        verificationError = "ENS name not found or expired"
                    }
                    isVerifying = false
                }
            } catch {
                await MainActor.run {
                    verificationError = "Failed to resolve ENS: \(error.localizedDescription)"
                    isVerifying = false
                }
            }
        }
    }
    
    private func verifyOwnershipWithWallet() {
        guard !subjectEns.isEmpty,
              walletManager.isConnected,
              let walletAddress = walletManager.walletAddress else {
            verificationError = "Please connect your wallet first"
            return
        }
        
        isVerifying = true
        verificationError = nil
        
        Task {
            do {
                let info = try await APIClient.shared.resolveEnsOwner(subjectEns)
                
                guard let ensOwner = info.owner, info.isValid else {
                    await MainActor.run {
                        verificationError = "ENS name not found or expired"
                        isVerifying = false
                    }
                    return
                }
                
                guard walletAddress.lowercased() == ensOwner.lowercased() else {
                    await MainActor.run {
                        verificationError = "Connected wallet does not own this ENS name. Expected: \(ensOwner)"
                        isVerifying = false
                    }
                    return
                }
                
                let message = walletManager.createOwnershipMessage(ensName: subjectEns)
                let signature = try await walletManager.signMessage(message)
                
                let verification = try await APIClient.shared.verifyOwnership(
                    ensName: subjectEns,
                    address: walletAddress,
                    signature: signature,
                    message: message
                )
                
                if verification.verified {
                    await MainActor.run {
                        verifiedOwner = walletAddress
                        try? KeychainManager.shared.storeVerifiedEnsOwner(walletAddress)
                        isVerifying = false
                    }
                } else {
                    await MainActor.run {
                        verificationError = "Ownership verification failed. Please ensure you're signing with the correct wallet."
                        isVerifying = false
                    }
                }
            } catch {
                await MainActor.run {
                    verificationError = error.localizedDescription
                    isVerifying = false
                }
            }
        }
    }
    
    private func confirmOwnership() {
        if let owner = verifiedOwner {
            do {
                try KeychainManager.shared.storeVerifiedEnsOwner(owner)
            } catch {
                verificationError = "Failed to save verification: \(error.localizedDescription)"
            }
        }
    }
    
    private func connectWallet() {
        showingWalletConnect = true
        Task {
            do {
                try await walletManager.connect()
            } catch {
                await MainActor.run {
                    verificationError = "Failed to connect wallet: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct FieldRowView: View {
    let fieldType: FieldType
    @State var value: String
    let onSave: (String) -> Void
    var isDisabled: Bool = false
    
    @State private var isEditing = false
    @State private var editingValue: String = ""
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(fieldType.displayName)
                    .font(.headline)
                
                if !value.isEmpty {
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Group {
                        let (valueHash, fieldHash) = CryptoUtils.computeHashes(field: fieldType, value: value)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("valueHash:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(valueHash)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.blue)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Text("fieldHash:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(fieldHash)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.blue)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                } else {
                    Text("Not set")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isDisabled {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .opacity(0.5)
            } else {
                Button(action: {
                    if isEditing {
                        onSave(editingValue)
                        value = editingValue
                        isEditing = false
                    } else {
                        editingValue = value
                        isEditing = true
                    }
                }) {
                    Text(isEditing ? "Save" : "Edit")
                }
            }
        }
        .opacity(isDisabled ? 0.6 : 1.0)
        .sheet(isPresented: $isEditing) {
            NavigationView {
                Form {
                    Section(header: Text(fieldType.displayName)) {
                        if fieldType == .dob {
                            TextField("YYYY-MM-DD", text: $editingValue)
                                .keyboardType(.default)
                        } else {
                            TextField("Enter value", text: $editingValue)
                                .textInputAutocapitalization(fieldType == .fullName ? .words : .none)
                                .autocorrectionDisabled()
                        }
                    }
                }
                .navigationTitle("Edit \(fieldType.displayName)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isEditing = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            onSave(editingValue)
                            value = editingValue
                            isEditing = false
                        }
                        .disabled(editingValue.isEmpty)
                    }
                }
            }
        }
    }
}

@MainActor
class FieldsViewModel: ObservableObject {
    @Published var fields: [FieldType: String] = [:]
    
    func loadFields() {
        for fieldType in FieldType.allCases {
            do {
                if let value = try KeychainManager.shared.retrieve(field: fieldType) {
                    fields[fieldType] = value
                }
            } catch {
                print("Error loading field \(fieldType.rawValue): \(error)")
            }
        }
    }
    
    func save(field: FieldType, value: String) {
        do {
            try KeychainManager.shared.store(field: field, value: value)
            fields[field] = value
        } catch {
            print("Error saving field \(field.rawValue): \(error)")
        }
    }
    
    func getValue(for field: FieldType) -> String {
        return fields[field] ?? ""
    }
}

