//
//  URLTests.swift
//
//
//  Created by Jozef Izso on 2024-05-01.
//  Copyright 2024 Cisco Systems, Inc.
//  Licensed under MIT-style license.
//

import XCTest
@testable import JWSETKit

final class URLTests: XCTestCase {
    func test_simpleURL() throws {
        let url = URL(string: "https://resource.example.com/")
        
        let httpTargetURL = url?.toDPoPHttpTargetUri
        
        XCTAssertEqual(httpTargetURL, "https://resource.example.com/")
    }
    
    func test_noLocalPathURL_normalizesPathComponent() throws {
        let url = URL(string: "https://resource.example.com")
        
        let httpTargetURL = url?.toDPoPHttpTargetUri
        
        XCTAssertEqual(httpTargetURL, "https://resource.example.com/")
    }
    
    func test_queryStringURL_removesQueryComponent() throws {
        let url = URL(string: "https://resource.example.com/api/v1?sort=name")
        
        let httpTargetURL = url?.toDPoPHttpTargetUri
        
        XCTAssertEqual(httpTargetURL, "https://resource.example.com/api/v1")
    }
    
    func test_fragmentURL_removesFragmentComponent() throws {
        let url = URL(string: "https://resource.example.com/entity#fragment")
        
        let httpTargetURL = url?.toDPoPHttpTargetUri
        
        XCTAssertEqual(httpTargetURL, "https://resource.example.com/entity")
    }
    
    func test_authoriyURL_keepsAuthroityComponent() throws {
        let url = URL(string: "https://username@resource.example.com:8443/")
        
        let httpTargetURL = url?.toDPoPHttpTargetUri
        
        XCTAssertEqual(httpTargetURL, "https://username@resource.example.com:8443/")
    }
}
