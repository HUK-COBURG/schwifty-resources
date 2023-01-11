//
//  Response.swift
//
//
//  Created by Johannes Bosecker on 28.11.22.
//

import struct Foundation.Data
import class Foundation.HTTPURLResponse

public struct Response<BodyResourceDecoder: ResourceDecoder> {
    /// The HTTP status of the response. Represented by the `HttpStatus` enumeration.
    public let status: HttpStatus
    /// All headers of the response.
    public let headers: [AnyHashable: Any]
    /// The type safe body of the response.
    public let body: BodyResourceDecoder.Content
}

public extension Response {
    init(httpUrlResponse: HTTPURLResponse, data: Data) throws {
        let bodyResourceDecoder = BodyResourceDecoder()

        status = httpUrlResponse.httpStatus
        headers = httpUrlResponse.allHeaderFields
        body = try bodyResourceDecoder.decode(data: data)
    }
}
