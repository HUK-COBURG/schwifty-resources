//
//  FileResource.swift
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

import Foundation

public protocol FileResource: Sendable {
    /// The type of the content resource coder. Must conform to `ResourceCoder`.
    associatedtype ContentResourceCoder: ResourceCoder

    /// The instance of the content resource coder.
    var contentResourceCoder: ContentResourceCoder { get }
    /// The URL of the resource.
    var url: URL { get async throws }
    /// The protection mode of the item on the file system
    var protection: FileResourceProtection { get }
    /// Will try to get the data from the given url and decode it with the content resource coder.
    func read() async throws -> ContentResourceCoder.Content
    /// Will try to encode the content using the content resource coder and write it to the given url.
    func write(content: ContentResourceCoder.Content) async throws
    /// Will try to remove the item from the file system at the given url.
    func delete() async throws
}

public extension FileResource {
    var contentResourceCoder: ContentResourceCoder {
        ContentResourceCoder()
    }

    var protection: FileResourceProtection {
        return .completeUntilFirstUserAuthentication
    }
    
    func read() async throws -> ContentResourceCoder.Content {
        let url = try await self.url

        do {
            let data = try Data(contentsOf: url)

            do {
                let content = try contentResourceCoder.decode(data: data)
                return content
            } catch {
                throw ErrorWrapper.wrapped(error)
            }
        } catch {
            if let error = error as? ErrorWrapper, case let .wrapped(wrappedError) = error {
                throw wrappedError
            } else {
                throw SchwiftyResourcesError.cannotReadFile(error)
            }
        }
    }
    
    func write(content: ContentResourceCoder.Content) async throws {
        let url = try await self.url
        let data = try contentResourceCoder.encode(content: content)
        
        do {
            let directoryUrl = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: true)
            
            try (data ?? Data()).write(to: url, options: protection.writingOptions)
        } catch {
            let nsError = error as NSError
            
            if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileWriteOutOfSpaceError {
                throw SchwiftyResourcesError.outOfDiskSpace(error)
            } else {
                throw SchwiftyResourcesError.cannotWriteFile(error)
            }
        }
    }
    
    func delete() async throws {
        let url = try await self.url
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw SchwiftyResourcesError.cannotDeleteFile(error)
        }
    }
}

public enum FileResourceProtection: Sendable {
    /// The file is stored in an encrypted format on disk and cannot be read from or written to while the device is locked or booting.
    case complete
    /// The file is stored in an encrypted format on disk after it is closed.
    case completeUnlessOpen
    /// The file is stored in an encrypted format on disk and cannot be accessed until after the device has booted.
    case completeUntilFirstUserAuthentication
    /// The file has no special protections associated with it.
    case none
    
    fileprivate var writingOptions: Data.WritingOptions {
        switch self {
        case .complete:
            return .completeFileProtection
        case .completeUnlessOpen:
            return .completeFileProtectionUnlessOpen
        case .completeUntilFirstUserAuthentication:
            return .completeFileProtectionUntilFirstUserAuthentication
        case .none:
            return .noFileProtection
        }
    }
}

private enum ErrorWrapper: Error {
    case wrapped(Error)
}
