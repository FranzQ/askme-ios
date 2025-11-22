//
//  RequestsView.swift
//  AskMe
//
//  Created by Franz Quarshie on 11/22/2025.
//

import SwiftUI
import Combine

struct RequestsView: View {
    @StateObject private var viewModel = RequestsViewModel()
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
                            viewModel.fetchRequests(for: subjectEns)
                        }
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if viewModel.pendingRequests.isEmpty && viewModel.otherRequests.isEmpty {
                                Text("No verification requests")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                if !viewModel.pendingRequests.isEmpty {
                                    Section {
                                        Text("Pending Requests")
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        ForEach(viewModel.pendingRequests) { request in
                                            RequestCard(
                                                request: request,
                                                onApprove: nil,
                                                onApproveWithMode: { fieldValue, revealMode in
                                                    viewModel.approveRequest(request.id, fieldValue: fieldValue, subjectEns: subjectEns, revealMode: revealMode)
                                                },
                                                onReject: {
                                                    viewModel.rejectRequest(request.id)
                                                }
                                            )
                                        }
                                    }
                                }
                                
                                if !viewModel.otherRequests.isEmpty {
                                    Section {
                                        Text("Other Requests")
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        ForEach(viewModel.otherRequests) { request in
                                            RequestCard(request: request, onApprove: nil, onApproveWithMode: nil, onReject: nil)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Requests")
            .onAppear {
                loadSubjectEns()
                if !subjectEns.isEmpty {
                    viewModel.fetchRequests(for: subjectEns)
                }
            }
            .refreshable {
                if !subjectEns.isEmpty {
                    await viewModel.fetchRequests(for: subjectEns)
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

struct RequestCard: View {
    let request: VerificationRequest
    let onApprove: ((String) -> Void)?
    let onApproveWithMode: ((String, String) -> Void)?
    let onReject: (() -> Void)?
    
    @State private var showingApproveDialog = false
    @State private var fieldValue: String = ""
    @State private var isProcessing = false
    @State private var fieldExists: Bool = false
    @State private var hasCheckedField: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.verifierEns ?? formatAddress(request.verifierAddress))
                        .font(.headline)
                    
                    Text(FieldType(rawValue: request.field)?.displayName ?? request.field)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Requested: \(formatDate(request.requestedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let approvedAt = request.approvedAt {
                        Text("Approved: \(formatDate(approvedAt))")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                StatusBadge(status: request.status)
            }
            
            if request.status == "pending" && (onApprove != nil || onApproveWithMode != nil) && onReject != nil {
                VStack(alignment: .leading, spacing: 8) {
                    if hasCheckedField {
                        if !fieldExists {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Field not set. Please set \(FieldType(rawValue: request.field)?.displayName ?? request.field) in \"My Fields\" first.")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Field value found. Ready to approve.")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            if fieldExists {
                                showingApproveDialog = true
                            }
                        }) {
                            Text("Approve")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(fieldExists ? Color.green : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(!fieldExists)
                        
                        Button(action: {
                            onReject?()
                        }) {
                            Text("Reject")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onAppear {
            checkFieldExists()
        }
        .sheet(isPresented: $showingApproveDialog) {
            NavigationView {
                Form {
                    Section(header: Text("Field Value")) {
                        Text(fieldValue)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.vertical, 8)
                    }
                    .disabled(true)
                    
                    Section(header: Text("Approve Options")) {
                        Button(action: {
                            if !fieldValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onApproveWithMode?(fieldValue, "reveal")
                                showingApproveDialog = false
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Approve & Reveal")
                                    .font(.headline)
                                Text("Verifier will see the value. It expires after 1 hour.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Button(action: {
                            if !fieldValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onApproveWithMode?(fieldValue, "no-reveal")
                                showingApproveDialog = false
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Approve (No Reveal)")
                                    .font(.headline)
                                Text("Verifier must type the value. Only matches if correct.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .navigationTitle("Approve Request")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingApproveDialog = false
                        }
                    }
                }
            }
        }
    }
    
    private func checkFieldExists() {
        guard let fieldType = FieldType(rawValue: request.field) else {
            hasCheckedField = true
            fieldExists = false
            return
        }
        
        do {
            if let value = try KeychainManager.shared.retrieve(field: fieldType), !value.isEmpty {
                fieldValue = value
                fieldExists = true
            } else {
                fieldExists = false
            }
        } catch {
            print("Error checking field: \(error)")
            fieldExists = false
        }
        
        hasCheckedField = true
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count >= 10 else { return address }
        let start = address.prefix(6)
        let end = address.suffix(4)
        return "\(start)...\(end)"
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

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(4)
    }
    
    var backgroundColor: Color {
        switch status {
        case "pending":
            return .yellow.opacity(0.3)
        case "approved":
            return .green.opacity(0.3)
        case "rejected":
            return .red.opacity(0.3)
        case "completed":
            return .blue.opacity(0.3)
        case "expired":
            return .gray.opacity(0.3)
        default:
            return .gray.opacity(0.3)
        }
    }
    
    var foregroundColor: Color {
        switch status {
        case "pending":
            return .yellow
        case "approved":
            return .green
        case "rejected":
            return .red
        case "completed":
            return .blue
        case "expired":
            return .gray
        default:
            return .gray
        }
    }
}

@MainActor
class RequestsViewModel: ObservableObject {
    @Published var requests: [VerificationRequest] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    var pendingRequests: [VerificationRequest] {
        requests.filter { $0.status == "pending" }
    }
    
    var otherRequests: [VerificationRequest] {
        requests.filter { $0.status != "pending" }
    }
    
    func fetchRequests(for ensName: String) {
        guard !ensName.isEmpty else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let fetched = try await APIClient.shared.fetchRequests(for: ensName)
                await MainActor.run {
                    self.requests = fetched
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    func approveRequest(_ id: String, fieldValue: String, subjectEns: String, revealMode: String) {
        isLoading = true
        
        let verifiedOwner = try? KeychainManager.shared.retrieveVerifiedEnsOwner()
        
        Task {
            do {
                try await APIClient.shared.approveRequest(id, fieldValue: fieldValue, subjectEns: subjectEns, verifiedEnsOwner: verifiedOwner, revealMode: revealMode)
                await MainActor.run {
                    self.isLoading = false
                    fetchRequests(for: subjectEns)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.error = error
                }
            }
        }
    }
    
    func rejectRequest(_ id: String) {
        isLoading = true
        Task {
            do {
                try await APIClient.shared.rejectRequest(id)
                await MainActor.run {
                    self.isLoading = false
                    if let firstRequest = requests.first {
                        fetchRequests(for: firstRequest.verifiedEns)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.error = error
                }
            }
        }
    }
}

