//
//  CertificatePinning.swift
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

/// With this registry it is possible to register specific certificates for a given regular expression.
/// Example: ".*\.huk-coburg\.cloud" will match "foo.huk-coburg.cloud" and "bar.huk-coburg.cloud"
/// It is possible to register multiple certificates for one regular expression. All of the registered certificates will be evaluated.
/// If the given certificate is not found or cannot be read, the evaluation will fail, because an entry for the regular expression was added.
/// The certficate needs to be in the DER format.
/// To convert a PEM to DER:
/// openssl x509 -in certificate.pem -outform der -out certificate.der
public class CertificatePinningRegistry {
    // MARK: - Private structs

    private struct Entry {
        let regularExpression: NSRegularExpression
        let certificate: SecCertificate?
    }

    // MARK: - Singleton

    public static let sharedInstance = CertificatePinningRegistry()

    // MARK: - Private properties

    private var entries: [Entry] = []

    // MARK: - Initialiser

    private init() {}

    // MARK: - Public functions

    public func registerCertificate(fileUrl: URL?, for regularExpression: NSRegularExpression) {
        var certificate: SecCertificate?

        if let fileUrl = fileUrl,
           let data = try? Data(contentsOf: fileUrl)
        {
            certificate = SecCertificateCreateWithData(nil, data as NSData)
        }

        entries.append(Entry(regularExpression: regularExpression, certificate: certificate))
    }

    public func registeredCertificates(for host: String) -> [SecCertificate]? {
        let filteredEntries = entries.filter { entry in
            let numberOfMatches = entry.regularExpression.numberOfMatches(in: host, range: NSRange(location: 0, length: host.count))
            return numberOfMatches > 0
        }

        guard filteredEntries.count > 0 else {
            return nil
        }

        let certificates: [SecCertificate] = filteredEntries.compactMap { entry in
            entry.certificate
        }

        return certificates
    }
}
