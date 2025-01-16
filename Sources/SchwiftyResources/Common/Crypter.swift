//
//  Crypter.swift
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

import struct Foundation.Data
import CryptoKit

/// Conform to this protocol to provide the ability to en- and decrypt data.
/// This is currently used by `CryptedJsonResourceCoder`
public protocol Crypter: Sendable {
    static func encrypt(data: Data) throws -> Data
    static func decrypt(data: Data) throws -> Data
}

/// Conform to this protocol to provide a valid en- and decryption key for the `AesGcmCrypter`.
public protocol AesGcmCrypterKeyProvider: Sendable {
    static func provideKey() -> SymmetricKey
}

/// This crypter will en- and decrypt data using AES GCM.
/// You have to pass a key provider implementation.
public struct AesGcmCrypter<KeyProvider: AesGcmCrypterKeyProvider>: Crypter {
    enum AesError: Error {
        case encryptionFailed(Error?)
        case decryptionFailed(Error?)
    }
    
    public static func encrypt(data: Data) throws -> Data {
        let key = KeyProvider.provideKey()
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            
            guard let data = sealedBox.combined else {
                throw AesError.encryptionFailed(nil)
            }
            
            return data
        } catch {
            switch error {
            case is AesError:
                throw error
            default:
                throw AesError.encryptionFailed(error)
            }
        }
    }
    
    public static func decrypt(data: Data) throws -> Data {
        let key = KeyProvider.provideKey()
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let data = try AES.GCM.open(sealedBox, using: key)
            
            return data
        } catch {
            throw AesError.decryptionFailed(error)
        }
    }
}

/// Conform to this protocol to provide a valid en- and decryption key for the `ChaChaPolyCrypter`.
public protocol ChaChaPolyCrypterKeyProvider: Sendable {
    static func provideKey() -> SymmetricKey
}

/// This crypter will en- and decrypt data using Cha Cha Poly.
/// You have to pass a key provider implementation.
public struct ChaChaPolyCrypter<KeyProvider: ChaChaPolyCrypterKeyProvider>: Crypter {
    enum ChaChaPolyError: Error {
        case encryptionFailed(Error?)
        case decryptionFailed(Error?)
    }
    
    public static func encrypt(data: Data) throws -> Data {
        let key = KeyProvider.provideKey()
        
        do {
            let sealedBox = try ChaChaPoly.seal(data, using: key)
            return sealedBox.combined
        } catch {
            throw ChaChaPolyError.encryptionFailed(error)
        }
    }
    
    public static func decrypt(data: Data) throws -> Data {
        let key = KeyProvider.provideKey()
        
        do {
            let sealedBox = try ChaChaPoly.SealedBox(combined: data)
            let data = try ChaChaPoly.open(sealedBox, using: key)
            return data
        } catch {
            throw ChaChaPolyError.decryptionFailed(error)
        }
    }
}
