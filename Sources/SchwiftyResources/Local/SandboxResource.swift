//
//  File.swift
//  
//
//  Created by Johannes Bosecker on 11.01.23.
//

import Foundation.NSPathUtilities

public protocol SandboxResource: FileResource {
    /// The location inside the sandbox (e.g. caches or documents)
    var location: SandboxLocation { get }
    /// The path to the resource relative to the location
    var path: String { get }
}

public extension SandboxResource {
    var url: URL {
        get throws {
            guard let locationUrl = location.url else {
                throw SchwiftyResourcesError.sandboxLocationUnavailable
            }
            
            return locationUrl.appendingPathComponent(path, isDirectory: false)
        }
    }
}

public enum SandboxLocation {
    case caches
    case documents
    
    var url: URL? {
        var path: String? = nil
        
        switch self {
        case .caches:
            path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        case .documents:
            path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        }
        
        guard let path = path else {
            return nil
        }
        
        return URL(fileURLWithPath: path)
    }
}
