//
//  Storage.swift
//
//
//  Created by Amir Abbas Mousavian on 9/6/23.
//

@preconcurrency import AnyCodable
import Foundation

/// Storage for values in JOSE headers or JWT claims
@dynamicMemberLookup
public struct JSONWebValueStorage: Codable, Hashable, ExpressibleByDictionaryLiteral, Sendable {
    private var storage: [String: AnyCodable]
    
    /// Returns value of given key.
    public subscript<T: Codable>(dynamicMember member: String) -> T? {
        get {
            get(key: member, as: T.self)
        }
        set {
            updateValue(key: member, value: newValue)
        }
    }
    
    /// Returns values of given key.
    public subscript<T: Codable>(dynamicMember member: String) -> [T] {
        get {
            self[member]
        }
        set {
            self[member] = newValue
        }
    }
    
    /// Returns value of given key.
    public subscript<T: Codable>(_ member: String) -> T? {
        get {
            get(key: member, as: T.self)
        }
        set {
            updateValue(key: member, value: newValue)
        }
    }
    
    /// Returns value of given key.
    public subscript(_ member: String) -> String? {
        get {
            get(key: member, as: String.self)
        }
        set {
            updateValue(key: member, value: newValue)
        }
    }
    
    /// Returns values of given key.
    public subscript<T: Codable>(_ member: String) -> [T] {
        get {
            guard let array = storage[member]?.value as? [Any] else { return [] }
            return array.compactMap { JSONWebValueStorage.cast(value: $0, as: T.self) }
        }
        set {
            if newValue.isEmpty {
                remove(key: member)
            } else {
                updateValue(key: member, value: newValue)
            }
        }
    }
    
    /// Returns value of given key.
    public subscript(_ member: String) -> Bool {
        get {
            get(key: member, as: Bool.self) ?? false
        }
        set {
            updateValue(key: member, value: newValue)
        }
    }
    
    /// Returns value of given key decoded using base64.
    public subscript(_ member: String, urlEncoded: Bool = true) -> Data? {
        get {
            guard let value = self[member] as String? else { return nil }
            if urlEncoded {
                return Data(urlBase64Encoded: value)
            } else {
                return Data(base64Encoded: value)
            }
        }
        set {
            updateValue(
                key: member,
                value: urlEncoded ? newValue?.urlBase64EncodedString() : newValue?.base64EncodedString()
            )
        }
    }
    
    /// Returns values of given key decoded using base64.
    public subscript(_ member: String, urlEncoded: Bool = true) -> [Data] {
        get {
            let values = self[member] as [String]
            if urlEncoded {
                return values.compactMap { Data(urlBase64Encoded: $0) }
            } else {
                return values.compactMap { Data(base64Encoded: $0) }
            }
        }
        set {
            self[member] = newValue.compactMap {
                urlEncoded ? $0.urlBase64EncodedString() : $0.base64EncodedString()
            }
        }
    }
    
    /// Initializes empty storage.
    public init() {
        self.storage = [:]
    }
    
    public init(dictionaryLiteral elements: (String, Any)...) {
        let elements = elements.map { ($0, AnyCodable($1)) }
        self.storage = .init(uniqueKeysWithValues: elements)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let claims = try? container.decode([String: AnyCodable].self) {
            self.storage = claims
        } else if let base64url = try? container.decode(String.self),
                  let data = Data(urlBase64Encoded: base64url)
        {
            self.storage = try JSONDecoder().decode([String: AnyCodable].self, from: data)
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: ""))
        }
    }
    
    public func merging(_ other: JSONWebValueStorage, uniquingKeysWith combine: (Any, Any) throws -> Any) rethrows -> JSONWebValueStorage {
        let storage = try storage.merging(other.storage) {
            try .init(combine($0.value, $1.value))
        }
        var result = JSONWebValueStorage()
        result.storage = storage
        return result
    }
    
    public func filter(_ isIncluded: (String) throws -> Bool) rethrows -> JSONWebValueStorage {
        let storage = try self.storage.filter { try isIncluded($0.key) }
        var result = JSONWebValueStorage()
        result.storage = storage
        return result
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storage)
    }
    
    public static func == (lhs: JSONWebValueStorage, rhs: JSONWebValueStorage) -> Bool {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let lhs = try? decoder.decode([String: AnyCodable].self, from: encoder.encode(lhs))
        let rhs = try? decoder.decode([String: AnyCodable].self, from: encoder.encode(rhs))
        return lhs == rhs
    }
    
    /// List of all keys that have data.
    public var storageKeys: [String] {
        [String](storage.keys)
    }
    
    /// Removes value of given key from storage.
    public func contains(key: String) -> Bool {
        storage.keys.contains(key)
    }
    
    /// Removes value of given key from storage.
    public mutating func remove(key: String) {
        storage.removeValue(forKey: key)
    }
    
    fileprivate static func cast<T>(value: Any?, as type: T.Type) -> T? where T: Encodable {
        guard let value = value else { return nil }
        if let value = value as? T {
            return value
        }
        switch T.self {
        case let type as any JSONWebFieldDecodable.Type:
            // Some values are encoded differently in JOSE than conventional JSON encoding.
            // e.g `Data` is encoded in Base64URL rather than standard Bas64, and Date is
            // encoded in `NumericDate` which is unix timestamp rather than RFC3339.
            // Other common differences are `Locale` where `JOSE` prefers
            // "BCP-47" presentation rather than "CLDR/ICU", `TimeZone` where
            // "IANA" presentation is expected, and UUID where lower-cased is preferred.
            //
            // These well known types are handled specially to prevent mis-encoding JWS/JWT
            // when using a `JSONEncoder` with incorrect data/date formattting strategies.
            return type.castValue(value) as? T
        case let type as any Decodable.Type:
            // Some data types are same in JSON while have different types
            // in Swift, e.g. integer and float types.
            //
            // Here, we first type to simply cast value to target type. If this
            // casting succeed, it will return. Otherwise we try to encode data
            // using `JSONEncoder` then decode as a "Type-erasure" method.
            if let value = value as? T {
                return value
            } else {
                let value = AnyCodable(value)
                guard let data = try? JSONEncoder().encode(value) else { return nil }
                return try? JSONDecoder().decode(type, from: data) as? T
            }
        default:
            return value as? T
        }
    }
    
    private func get<T>(key: String, as _: T.Type) -> T? where T: Encodable {
        JSONWebValueStorage.cast(value: storage[key]?.value, as: T.self)
    }
    
    private mutating func updateValue<T>(key: String, value: T?) where T: Decodable {
        guard let value = value else {
            remove(key: key)
            return
        }
        
        switch value {
        case let value as any JSONWebFieldEncodable:
            storage[key] = .init(value.jsonWebValue)
        default:
            storage[key] = .init(value)
        }
    }
}
