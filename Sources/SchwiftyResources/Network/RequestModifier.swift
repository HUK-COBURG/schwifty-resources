//
//  RequestModifier.swift
//
//
//  Created by Johannes Bosecker on 25.11.22.
//

import struct Foundation.URLRequest

/// Conform to this protocol and add it to the `requestModifiers` of a `HttpResource` to be able to manipulate the request, before sending it.
public protocol RequestModifier {
    func modify(request: URLRequest, networkResource: any HttpResource) async throws -> URLRequest
}

/// This RequestModifier will manipulate the request with the given cache policy.
public struct CachePolicyRequestModifier: RequestModifier {
    private let cachePolicy: URLRequest.CachePolicy

    public init(cachePolicy: URLRequest.CachePolicy) {
        self.cachePolicy = cachePolicy
    }

    public func modify(request: URLRequest, networkResource _: any HttpResource) async throws -> URLRequest {
        var modifiedRequest = request
        modifiedRequest.cachePolicy = cachePolicy
        return modifiedRequest
    }
}
