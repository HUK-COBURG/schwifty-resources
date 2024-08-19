//
//  Resource.swift
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

public protocol HttpResource {
    /// The type of the request body encoder. Must conform to `ResourceCoder`.
    associatedtype RequestBodyResourceEncoder: ResourceEncoder
    /// The type of the response body decoder. Must conform to `ResourceCoder`.
    associatedtype ResponseBodyResourceDecoder: ResourceDecoder

    /// The instance of the request body encoder.
    var requestBodyResourceEncoder: RequestBodyResourceEncoder { get }
    /// An instance of a type, which conforms to `PathModifier`. This can be used to manipulate the URLs path, before the request is sent. Defaults to nil.
    var pathModifier: PathModifier? { get }
    /// The desired HTTP method (e.g. GET, POST, DELETE etc.). Defaults to GET.
    var method: HttpMethod { get }
    /// The URL of the request. This will be modified by `pathModifier` and `requestQuery`.
    var url: URL { get async throws }
    /// The given headers will be appended to the requests headers. Existing headers will be overridden. Defaults to nil.
    var requestHeader: [String: String]? { get }
    /// The given query items will be appended to the URL. Existing query items will be overridden. Defaults to nil.
    var requestQuery: [String: String]? { get }
    /// Defines the time interval of the request. If this is set to nil, the default value of `URLRequest.timeoutInterval` will be used. Defaults to nil.
    var requestTimeout: TimeInterval? { get }
    /// The requests body, which will be sent to the server. The type is defined by the `BodyEncoder`.
    var requestBody: RequestBodyResourceEncoder.Content { get }
    /// An array of instances of types, which conform to `RequestModifier`. They will be executed before the request is sent in the order of the array. Defaults to nil.
    var requestModifiers: [RequestModifier]? { get }
    /// Asynchronous response for the request.
    var response: Response<ResponseBodyResourceDecoder> { get async throws }
    /// This handler will be called whenever the requests progress is evolving. This handler will only be called on iOS 15 and above. Defaults to nil.
    var sendProgressHandler: ProgressHandler? { get }
    /// This handler will be called whenever the responses progress is evolving. This handler will only be called on iOS 15 and above. Defaults to nil.
    var receiveProgressHandler: ProgressHandler? { get }
    /// The URLSessionConfiguration used for SchwiftyResourcesUrlSession.
    var urlSessionConfiguration: URLSessionConfiguration { get }
}

public extension HttpResource {
    var requestBodyResourceEncoder: RequestBodyResourceEncoder {
        RequestBodyResourceEncoder()
    }

    var pathModifier: PathModifier? {
        return nil
    }

    var method: HttpMethod {
        return .get
    }

    var requestHeader: [String: String]? {
        return nil
    }

    var requestQuery: [String: String]? {
        return nil
    }

    var requestTimeout: TimeInterval? {
        return nil
    }

    var requestModifiers: [RequestModifier]? {
        return nil
    }

    var response: Response<ResponseBodyResourceDecoder> {
        get async throws {
            let urlRequest = try await buildUrlRequest()

            do {
                let (data, urlResponse) = try await URLSession
                    .makeSchwiftyResourcesUrlSession(with: urlSessionConfiguration)
                    .data(for: urlRequest, sendProgressHandler: sendProgressHandler, receiveProgressHandler: receiveProgressHandler)

                do {
                    guard let httpUrlResponse = urlResponse as? HTTPURLResponse else {
                        throw SchwiftyResourcesError.wrongResponse
                    }

                    guard httpUrlResponse.statusCode >= 200, httpUrlResponse.statusCode < 300 else {
                        throw SchwiftyResourcesError.httpStatus(httpUrlResponse.httpStatus, String(data: data, encoding: .utf8))
                    }

                    return try Response(httpUrlResponse: httpUrlResponse, data: data)
                } catch {
                    throw ErrorWrapper.wrapped(error)
                }
            } catch {
                if (error as NSError).code == NSURLErrorCancelled {
                    throw SchwiftyResourcesError.cancelled(error)
                } else if (error as NSError).code == NSURLErrorTimedOut {
                    throw SchwiftyResourcesError.timedOut(error)
                } else if (error as NSError).code == NSURLErrorSecureConnectionFailed ||
                    (error as NSError).code == NSURLErrorServerCertificateUntrusted ||
                    (error as NSError).code == NSURLErrorServerCertificateHasUnknownRoot
                {
                    throw SchwiftyResourcesError.secureConnectionFailed(error)
                } else if let error = error as? ErrorWrapper, case let .wrapped(wrappedError) = error {
                    throw wrappedError
                } else {
                    throw SchwiftyResourcesError.requestFailed(error)
                }
            }
        }
    }

    var sendProgressHandler: ProgressHandler? {
        return nil
    }

    var receiveProgressHandler: ProgressHandler? {
        return nil
    }
    
    var urlSessionConfiguration: URLSessionConfiguration {
        .default
    }

    // MARK: - Internal functions

    internal func buildUrlRequest() async throws -> URLRequest {
        let url = try await buildUrl()

        var urlRequest = URLRequest(url: url)
        urlRequest.method = method
        urlRequest.allHTTPHeaderFields = requestHeader
        urlRequest.httpBody = try requestBodyResourceEncoder.encode(content: requestBody)

        if let contentType = requestBodyResourceEncoder.contentType {
            urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        if let requestTimeout = requestTimeout {
            urlRequest.timeoutInterval = requestTimeout
        }

        if let requestModifiers = requestModifiers {
            for requestModifier in requestModifiers {
                urlRequest = try await requestModifier.modify(request: urlRequest, httpResource: self)
            }
        }

        return urlRequest
    }

    internal func buildUrl() async throws -> URL {
        let url = try await self.url

        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw SchwiftyResourcesError.urlBroken
        }

        if let pathModifier = pathModifier {
            urlComponents.path = pathModifier.modify(path: urlComponents.path)
        }

        let queryItems = requestQuery?.keys.map { key in
            let value = requestQuery?[key]
            return URLQueryItem(name: key, value: value)
        }

        var newQueryItems = urlComponents.percentEncodedQueryItems ?? []
        
        urlComponents.queryItems = queryItems
        
        newQueryItems.append(contentsOf: urlComponents.percentEncodedQueryItems ?? [])
        newQueryItems.sort { lhs, rhs in
            return lhs.name < rhs.name
        }
        urlComponents.percentEncodedQueryItems = newQueryItems.count > 0 ? newQueryItems : nil

        guard let composedUrl = urlComponents.url else {
            throw SchwiftyResourcesError.urlBroken
        }

        return composedUrl
    }
}

public extension HttpResource where RequestBodyResourceEncoder == EmptyResourceCoder {
    var requestBody: RequestBodyResourceEncoder.Content {
        return ()
    }
}

private enum ErrorWrapper: Error {
    case wrapped(Error)
}
