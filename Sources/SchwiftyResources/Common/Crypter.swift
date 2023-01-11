//
//  Crypter.swift
//
//
//  Created by Johannes Bosecker on 03.07.18.
//

import CommonCrypto
import Foundation

/// Conform to this protocol to provide the ability to en- and decrypt data.
/// This is currently used by `CryptedJsonResourceCoder`
public protocol Crypter {
    static func encrypt(data: Data) throws -> Data
    static func decrypt(data: Data) throws -> Data
}

/// Conform to this protocol to provide a valid en- and decryption key for the `Aes256Crypter`.
public protocol Aes256CrypterKeyProvider {
    static func provideKey() -> Data
}

/// This crypter will en- and decrypt data using AES256.
/// You have to pass a key provider implementation.
/// The IV is prefixed to the encrypted data.
public struct Aes256Crypter<KeyProvider: Aes256CrypterKeyProvider>: Crypter {
    enum AesError: Error {
        case keyError((String, Int))
        case ivError((String, Int))
        case cryptorError((String, Int))
    }
    
    public static func encrypt(data: Data) throws -> Data {
        let keyData = KeyProvider.provideKey()
        let keyLength = keyData.count
        let validKeyLengths = [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256]

        guard validKeyLengths.contains(keyLength) else {
            throw AesError.keyError(("Invalid key length", keyLength))
        }

        let ivSize = kCCBlockSizeAES128
        let cryptLength = size_t(ivSize + data.count + kCCBlockSizeAES128)
        var cryptData = Data(count: cryptLength)

        let status = cryptData.withUnsafeMutableBytes { ivBytes in
            SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, ivBytes.baseAddress!)
        }

        guard status == 0 else {
            throw AesError.ivError(("IV generation failed", Int(status)))
        }

        var numBytesEncrypted: size_t = 0
        let options = CCOptions(kCCOptionPKCS7Padding)

        let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes { dataBytes in
                keyData.withUnsafeBytes { keyBytes in
                    CCCrypt(CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            options,
                            keyBytes.baseAddress, keyLength,
                            cryptBytes.baseAddress,
                            dataBytes.baseAddress, data.count,
                            cryptBytes.baseAddress! + kCCBlockSizeAES128, cryptLength,
                            &numBytesEncrypted)
                }
            }
        }

        guard UInt32(cryptStatus) == UInt32(kCCSuccess) else {
            throw AesError.cryptorError(("Encryption failed", Int(cryptStatus)))
        }

        cryptData.count = numBytesEncrypted + ivSize

        return cryptData
    }
    
    public static func decrypt(data: Data) throws -> Data {
        let keyData = KeyProvider.provideKey()
        let keyLength = keyData.count
        let validKeyLengths = [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256]

        guard validKeyLengths.contains(keyLength) else {
            throw AesError.keyError(("Invalid key length", keyLength))
        }

        let ivSize = kCCBlockSizeAES128
        let clearLength = size_t(data.count - ivSize)

        guard clearLength > 0 else {
            throw AesError.cryptorError(("Invalid data length", clearLength))
        }

        var clearData = Data(count: clearLength)

        var numBytesDecrypted: size_t = 0
        let options = CCOptions(kCCOptionPKCS7Padding)

        let cryptStatus = clearData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes { dataBytes in
                keyData.withUnsafeBytes { keyBytes in
                    CCCrypt(CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            options,
                            keyBytes.baseAddress, keyLength,
                            dataBytes.baseAddress,
                            dataBytes.baseAddress! + kCCBlockSizeAES128, clearLength,
                            cryptBytes.baseAddress, clearLength,
                            &numBytesDecrypted)
                }
            }
        }

        guard UInt32(cryptStatus) == UInt32(kCCSuccess) else {
            throw AesError.cryptorError(("Decryption failed", Int(cryptStatus)))
        }

        clearData.count = numBytesDecrypted

        return clearData
    }
}
