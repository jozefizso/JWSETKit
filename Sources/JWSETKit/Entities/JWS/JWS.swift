//
//  JWS.swift
//
//
//  Created by Amir Abbas Mousavian on 9/8/23.
//

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

/// JWS represents digitally signed or MACed content using JSON data structures and `base64url` encoding.
public struct JSONWebSignature<Payload: ProtectedWebContainer>: Hashable {
    /// The "signatures" member value MUST be an array of JSON objects.
    ///
    /// Each object represents a signature or MAC over the JWS Payload and the JWS Protected Header.
    public var signatures: [JSONWebSignatureHeader]
    
    /// The "`payload`" member MUST be present and contain the value of JWS Payload.
    public var payload: Payload
    
    enum CodingKeys: String, CodingKey {
        case payload
        case signatures
    }
    
    /// Decodes a data that may contain either Base64URL encoded string of JWS or a Complete/Flattened JWS representation.
    ///
    /// - Parameter data: Either Base64URL encoded string of JWS or a JSON with Complete/Flattened JWS representation.
    public init<D: DataProtocol>(from data: D) throws {
        if data.starts(with: Data("ey".utf8)) {
            let container = Data("\"".utf8) + Data(data) + Data("\"".utf8)
            self = try JSONDecoder().decode(JSONWebSignature<Payload>.self, from: container)
        } else if data.starts(with: Data("{".utf8)) {
            self = try JSONDecoder().decode(JSONWebSignature<Payload>.self, from: Data(data))
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid JWS."))
        }
    }
    
    /// Initialzes JWS using Base64URL encoded String.
    ///
    /// - Parameter string: Base64URL encoded String.
    public init<S: StringProtocol>(from string: S) throws {
        try self.init(from: Data(string.utf8))
    }
    
    /// Initializes a new JWS with given payload and signature(s).
    ///
    /// - Parameters:
    ///   - signatures: An array of signatures and JOSE headers.
    ///   - payload: Protected payload data/object.
    public init(signatures: [JSONWebSignatureHeader], payload: Payload) {
        self.signatures = signatures
        self.payload = payload
    }
    
    /// Renews all signatures for protected header(s) using given keys.
    ///
    /// This methos finds appropriate key for the header using `kid` value in protected or unprotected header.
    ///
    /// - Parameters:
    ///   - keys: An array of `JSONWebSigningKey` that would be used for signing.
    public mutating func updateSignature(using keys: [any JSONWebSigningKey]) throws {
        signatures = try signatures.map { header in
            let message = header.signedData(payload)
            let algorithm = header.header.value.algorithm
            let keyId: String? = header.header.value.keyId ?? header.unprotectedHeader?.keyId
            let signature: Data
            if algorithm == .none {
                signature = .init()
            } else if let key = keys.bestMatch(for: algorithm, id: keyId) {
                signature = try key.signature(message, using: algorithm)
            } else {
                throw JSONWebKeyError.keyNotFound
            }
            return try .init(
                header: header.header.protected,
                unprotectedHeader: header.unprotectedHeader,
                signature: signature
            )
        }
    }
    
    /// Renews all signatures for protected header(s) using given key set.
    ///
    /// - Parameters:
    ///   - keySet: A `JSONWebKeySet` object contains keys that would be used for signing.
    public mutating func updateSignature(using keySet: JSONWebKeySet) throws {
        try updateSignature(using: keySet.keys.compactMap { $0 as? any JSONWebSigningKey })
    }
    
    /// Renews all signatures for protected header(s) using given key.
    ///
    /// - Parameters:
    ///   - key: A `JSONWebSigningKey` object that would be used for signing.
    public mutating func updateSignature(using key: any JSONWebSigningKey) throws {
        try updateSignature(using: [key])
    }
    
    /// Verifies all signatures for protected header(s) using given keys.
    ///
    /// This methos finds appropriate key for the header using `kid` value in protected or unprotected header.
    ///
    /// - Note: No signature algorithm (`alg`) may have been set to "`none`" otherwise
    ///     `JSONWebKeyError.operationNotAllowed` will be thrown.
    ///
    /// - Parameters:
    ///   - keys: An array of `JSONWebValidatingKey` that would be used for validation.
    public func verifySignature(using keys: [any JSONWebValidatingKey]) throws {
        guard !signatures.isEmpty else {
            throw CryptoKitError.authenticationFailure
        }
        try signatures.forEach { header in
            let message = header.signedData(payload)
            let algorithm = header.header.value.algorithm
            let keyId: String? = header.header.value.keyId ?? header.unprotectedHeader?.keyId
            if algorithm == .none {
                // If we allow "none" algorithm in verification, a malicious user may simply
                // remove the signature and change the algorithm to "none".
                // As this scenario may lead to a critical security vulnaribility, "none"
                // is not supported algorithm .
                throw JSONWebKeyError.operationNotAllowed
            } else if let key = keys.bestMatch(for: algorithm, id: keyId) {
                try key.verifySignature(header.signature, for: message, using: algorithm)
            } else {
                throw JSONWebKeyError.keyNotFound
            }
        }
    }
    
    /// Verifies all signatures in protected header(s) using given key set.
    ///
    /// - Parameters:
    ///   - key: A `JSONWebKeySet` object contains keys that would be used for validation.
    public func verifySignature(using keySet: JSONWebKeySet) throws {
        try verifySignature(using: keySet.keys.compactMap { $0 as? any JSONWebValidatingKey })
    }
    
    /// Verifies all signatures in protected header(s) using given key.
    ///
    /// - Parameters:
    ///   - key: A `JSONWebValidatingKey` object that would be used for validation.
    public func verifySignature(using key: any JSONWebValidatingKey) throws {
        try verifySignature(using: [key])
    }
}

extension String {
    public init<Payload: ProtectedWebContainer>(jws: JSONWebSignature<Payload>) throws {
        self = try String(String(decoding: JSONEncoder().encode(jws), as: UTF8.self).dropFirst().dropLast())
    }
}

extension JSONWebSignature: LosslessStringConvertible, CustomDebugStringConvertible {
    public init?(_ description: String) {
        guard let jws = try? JSONWebSignature<Payload>(from: description) else {
            return nil
        }
        self = jws
    }
    
    public var description: String {
        (try? String(jws: self)) ?? ""
    }
    
    public var debugDescription: String {
        "Signatures: \(signatures.debugDescription)\nPayload: \(String(decoding: payload.protected.urlBase64EncodedData(), as: UTF8.self))"
    }
}
