# SSL Pinning

SchwiftyResources provides an extensible server trust evaluation system through the `ServerTrustEvaluating` protocol. You can use the built-in evaluators or implement your own custom pinning strategy.

## How It Works

All trust evaluation is managed by the `ServerTrustRegistry` singleton. You register evaluators for host patterns (using `Regex`), and the library's URLSession delegate automatically consults the registry during TLS handshakes.

- Evaluators are matched in **registration order** (first match wins).
- If no evaluator matches a host, the system performs **default handling** (standard certificate validation).
- Register more specific patterns **before** broader catch-all patterns.

## Certificate Pinning

The simplest use case is pinning a DER-encoded certificate for a specific host. Bundle the `.der` file in your app and register it at startup:

```swift
import SchwiftyResources

// Load the DER certificate from the app bundle.
guard let certUrl = Bundle.main.url(forResource: "server", withExtension: "der"),
      let certData = try? Data(contentsOf: certUrl),
      let certificate = SecCertificateCreateWithData(nil, certData as NSData)
else {
    fatalError("Failed to load pinned certificate.")
}

let evaluator = CertificateServerTrustEvaluator(certificates: [certificate])

await ServerTrustRegistry.sharedInstance.register(
    evaluator,
    for: try! Regex(".*\\.example\\.com")
)
```

> To convert a PEM certificate to DER:
> ```
> openssl x509 -in certificate.pem -outform der -out certificate.der
> ```

## Custom Server Trust Evaluation

To implement a custom pinning strategy, conform to `ServerTrustEvaluating`:

```swift
public protocol ServerTrustEvaluating: Sendable {
    func evaluate(_ serverTrust: SecTrust, for host: String) throws -> Bool
}
```

### Example: SPKI Hash Pinning

This evaluator pins the SHA-256 hash of the server's public key (Subject Public Key Info), a common alternative to pinning the full certificate.

```swift
import SchwiftyResources
import Security
import CommonCrypto

struct SPKIHashServerTrustEvaluator: ServerTrustEvaluating {
    let pinnedHashes: Set<String>

    func evaluate(_ serverTrust: SecTrust, for host: String) throws -> Bool {
        guard let chain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            return false
        }

        for certificate in chain {
            guard let publicKey = SecCertificateCopyKey(certificate),
                  let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?
            else {
                continue
            }

            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            _ = publicKeyData.withUnsafeBytes {
                CC_SHA256($0.baseAddress, CC_LONG(publicKeyData.count), &hash)
            }
            let hashBase64 = Data(hash).base64EncodedString()

            if pinnedHashes.contains(hashBase64) {
                return true
            }
        }
        return false
    }
}
```

Register it like any other evaluator:

```swift
await ServerTrustRegistry.sharedInstance.register(
    SPKIHashServerTrustEvaluator(pinnedHashes: [
        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
    ]),
    for: try! Regex(".*\\.example\\.com")
)
```

## Built-in Evaluators

| Evaluator | Description |
|---|---|
| `CertificateServerTrustEvaluator` | Pins DER-encoded certificates as anchor certificates. |
| `DefaultServerTrustEvaluator` | Performs the system's default certificate validation (no custom pinning). |
| `CompositeServerTrustEvaluator` | Combines multiple evaluators — all must pass (logical AND). |

### Composing Evaluators

Use `CompositeServerTrustEvaluator` to chain strategies. For example, require both system trust validation and SPKI hash pinning:

```swift
let composite = CompositeServerTrustEvaluator(evaluators: [
    DefaultServerTrustEvaluator(),
    SPKIHashServerTrustEvaluator(pinnedHashes: ["..."])
])

await ServerTrustRegistry.sharedInstance.register(
    composite,
    for: try! Regex(".*\\.example\\.com")
)
```
