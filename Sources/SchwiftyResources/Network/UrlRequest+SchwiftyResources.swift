//
//  UrlRequest+SchwiftyResources.swift
//
//
//  Created by Johannes Bosecker on 01.12.22.
//

import struct Foundation.URLRequest

public enum HttpMethod: String {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace = "TRACE"
}

public extension URLRequest {
    /// A type safe (`HttpMethod`) representation of the `httpMethod`.
    var method: HttpMethod? {
        get {
            guard let httpMethodString = httpMethod else {
                return .get
            }

            return HttpMethod(rawValue: httpMethodString.uppercased())
        }
        set {
            httpMethod = newValue?.rawValue
        }
    }
}
