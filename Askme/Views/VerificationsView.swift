//
//  VerificationsView.swift
//  AskMe
//
//  Created by Franz Quarshie on 11/22/2025.
//

import SwiftUI
import Combine

struct VerificationsView: View {
    @StateObject private var viewModel = VerificationsViewModel()
    @State private var subjectEns: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Text("Error")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task {
                                await viewModel.fetchVerifications(for: subjectEns)
                            }
                        }
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(FieldType.allCases) { fieldType in
                                FieldVerificationsSection(
                                    fieldType: fieldType,
                                    verifications: viewModel.getVerifications(for: fieldType)
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Verifications")
            .onAppear {
                loadSubjectEns()
                if !subjectEns.isEmpty {
                    Task {
                        await viewModel.fetchVerifications(for: subjectEns)
                    }
                }
            }
            .refreshable {
                if !subjectEns.isEmpty {
                    await viewModel.fetchVerifications(for: subjectEns)
                }
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
}

struct FieldVerificationsSection: View {
    let fieldType: FieldType
    let verifications: [Verification]
    
    var activeVerifications: [Verification] {
        verifications.filter { $0.status == "active" && ($0.isValid ?? true) }
    }
    
    var revokedVerifications: [Verification] {
        verifications.filter { $0.status == "revoked" || !($0.isValid ?? true) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(fieldType.displayName)
                .font(.headline)
            
            Text("\(activeVerifications.count) active, \(revokedVerifications.count) revoked")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if activeVerifications.isEmpty && revokedVerifications.isEmpty {
                Text("No verifications")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                if !activeVerifications.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Active")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        
                        ForEach(activeVerifications) { verification in
                            VerificationCard(verification: verification)
                        }
                    }
                }
                
                if !revokedVerifications.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Revoked/Invalid")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(revokedVerifications) { verification in
                            VerificationCard(verification: verification)
                                .opacity(0.6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct VerificationCard: View {
    let verification: Verification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(verification.verifierEnsSnapshot ?? verification.verifierAddress)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if verification.isValid == true {
                    Label("Valid", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Label("Invalid", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            if let methodUrl = verification.methodUrl {
                Link(destination: URL(string: methodUrl)!) {
                    HStack {
                        Text("Method")
                            .font(.caption)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            
            if let countVerified = verification.methodMeta?["countVerified"]?.value as? Int {
                Text("Total verified: \(countVerified)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Issued: \(formatDate(verification.issuedAt))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Expires: \(formatDate(verification.expiresAt))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if verification.isExpired == true {
                Text("Expired")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if verification.isEnsValid == false {
                Text("ENS Invalid")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

@MainActor
class VerificationsViewModel: ObservableObject {
    @Published var verifications: [Verification] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func fetchVerifications(for ensName: String) async {
        guard !ensName.isEmpty else { return }
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let fetched = try await APIClient.shared.fetchVerifications(for: ensName)
            await MainActor.run {
                self.verifications = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func getVerifications(for fieldType: FieldType) -> [Verification] {
        return verifications.filter { $0.field == fieldType.rawValue }
    }
}

