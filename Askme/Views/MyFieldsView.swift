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
    @State private var ensNames: [String] = []
    @State private var selectedEns: String = ""
    @State private var verifiedOwner: String? = nil
    @State private var isVerifying = false
    @State private var verificationError: String? = nil
    @State private var showingVerificationAlert = false
    @State private var showingWalletConnect = false
    @State private var isLoadingEnsNames = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ENS name and wallet")) {
                    // Show primary ENS name (read-only for hackathon)
                    if let primaryEns = ensNames.first {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text(primaryEns)
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } else if !isLoadingEnsNames {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text(walletManager.isConnected ? "No ENS name found for this wallet" : "Connect wallet to see your ENS name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if isLoadingEnsNames {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading ENS names...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
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
                    }
                    
                }
                
                Section(header: Text("Personal Fields")) {
                    if selectedEns.isEmpty {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Select an ENS name above to manage fields")
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
                                viewModel.save(field: fieldType, value: newValue, ensName: selectedEns)
                            },
                            isDisabled: selectedEns.isEmpty
                        )
                    }
                }
                
                Section(header: Text("Coming Soon")) {
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
                loadEnsNames()
                loadSelectedEns()
                loadVerifiedOwner()
                if !selectedEns.isEmpty {
                    viewModel.loadFields(for: selectedEns)
                }
                
                // Fetch ENS names when wallet connects
                if walletManager.isConnected {
                    fetchEnsNamesFromWallet()
                }
            }
            .onChange(of: walletManager.isConnected) { oldValue, newValue in
                if newValue {
                    fetchEnsNamesFromWallet()
                } else {
                    // Clear ENS names when wallet disconnects (security)
                    ensNames = []
                    selectedEns = ""
                    verifiedOwner = nil
                    try? KeychainManager.shared.storeEnsNames([])
                    try? KeychainManager.shared.storeSubjectEns("")
                    try? KeychainManager.shared.deleteVerifiedEnsOwner()
                }
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
    
    private func loadEnsNames() {
        do {
            ensNames = try KeychainManager.shared.retrieveEnsNames()
        } catch {
            print("Error loading ENS names: \(error)")
            ensNames = []
        }
    }
    
    private func loadSelectedEns() {
        do {
            let savedEns = try KeychainManager.shared.retrieveSubjectEns() ?? ""
            selectedEns = savedEns
            // Load fields for the saved ENS name
            if !savedEns.isEmpty {
                viewModel.loadFields(for: savedEns)
            }
        } catch {
            print("Error loading selected ENS: \(error)")
            selectedEns = ""
        }
    }
    
    private func selectEns(_ ensName: String) {
        // Only reload if switching to a different ENS name
        guard selectedEns != ensName else { return }
        
        selectedEns = ensName
        try? KeychainManager.shared.storeSubjectEns(ensName)
        verifiedOwner = nil
        try? KeychainManager.shared.deleteVerifiedEnsOwner()
        
        // Clear fields first to ensure UI updates
        viewModel.fields.removeAll()
        
        // Reload fields for the selected ENS name
        viewModel.loadFields(for: ensName)
        print("Switched to ENS: \(ensName), loading fields...")
    }
    
    private func fetchEnsNamesFromWallet() {
        guard let address = walletManager.walletAddress else { return }
        
        isLoadingEnsNames = true
        Task {
            do {
                let fetchedNames = try await APIClient.shared.fetchEnsNames(for: address)
                
                await MainActor.run {
                    // Only use names fetched from the wallet (security: no manual additions)
                    ensNames = fetchedNames
                    try? KeychainManager.shared.storeEnsNames(ensNames)
                    
                           // Auto-select primary name (first in list)
                           if let primaryEns = ensNames.first {
                               selectEns(primaryEns)
                           } else {
                               // No ENS name found, clear selection
                               selectedEns = ""
                               try? KeychainManager.shared.storeSubjectEns("")
                           }
                    
                    isLoadingEnsNames = false
                }
            } catch {
                await MainActor.run {
                    print("Error fetching ENS names: \(error)")
                    isLoadingEnsNames = false
                }
            }
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
        guard !selectedEns.isEmpty else { return }
        
        isVerifying = true
        verificationError = nil
        
        Task {
            do {
                let info = try await APIClient.shared.resolveEnsOwner(selectedEns)
                
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
        guard !selectedEns.isEmpty,
              walletManager.isConnected,
              let walletAddress = walletManager.walletAddress else {
            verificationError = "Please connect your wallet first"
            return
        }
        
        isVerifying = true
        verificationError = nil
        
        Task {
            do {
                let info = try await APIClient.shared.resolveEnsOwner(selectedEns)
                
                guard info.owner != nil, info.isValid else {
                    await MainActor.run {
                        verificationError = "ENS name not found or expired"
                        isVerifying = false
                    }
                    return
                }
                
                // Note: With real WalletConnect, users connect the wallet that owns the ENS name
                // The server will verify ownership via signature verification, so we can skip
                // the client-side check for demo purposes. In production, you may want to keep
                // this check for better UX (fail fast before signing).
                
                let message = walletManager.createOwnershipMessage(ensName: selectedEns)
                let signature = try await walletManager.signMessage(message)
                
                let verification = try await APIClient.shared.verifyOwnership(
                    ensName: selectedEns,
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
    var currentEnsName: String = ""
    
    func loadFields(for ensName: String) {
        print("🔄 loadFields called for ENS: \(ensName)")
        currentEnsName = ensName
        
        // Clear all fields first to ensure UI updates
        fields.removeAll()
        
        // Force UI update by publishing the change
        objectWillChange.send()
        
        guard !ensName.isEmpty else {
            print("⚠️ ENS name is empty, not loading fields")
            return
        }
        
        // Load fields for the new ENS name
        var newFields: [FieldType: String] = [:]
        for fieldType in FieldType.allCases {
            do {
                if let value = try KeychainManager.shared.retrieve(field: fieldType, ensName: ensName) {
                    newFields[fieldType] = value
                    print("✅ Loaded \(fieldType.rawValue) = \(value) for \(ensName)")
                } else {
                    print("ℹ️ No value found for \(fieldType.rawValue) in \(ensName)")
                }
            } catch {
                print("❌ Error loading field \(fieldType.rawValue): \(error)")
            }
        }
        
        // Update fields all at once to trigger UI update
        fields = newFields
        print("📊 Total fields loaded: \(fields.count) for \(ensName)")
    }
    
    func save(field: FieldType, value: String, ensName: String) {
        guard !ensName.isEmpty else { return }
        
        do {
            try KeychainManager.shared.store(field: field, value: value, ensName: ensName)
            fields[field] = value
        } catch {
            print("Error saving field \(field.rawValue): \(error)")
        }
    }
    
    func getValue(for field: FieldType) -> String {
        return fields[field] ?? ""
    }
}

