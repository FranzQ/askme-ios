//
//  Request.swift
//  AskMe
//
//  Created by Franz Quarshie on 11/22/2025.
//

import Foundation

struct VerificationRequest: Codable, Identifiable {
    let id: String
    let verifierAddress: String
    let verifierEns: String?
    let verifiedEns: String
    let field: String
    let status: String // pending, approved, rejected, expired, completed
    let requestedAt: String
    let approvedAt: String?
    let expiresAt: String?
    let completedAt: String?
}

struct FieldRevealLog: Codable, Identifiable {
    let id: String
    let requestId: String
    let verifiedEns: String
    let field: String
    let verifierAddress: String
    let verifierEns: String?
    let revealedAt: String
    let valueHash: String?
}

