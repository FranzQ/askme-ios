//
//  Field.swift
//  AskMe
//
//  Created by Franz Quarshie on 11/22/2025.
//

import Foundation

enum FieldType: String, CaseIterable, Identifiable, Codable {
    case fullName = "full_name"
    case dob = "dob"
    case passportId = "passport_id"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .fullName:
            return "Full Name"
        case .dob:
            return "Date of Birth"
        case .passportId:
            return "Passport/ID Number"
        }
    }
}

struct FieldValue: Codable {
    let type: FieldType
    let value: String
    let valueHash: String
    let fieldHash: String
    let updatedAt: Date
}

struct Verification: Codable, Identifiable {
    let id: String
    let verifiedEns: String
    let field: String
    let fieldHash: String
    let verifierType: String
    let verifierId: String
    let ensName: String?
    let ownerSnapshot: String?
    let expirySnapshot: String? // ISO8601 date string or null
    let methodUrl: String?
    let status: String
    let sig: String?
    let attestationUid: String?
    let createdAt: String // ISO8601 date string
    let revokedAt: String? // ISO8601 date string or null
    let isValid: Bool?
    let isEnsValid: Bool?
    let isActive: Bool?
    let ownershipMatches: Bool?
    let expiryValid: Bool?
    let verifierValid: Bool?
    let attestationExplorerUrl: String?
    
    // Computed properties for backward compatibility
    var verifierAddress: String {
        verifierId
    }
    
    var valueHash: String {
        fieldHash
    }
    
    var verifierEnsSnapshot: String? {
        ensName
    }
    
    var issuedAt: String {
        createdAt
    }
    
    var expiresAt: String {
        expirySnapshot ?? ""
    }
    
    var isExpired: Bool? {
        guard let expirySnapshot = expirySnapshot else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let expiryDate = formatter.date(from: expirySnapshot) {
            return expiryDate < Date()
        }
        return nil
    }
}

// Helper for JSON decoding with Any values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode AnyCodable")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Cannot encode AnyCodable"))
        }
    }
}

