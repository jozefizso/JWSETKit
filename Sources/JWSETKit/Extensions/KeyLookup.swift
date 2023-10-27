//
//  KeyLookup.swift
//
//
//  Created by Amir Abbas Mousavian on 9/7/23.
//

import Foundation

@_documentation(visibility: private)
public protocol JSONWebContainerParameters<Container> {
    associatedtype Container: JSONWebContainer
    
    static var keys: [PartialKeyPath<Self>: String] { get }
    static var localizableKeys: [PartialKeyPath<Self>] { get }
}

extension JSONWebContainerParameters {
    public static var localizableKeys: [PartialKeyPath<Self>] { [] }
}

extension JSONWebContainer {
    @_documentation(visibility: private)
    public func stringKey<P: JSONWebContainerParameters<Self>, T>(_ keyPath: KeyPath<P, T>) -> String {
        let key = P.keys[keyPath] ?? String(reflecting: keyPath).components(separatedBy: ".").last!.jsonWebKey
        guard P.localizableKeys.contains(keyPath) else { return key }
        let locales = storage.storageKeys
            .filter { $0.hasPrefix(key + "#") }
            .map { $0.replacingOccurrences(of: key + "#", with: "", options: [.anchored]) }
            .map(Locale.init(identifier:))
        guard let bestLocale = JSONWebKit.locale.bestMatch(in: locales) else { return key }
        return "\(key)#\(bestLocale.identifier)"
    }
}

extension String {
    var snakeCased: String {
        let regex = try! NSRegularExpression(pattern: "([a-z0-9])([A-Z])", options: [])
        let range = NSRange(startIndex..., in: self)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
    }
    
    var jsonWebKey: String {
        snakeCased
            .replacingOccurrences(of: "is_", with: "", options: [.anchored])
            .replacingOccurrences(of: "_url", with: "", options: [.anchored, .backwards])
    }
}
