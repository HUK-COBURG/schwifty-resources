//
//  UrlSession+SchwiftyResources.swift
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

typealias MetricsHandler = (URLSessionTaskMetrics) -> Void

extension URLSession {
    private static var schwiftyResourcesUrlSessionDelegate = SchwiftyResourcesUrlSessionDelegate()
    static var schwiftyResourcesUrlSession = URLSession(configuration: .default,
                                                    delegate: schwiftyResourcesUrlSessionDelegate,
                                                    delegateQueue: nil)

    /// Convenience method to load data using an URLRequest.
    /// If using iOS 15 and above the given `sendProgressHandler` and `receiveProgressHandler` will be called while sending and receiving.
    /// Internally either `bytes(for:delegate)` (>= iOS 15) or `data(for:)` will be used.
    ///
    /// - Parameter request: The URLRequest for which to load data.
    /// - Parameter sendProgressHandler: An optional closure for handling send progress updates.
    /// - Parameter receiveProgressHandler: An optional closure for handling receive progress updates. Will be called every kilobyte of received data.
    /// - Returns: Data and response.
    func data(for request: URLRequest, sendProgressHandler: ProgressHandler?, receiveProgressHandler: ProgressHandler?, metricsHandler: MetricsHandler?) async throws -> (Data, URLResponse) {
        if #available(iOS 15.0, *), sendProgressHandler != nil || receiveProgressHandler != nil || metricsHandler != nil {
            let delegateHandler = URLSessionTaskDelegateHandler(sendProgressHandler: sendProgressHandler, metricsHandler: metricsHandler)
            let (bytes, response) = try await bytes(for: request, delegate: delegateHandler)

            let countOfBytesExpectedToReceive = bytes.task.countOfBytesExpectedToReceive
            var data = Data()

            for try await byte in bytes {
                data.append(byte)

                let bytesDone = Int64(data.count)

                if let receiveProgressHandler = receiveProgressHandler,
                   bytesDone % 1024 == 0 || bytesDone == countOfBytesExpectedToReceive
                {
                    let progress = Progress(bytesDone: Int64(data.count), bytesOverall: countOfBytesExpectedToReceive)
                    receiveProgressHandler(progress)
                }
            }

            return (data, response)
        } else {
            return try await data(for: request)
        }
    }
}

private class SchwiftyResourcesUrlSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let certificates = CertificatePinningRegistry.sharedInstance.registeredCertificates(for: challenge.protectionSpace.host)
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let status = SecTrustSetAnchorCertificates(serverTrust, certificates as NSArray)

        guard status == errSecSuccess else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        var error: CFError?
        let isTrusted = SecTrustEvaluateWithError(serverTrust, &error)

        guard isTrusted else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}

private class URLSessionTaskDelegateHandler: NSObject, URLSessionTaskDelegate {
    let sendProgressHandler: ProgressHandler?
    let metricsHandler: MetricsHandler?

    init(sendProgressHandler: ProgressHandler?, metricsHandler: MetricsHandler?) {
        self.sendProgressHandler = sendProgressHandler
        self.metricsHandler = metricsHandler
    }

    func urlSession(_: URLSession, task _: URLSessionTask, didSendBodyData _: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let sendProgressHandler = sendProgressHandler else {
            return
        }

        let progress = Progress(bytesDone: totalBytesSent, bytesOverall: totalBytesExpectedToSend)
        sendProgressHandler(progress)
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        session.delegate?.urlSession?(session, didReceive: challenge, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        metricsHandler?(metrics)
    }
}
