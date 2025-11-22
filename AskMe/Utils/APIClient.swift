//
//  APIClient.swift
//  AskMe
//
//  Created by Franz Quarshie on 11/22/2025.
//

import Foundation

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "http://localhost:8080"
    
    private init() {}
    
    /// Fetch verifications for an ENS name
    func fetchVerifications(for ensName: String) async throws -> [Verification] {
        guard let url = URL(string: "\(baseURL)/api/verifications/\(ensName)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let verifications = try decoder.decode([Verification].self, from: data)
        
        return verifications
    }
    
    /// Fetch verification requests for an ENS name
    func fetchRequests(for ensName: String) async throws -> [VerificationRequest] {
        guard let url = URL(string: "\(baseURL)/api/requests/\(ensName)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let requests = try decoder.decode([VerificationRequest].self, from: data)
        
        return requests
    }
    
    /// Approve a verification request
    func approveRequest(_ id: String, fieldValue: String, subjectEns: String, verifiedEnsOwner: String?, revealMode: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/requests/\(id)/approve") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "fieldValue": fieldValue,
            "revealMode": revealMode
        ]
        
        if let owner = verifiedEnsOwner {
            body["verifiedEnsOwner"] = owner
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
    
    /// Reject a verification request
    func rejectRequest(_ id: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/requests/\(id)/reject") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
    
    /// Resolve ENS owner address
    func resolveEnsOwner(_ ensName: String) async throws -> EnsOwnerInfo {
        guard let url = URL(string: "\(baseURL)/api/resolveOwner/\(ensName)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let info = try decoder.decode(EnsOwnerInfo.self, from: data)
        
        return info
    }
}

struct EnsOwnerInfo: Codable {
    let ensName: String
    let owner: String?
    let expiry: String?
    let isValid: Bool
}

struct OwnershipVerification: Codable {
    let verified: Bool
    let ensName: String
    let address: String
    let message: String
}

extension APIClient {
    /// Verify ENS ownership with wallet signature
    func verifyOwnership(ensName: String, address: String, signature: String, message: String?) async throws -> OwnershipVerification {
        guard let url = URL(string: "\(baseURL)/api/verifyOwnership") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "ensName": ensName,
            "address": address,
            "signature": signature
        ]
        
        if let message = message {
            body["message"] = message
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? String {
                throw APIError.verificationFailed(error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let verification = try decoder.decode(OwnershipVerification.self, from: data)
        
        return verification
    }
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case verificationFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .verificationFailed(let message):
            return "Verification failed: \(message)"
        }
    }
}

