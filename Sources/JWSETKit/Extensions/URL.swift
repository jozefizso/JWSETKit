//
//  URL.swift
//
//
//  Created by Jozef Izso on 2024-05-01.
//  Copyright 2024 Cisco Systems, Inc.
//  Licensed under MIT-style license.
//

import Foundation

public extension URL {
    /// Returns the HTTP target URI of the request to which
    /// the JWT is attached, without query and fragment parts.
    ///
    /// Use this value for the DPoP `htu` parameter.
    ///
    /// @See: https://www.rfc-editor.org/rfc/rfc9110#section-7.1
    var toDPoPHttpTargetUri: String? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        /// Normalize the path to `/` if empty in the original URL.
        /// @Brief: In general, a URI that uses the generic syntax for authority with an
        ///        empty path should be normalized to a path of "/".
        /// @See: https://www.rfc-editor.org/rfc/rfc3986#section-6.2.3
        components.path = components.path.isEmpty ? "/" : components.path
        components.query = nil
        components.fragment = nil
        
        return components.url?.absoluteString
    }
}
