//
//  ServerTrustRegistry.swift
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

@CertificatePinningActor
public final class ServerTrustRegistry {
    public static let sharedInstance = ServerTrustRegistry()

    private var entries: [(pattern: Regex<AnyRegexOutput>, evaluator: any ServerTrustEvaluating)] = []

    private init() {}

    /// Register a trust evaluator for hosts matching the given regex pattern.
    ///
    /// Evaluators are matched in registration order (first match wins).
    /// Register more specific host patterns **before** broader catch-all patterns
    /// to ensure correct matching. For example:
    /// ```swift
    /// // Specific first
    /// registry.register(strictEvaluator, for: try! Regex("^api\\.example\\.com$"))
    /// // Broad second
    /// registry.register(defaultEvaluator, for: try! Regex(".*\\.example\\.com"))
    /// ```
    public func register(
        _ evaluator: any ServerTrustEvaluating,
        for pattern: Regex<AnyRegexOutput>
    ) {
        entries.append((pattern: pattern, evaluator: evaluator))
    }

    /// Returns the evaluator registered for the given host, or `nil` if none matches.
    ///
    /// Entries are evaluated in registration order and the **first** match wins.
    /// Register more specific patterns before broader ones to ensure correct matching.
    internal func evaluator(for host: String) -> (any ServerTrustEvaluating)? {
        entries.first { entry in
            host.firstMatch(of: entry.pattern) != nil
        }?.evaluator
    }
}

@globalActor public actor CertificatePinningActor: GlobalActor {
    static public let shared = CertificatePinningActor()
}
