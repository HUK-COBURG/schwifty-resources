//
//  RequestModifier.swift
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
