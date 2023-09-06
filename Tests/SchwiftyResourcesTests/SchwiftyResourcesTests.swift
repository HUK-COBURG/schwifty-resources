//
//  SchwiftyResourcesTests.swift
//
//  Copyright (c) 2023 HUK-COBURG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

@testable import SchwiftyResources
import XCTest
import CryptoKit

final class SchwiftyResourcesTests: XCTestCase {
    func testStringUserDefaultsResource() async throws {
        struct StringUserDefaultsResource: UserDefaultsResource {
            typealias ContentResourceCoder = StringResourceCoder
            let key: String = "property"
        }

        let resource = StringUserDefaultsResource()
        
        let valueToWrite = "Just a simple string."
        try resource.write(content: "Just a simple string.")

        let readValue = try resource.read()
        
        XCTAssertEqual(valueToWrite, readValue)
    }
    
    func testStringSandboxResource() async throws {
        struct StringSandboxResource: SandboxResource {
            typealias ContentResourceCoder = StringResourceCoder
            let location: SandboxLocation = .caches
            let path: String = "test.string"
        }

        let resource = StringSandboxResource()
        
        let valueToWrite = "Just a simple string."
        try await resource.write(content: "Just a simple string.")

        let readValue = try await resource.read()
        
        XCTAssertEqual(valueToWrite, readValue)
    }
    
    func testCryptedJsonSandboxResource() async throws {
        struct Rick: Codable, Equatable {
            let identifier: String
            let haircut: String
        }
        
        struct RicksKeyProvider: AesGcmCrypterKeyProvider {
            static func provideKey() -> SymmetricKey {
                let password = "pAssW0rd#OF-the/c1Tad3l"
                return SymmetricKey(data: SHA256.hash(data: Data(password.utf8)))
            }
        }
        
        struct RicksSandboxResource: SandboxResource {
            typealias ContentResourceCoder = CryptedJsonResourceCoder<[Rick], AesGcmCrypter<RicksKeyProvider>>
            let location: SandboxLocation = .documents
            var path: String = "ricks/ricks.store"
        }

        let resource = RicksSandboxResource()
        
        let ricksToWrite: [Rick] = [Rick(identifier: "C-137", haircut: "Mad scientist"),
                                    Rick(identifier: "Rick Prime", haircut: "Mad scientist (short)")]
        try await resource.write(content: ricksToWrite)

        let readRicks = try await resource.read()
        
        XCTAssertEqual(ricksToWrite, readRicks)
    }
    
    func testUrlBuilding() async throws {
        struct UrlSampleResource: HttpResource {
            typealias RequestBodyResourceEncoder = EmptyResourceCoder
            typealias ResponseBodyResourceDecoder = EmptyResourceCoder
            
            let url: URL
        }
        
        let url = URL(string: "https://www.citadel.org?rick=c-137&morty=%2F")!
        let resource = UrlSampleResource(url: url)
        let builtUrl = try await resource.buildUrl()
        
        XCTAssertEqual(url, builtUrl)
    }
}
