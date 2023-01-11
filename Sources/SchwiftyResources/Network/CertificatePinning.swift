//
//  CertificatePinning.swift
//
//
//  Created by Johannes Bosecker on 12.12.22.
//

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
