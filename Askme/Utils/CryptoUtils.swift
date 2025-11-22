//
//  CryptoUtils.swift
//  AskMe
//
//  Created by Franz Quarshie on 11/22/2025.
//

import Foundation
import CryptoSwift

struct CryptoUtils {
    /// Normalize a value (trim whitespace, lowercase for consistency)
    static func normalize(_ value: String) -> String {
        return value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    /// Compute keccak256 hash using CryptoSwift
    static func keccak256(_ data: Data) -> String {
        let hash = data.sha3(.keccak256)
        return "0x" + hash.toHexString()
    }
    
    /// Compute keccak256 hash from string
    static func keccak256(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else {
            return ""
        }
        return keccak256(data)
    }
    
    /// Compute valueHash = keccak256(normalize(value))
    static func computeValueHash(for value: String) -> String {
        let normalized = normalize(value)
        return keccak256(normalized)
    }
    
    /// Compute fieldHash = keccak256("VerifyENS:" + field + ":" + valueHash)
    static func computeFieldHash(field: String, valueHash: String) -> String {
        let input = "VerifyENS:\(field):\(valueHash)"
        return keccak256(input)
    }
    
    /// Compute both valueHash and fieldHash for a field value
    static func computeHashes(field: FieldType, value: String) -> (valueHash: String, fieldHash: String) {
        let valueHash = computeValueHash(for: value)
        let fieldHash = computeFieldHash(field: field.rawValue, valueHash: valueHash)
        return (valueHash, fieldHash)
    }
}

