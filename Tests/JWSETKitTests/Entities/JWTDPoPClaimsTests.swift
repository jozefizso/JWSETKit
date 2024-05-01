//
//  JWTDPoPClaims.swift
//
//
//  Created by Jozef Izso on 2024-04-28.
//  Copyright 2024 Cisco Systems, Inc.
//  Licensed under MIT-style license.
//

import XCTest
@testable import JWSETKit

final class JWTDPoPClaimsTests: XCTestCase {
    let dpopJsonSimpleClaim = """
    {
      "jti":"-BwC3ESc6acc2lTc",
      "htm":"POST",
      "htu":"https://server.example.com/token",
      "iat":1562262616
    }
    """
    
    let dpopJsonFullClaim = """
    {
      "jti":"BmfXHsGBiSBmNzGfyAJSL9EXi0THsLYEdVkfTodKKRo",
      "htm":"POST",
      "htu":"https://server.example.com/authorize",
      "iat":1714248302,
      "ath":"fUHyO2r2Z3DZ53EsNrWBb0xWXoaNy59IiKCAqksmQEo",
      "nonce":"eyJ7S_zG.eyJH0-Z.HX4w-7v",
    }
    """

    func test_decode_dpopSimpleClaim_using_jsonFormat() throws {
        // Arrange
        let decoder = JSONDecoder()
        
        // Act
        let dpopClaims = try decoder.decode(JWTDPoPClaims.self, from: .init(dpopJsonSimpleClaim.utf8))
        
        // Assert
        XCTAssertEqual(dpopClaims.jwtId, "-BwC3ESc6acc2lTc")
        XCTAssertEqual(dpopClaims.httpMethod, "POST")
        XCTAssertEqual(dpopClaims.httpTargetUri, "https://server.example.com/token")
        XCTAssertEqual(dpopClaims.issuedAt, Date(timeIntervalSince1970: 1_562_262_616))
        
        XCTAssertNil(dpopClaims.accessTokenHash)
        XCTAssertNil(dpopClaims.nonce)
    }
    
    func test_decode_dpopFullClaim_using_jsonFormat() throws {
        // Arrange
        let decoder = JSONDecoder()
        
        // Act
        let dpopClaims = try decoder.decode(JWTDPoPClaims.self, from: .init(dpopJsonFullClaim.utf8))
        
        // Assert
        XCTAssertEqual(dpopClaims.jwtId, "BmfXHsGBiSBmNzGfyAJSL9EXi0THsLYEdVkfTodKKRo")
        XCTAssertEqual(dpopClaims.httpMethod, "POST")
        XCTAssertEqual(dpopClaims.httpTargetUri, "https://server.example.com/authorize")
        XCTAssertEqual(dpopClaims.issuedAt, Date(timeIntervalSince1970: 1_714_248_302))
        
        XCTAssertEqual(dpopClaims.accessTokenHash, "fUHyO2r2Z3DZ53EsNrWBb0xWXoaNy59IiKCAqksmQEo")
        XCTAssertEqual(dpopClaims.nonce, "eyJ7S_zG.eyJH0-Z.HX4w-7v")
    }
}

final class JWTDPoPTests: XCTestCase {
    /// Sample DPoP JWT value from [The DPoP Authentication Scheme](https://www.rfc-editor.org/rfc/rfc9449.html#name-the-dpop-authentication-sch)
    let dpopJwtSample = "eyJ0eXAiOiJkcG9wK2p3dCIsImFsZyI6IkVTMjU2IiwiandrIjp7Imt0eSI6IkVDIiwieCI6Imw4dEZyaHgtMzR0VjNoUklDUkRZOXpDa0RscEJoRjQyVVFVZldWQVdCRnMiLCJ5IjoiOVZFNGpmX09rX282NHpiVFRsY3VOSmFqSG10NnY5VERWclUwQ2R2R1JEQSIsImNydiI6IlAtMjU2In19.eyJqdGkiOiJlMWozVl9iS2ljOC1MQUVCIiwiaHRtIjoiR0VUIiwiaHR1IjoiaHR0cHM6Ly9yZXNvdXJjZS5leGFtcGxlLm9yZy9wcm90ZWN0ZWRyZXNvdXJjZSIsImlhdCI6MTU2MjI2MjYxOCwiYXRoIjoiZlVIeU8ycjJaM0RaNTNFc05yV0JiMHhXWG9hTnk1OUlpS0NBcWtzbVFFbyJ9.2oW9RP35yRqzhrtNP86L-Ey71EOptxRimPPToA1plemAgR6pxHF8y6-yqyVnmcw6Fy1dqd-jfxSYoMxhAJpLjA"
    
    func test_decode_JWTDPoP_using_jwtFormat() throws {
        // Act
        let dpop = try JWTDPoP.init(from: dpopJwtSample)
        
        // Assert
        let dpopClaim = dpop.payload
        
        XCTAssertEqual(dpopClaim.jwtId, "e1j3V_bKic8-LAEB")
        XCTAssertEqual(dpopClaim.httpMethod, "GET")
        XCTAssertEqual(dpopClaim.httpTargetUri, "https://resource.example.org/protectedresource")
        XCTAssertEqual(dpopClaim.issuedAt, Date(timeIntervalSince1970: 1_562_262_618))
        XCTAssertEqual(dpopClaim.accessTokenHash, "fUHyO2r2Z3DZ53EsNrWBb0xWXoaNy59IiKCAqksmQEo")
        
        XCTAssertNil(dpopClaim.nonce)
    }
}
