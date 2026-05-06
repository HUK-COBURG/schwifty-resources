//
//  CertificateServerTrustEvaluator.swift
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

/// Evaluates server trust by pinning DER-encoded certificates as anchor certificates.
///
/// immutable and thread-safe but not formally marked `Sendable` by the SDK.
public struct CertificateServerTrustEvaluator: ServerTrustEvaluating {
    /// Pinned anchor certificates.
    ///
    /// `nonisolated(unsafe)` opts this single stored property out of Swift 6's
    /// Sendable checking. The vouch is safe because:
    ///   * The property is `let` — it is never mutated after `init`.
    ///   * `SecCertificate` instances are immutable once created and Apple documents
    ///     them as safe for concurrent read access.
    ///   * Recent SDKs mark `SecCertificate` as `Sendable`; on those toolchains
    ///     the compiler will emit a "`nonisolated(unsafe)` is unnecessary" warning,
    ///     which is expected. The annotation remains to support older SDKs where
    ///     the conformance has not been backfilled.
    private nonisolated(unsafe) let certificates: [SecCertificate]

    /// Creates an evaluator that pins the given certificates.
    public init(certificates: [SecCertificate]) {
        self.certificates = certificates
    }

    public func evaluate(_ serverTrust: SecTrust, for host: String) throws -> Bool {
        guard !certificates.isEmpty else {
            return false
        }

        let status = SecTrustSetAnchorCertificates(serverTrust, certificates as NSArray)
        guard status == errSecSuccess else {
            return false
        }

        var error: CFError?
        let trusted = SecTrustEvaluateWithError(serverTrust, &error)
        if let error { throw error as Error }
        return trusted
    }
}
