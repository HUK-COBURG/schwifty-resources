//
//  Response.swift
//
//
//  Created by Johannes Bosecker on 28.11.22.
//

import struct Foundation.Data
import class Foundation.HTTPURLResponse

public struct Response<BodyResourceCoder: ResourceCoder> {
    /// The HTTP status of the response. Represented by the `HttpStatus` enumeration.
    public let status: HttpStatus
    /// All headers of the response.
    public let headers: [AnyHashable: Any]
    /// The type safe body of the response.
    public let body: BodyResourceCoder.Content
}

public extension Response {
    init(httpUrlResponse: HTTPURLResponse, data: Data) throws {
        let bodyResourceCoder = BodyResourceCoder()

        status = httpUrlResponse.httpStatus
        headers = httpUrlResponse.allHeaderFields
        body = try bodyResourceCoder.decode(data: data)
    }
}
