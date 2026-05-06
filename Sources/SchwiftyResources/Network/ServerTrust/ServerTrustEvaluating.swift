//
//  ServerTrustEvaluating.swift
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

/// A type that evaluates whether a server's trust credentials should be accepted.
///
/// Conform to this protocol to implement custom SSL pinning strategies
/// (e.g., SPKI hash pinning, composite chain validation, certificate transparency).
///
/// Implementations must be safe to call from any concurrency context.
public protocol ServerTrustEvaluating: Sendable {

    /// Evaluate the server trust for the given host.
    ///
    /// - Parameters:
    ///   - serverTrust: The `SecTrust` object provided by the URL authentication challenge.
    ///   - host: The hostname of the server being connected to.
    /// - Returns: `true` if the server should be trusted, `false` otherwise.
    /// - Throws: An error if evaluation cannot be performed.
    func evaluate(_ serverTrust: SecTrust, for host: String) throws -> Bool
}
