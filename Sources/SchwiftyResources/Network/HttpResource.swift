//
//  Resource.swift
//
//
//  Created by Johannes Bosecker on 25.11.22.
//

import Foundation

public protocol HttpResource {
    /// The type of the request body encoder. Must conform to `ResourceCoder`.
    associatedtype RequestBodyResourceCoder: ResourceCoder
    /// The type of the response body decoder. Must conform to `ResourceCoder`.
    associatedtype ResponseBodyResourceCoder: ResourceCoder

    /// The instance of the request body encoder.
    var requestBodyResourceCoder: RequestBodyResourceCoder { get }
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
    var requestBody: RequestBodyResourceCoder.Content { get }
    /// An array of instances of types, which conform to `RequestModifier`. They will be executed before the request is sent in the order of the array. Defaults to nil.
    var requestModifiers: [RequestModifier]? { get }
    /// Asynchronous response for the request.
    var response: Response<ResponseBodyResourceCoder> { get async throws }
    /// This handler will be called whenever the requests progress is evolving. This handler will only be called on iOS 15 and above. Defaults to nil.
    var sendProgressHandler: ProgressHandler? { get }
    /// This handler will be called whenever the responses progress is evolving. This handler will only be called on iOS 15 and above. Defaults to nil.
    var receiveProgressHandler: ProgressHandler? { get }
}

public extension HttpResource {
    var requestBodyResourceCoder: RequestBodyResourceCoder {
        RequestBodyResourceCoder()
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

    var response: Response<ResponseBodyResourceCoder> {
        get async throws {
            let urlRequest = try await buildUrlRequest()

            do {
                let (data, urlResponse) = try await URLSession.schwiftyResourcesUrlSession.data(for: urlRequest,
                                                                                                sendProgressHandler: sendProgressHandler,
                                                                                                receiveProgressHandler: receiveProgressHandler)

                do {
                    guard let httpUrlResponse = urlResponse as? HTTPURLResponse else {
                        throw SchwiftyResourcesError.wrongResponse
                    }

                    guard httpUrlResponse.statusCode >= 200, httpUrlResponse.statusCode < 300 else {
                        throw SchwiftyResourcesError.httpStatus(httpUrlResponse.httpStatus)
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

    // MARK: - Private functions

    private func buildUrlRequest() async throws -> URLRequest {
        let url = try await buildUrl()

        var urlRequest = URLRequest(url: url)
        urlRequest.method = method
        urlRequest.allHTTPHeaderFields = requestHeader
        urlRequest.httpBody = try requestBodyResourceCoder.encode(content: requestBody)

        if let contentType = requestBodyResourceCoder.contentType {
            urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        if let requestTimeout = requestTimeout {
            urlRequest.timeoutInterval = requestTimeout
        }

        if let requestModifiers = requestModifiers {
            for requestModifier in requestModifiers {
                urlRequest = try await requestModifier.modify(request: urlRequest, networkResource: self)
            }
        }

        return urlRequest
    }

    private func buildUrl() async throws -> URL {
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

        var newQueryItems: [URLQueryItem] = urlComponents.queryItems ?? []
        newQueryItems.append(contentsOf: queryItems ?? [])
        urlComponents.queryItems = newQueryItems.count > 0 ? newQueryItems : nil

        guard let composedUrl = urlComponents.url else {
            throw SchwiftyResourcesError.urlBroken
        }

        return composedUrl
    }
}

public extension HttpResource where RequestBodyResourceCoder == EmptyResourceCoder {
    var requestBody: RequestBodyResourceCoder.Content {
        return ()
    }
}

private enum ErrorWrapper: Error {
    case wrapped(Error)
}
