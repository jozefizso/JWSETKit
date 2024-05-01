//
//  JWTDPoPClaims.swift
//
//
//  Created by Jozef Izso on 2024-04-27.
//  Copyright 2024 Cisco Systems, Inc.
//  Licensed under MIT-style license.
//

import Foundation

/// DPoP proof, which is a JWT
/// OAuth 2.0 Demonstrating Proof of Possession (DPoP) tokens are proofs
/// in a JWT format created by the client and sent with an HTTP request
/// using the `DPoP` header field.
/// 
/// Each HTTP request requires a unique DPoP proof.
///
/// A valid DPoP proof demonstrates to the server that the client holds
/// the private key that was used to sign the DPoP proof JWT.
///
/// @See: https://www.rfc-editor.org/rfc/rfc9449.html
/// @Version: RFC 9449, September 2023
public struct JWTDPoPClaims: JSONWebContainer {
    public var storage: JSONWebValueStorage
    
    public init(storage: JSONWebValueStorage) {
        self.storage = storage
    }
    
    public static func create(storage: JSONWebValueStorage) throws -> JWTDPoPClaims {
        .init(storage: storage)
    }
}

public typealias JWTDPoP = JSONWebSignature<ProtectedJSONWebContainer<JWTDPoPClaims>>

/// Claims registered for JWT DPoP tokens.
///
/// @Note: A DPoP proof MAY contain other JOSE Header Parameters or claims
/// as defined by extension, profile, or deployment-specific requirements.
///
/// @See: https://www.rfc-editor.org/rfc/rfc9449.html#name-json-web-token-claims-regis
public struct JWTDPoPRegisteredParameters: JSONWebContainerParameters {
    public typealias Container = JWTDPoPClaims
    
    /// Unique identifier for the DPoP proof JWT.
    public var jwtId: String?
    
    /// The value of the HTTP method of the request to which the JWT is attached.
    public var httpMethod: String?
    
    /// The HTTP target URI of the request to which the JWT is attached, without query and fragment parts.
    public var httpTargetUri: String?
    
    /// Creation timestamp of the JWT.
    public var issuedAt: Date?
    
    /// The base64url-encoded SHA-256 hash of the ASCII encoding of the associated access token's value.
    public var accessTokenHash: String?
    
    /// A recent nonce provided via the `DPoP-Nonce` HTTP header.
    public var nonce: String?
    
    @_documentation(visibility: private)
    public static let keys: [PartialKeyPath<Self>: String] = [
        \.jwtId: "jti",
        \.httpMethod: "htm",
        \.httpTargetUri: "htu",
        \.issuedAt: "iat",
        \.accessTokenHash: "ath",
        \.nonce: "nonce"
    ]
}

extension JWTDPoPClaims {
    @_documentation(visibility: private)
    public subscript<T: Codable>(dynamicMember keyPath: KeyPath<JWTDPoPRegisteredParameters, T?>) -> T? {
        get {
            storage[stringKey(keyPath)]
        }
        set {
            storage[stringKey(keyPath)] = newValue
        }
    }
}
