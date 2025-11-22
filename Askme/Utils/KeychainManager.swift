//
//  KeychainManager.swift
//  AskMe
//
//  Created by Franz Quarshie on 11/22/2025.
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.askme.AskMe"
    
    private init() {}
    
    /// Store a field value in Keychain (per ENS name)
    func store(field: FieldType, value: String, ensName: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataConversionError
        }
        
        // Store field per ENS name: "field:ensName:fieldType"
        let account = "field:\(ensName):\(field.rawValue)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw KeychainError.storeError(status)
        }
    }
    
    /// Retrieve a field value from Keychain (per ENS name)
    func retrieve(field: FieldType, ensName: String) throws -> String? {
        // Retrieve field per ENS name: "field:ensName:fieldType"
        let account = "field:\(ensName):\(field.rawValue)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        if status != errSecSuccess {
            throw KeychainError.retrieveError(status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionError
        }
        
        return value
    }
    
    /// Delete a field value from Keychain (per ENS name)
    func delete(field: FieldType, ensName: String) throws {
        // Delete field per ENS name: "field:ensName:fieldType"
        let account = "field:\(ensName):\(field.rawValue)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteError(status)
        }
    }
    
    /// Store subject ENS name
    func storeSubjectEns(_ ens: String) throws {
        guard let data = ens.data(using: .utf8) else {
            throw KeychainError.dataConversionError
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "subjectEns",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw KeychainError.storeError(status)
        }
    }
    
    /// Retrieve subject ENS name
    func retrieveSubjectEns() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "subjectEns",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        if status != errSecSuccess {
            throw KeychainError.retrieveError(status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionError
        }
        
        return value
    }
    
    /// Store verified ENS owner address
    func storeVerifiedEnsOwner(_ owner: String) throws {
        guard let data = owner.data(using: .utf8) else {
            throw KeychainError.dataConversionError
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "verifiedEnsOwner",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw KeychainError.storeError(status)
        }
    }
    
    /// Retrieve verified ENS owner address
    func retrieveVerifiedEnsOwner() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "verifiedEnsOwner",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        if status != errSecSuccess {
            throw KeychainError.retrieveError(status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionError
        }
        
        return value
    }
    
    /// Delete verified ENS owner address
    func deleteVerifiedEnsOwner() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "verifiedEnsOwner"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteError(status)
        }
    }
    
    /// Store list of ENS names
    func storeEnsNames(_ names: [String]) throws {
        let data = try JSONEncoder().encode(names)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "ensNames",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw KeychainError.storeError(status)
        }
    }
    
    /// Retrieve list of ENS names
    func retrieveEnsNames() throws -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "ensNames",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return []
        }
        
        if status != errSecSuccess {
            throw KeychainError.retrieveError(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.dataConversionError
        }
        
        return try JSONDecoder().decode([String].self, from: data)
    }
}

enum KeychainError: Error {
    case dataConversionError
    case storeError(OSStatus)
    case retrieveError(OSStatus)
    case deleteError(OSStatus)
    
    var localizedDescription: String {
        switch self {
        case .dataConversionError:
            return "Failed to convert data"
        case .storeError(let status):
            return "Failed to store in Keychain: \(status)"
        case .retrieveError(let status):
            return "Failed to retrieve from Keychain: \(status)"
        case .deleteError(let status):
            return "Failed to delete from Keychain: \(status)"
        }
    }
}

