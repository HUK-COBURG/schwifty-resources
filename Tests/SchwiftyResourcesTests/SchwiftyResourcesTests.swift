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
        try await resource.write(content: "Just a simple string.")

        let readValue = try await resource.read()
        
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
        
        struct RicksKeyProvider: Aes256CrypterKeyProvider {
            static func provideKey() -> Data {
                let password = "pAssW0rd#OF-the/c1Tad3l"
                let passwordData = Data(password.utf8)
                
                return Data(SHA256.hash(data: passwordData))
            }
        }
        
        struct RicksSandboxResource: SandboxResource {
            typealias ContentResourceCoder = CryptedJsonResourceCoder<[Rick], Aes256Crypter<RicksKeyProvider>>
            let location: SandboxLocation = .documents
            var path: String = "ricks.store"
        }

        let resource = RicksSandboxResource()
        
        let ricksToWrite: [Rick] = [Rick(identifier: "C-137", haircut: "Mad scientist"),
                                    Rick(identifier: "Rick Prime", haircut: "Mad scientist (short)")]
        try await resource.write(content: ricksToWrite)

        let readRicks = try await resource.read()
        
        XCTAssertEqual(ricksToWrite, readRicks)
    }
}
