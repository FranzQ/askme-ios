//
//  ShareView.swift
//  AskMe
//
//  Created by Franz Quarshie on 11/22/2025.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ShareView: View {
    @StateObject private var viewModel = FieldsViewModel()
    @State private var subjectEns: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Section {
                        Text("Subject ENS")
                            .font(.headline)
                        Text(subjectEns.isEmpty ? "Not set" : subjectEns)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    ForEach(FieldType.allCases) { fieldType in
                        FieldShareCard(
                            fieldType: fieldType,
                            value: viewModel.getValue(for: fieldType),
                            subjectEns: subjectEns
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Share")
            .onAppear {
                loadSubjectEns()
                if !subjectEns.isEmpty {
                    viewModel.loadFields(for: subjectEns)
                }
            }
            .onChange(of: subjectEns) { oldValue, newValue in
                if !newValue.isEmpty {
                    viewModel.loadFields(for: newValue)
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

struct FieldShareCard: View {
    let fieldType: FieldType
    let value: String
    let subjectEns: String
    
    @State private var copied = false
    
    var valueHash: String? {
        guard !value.isEmpty else { return nil }
        let (hash, _) = CryptoUtils.computeHashes(field: fieldType, value: value)
        return hash
    }
    
    var fieldHash: String? {
        guard !value.isEmpty else { return nil }
        let (_, hash) = CryptoUtils.computeHashes(field: fieldType, value: value)
        return hash
    }
    
    var qrData: String? {
        guard !subjectEns.isEmpty, let valueHash = valueHash else { return nil }
        let data: [String: String] = [
            "ens": subjectEns,
            "field": fieldType.rawValue,
            "valueHash": valueHash
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(fieldType.displayName)
                .font(.headline)
            
            if let valueHash = valueHash, let fieldHash = fieldHash {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Value Hash:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(valueHash)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text("Field Hash:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(fieldHash)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    HStack {
                        Button(action: {
                            UIPasteboard.general.string = fieldHash
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        }) {
                            HStack {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "Copied!" : "Copy Hash")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                    }
                    
                    if let qrData = qrData, let qrImage = generateQRCode(from: qrData) {
                        VStack(spacing: 8) {
                            Text("QR Code (JSON: ens, field, valueHash)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                    }
                }
            } else {
                Text("Field not set")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
}

