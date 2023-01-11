//
//  Response.swift
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
