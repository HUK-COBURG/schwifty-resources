//
//  SchwiftyResourcesError.swift
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

public enum SchwiftyResourcesError: Error {
    /// The response body could not be decoded as an UTF8 string
    case stringDecodingFailed
    /// The response could not be decoded as a JSON representation of the given type. Check the associated error for further information.
    case jsonDecodingFailed(Error)
    /// The response could not be encoded as JSON. Check the associated error for further information.
    case jsonEncodingFailed(Error)
    /// The response should be of kind `HTTPURLResponse`, but is not.
    case wrongResponse
    /// The URL of the request could not be constructed, due to some issue with it.
    case urlBroken
    /// The request was cancelled. Check the associated error for further information.
    case cancelled(Error)
    /// The request failed. This can be the case for various reasons (e.g. host not found, network issue, etc.). Check the associated error for further information.
    case requestFailed(Error)
    /// The request timed out. Check the associated error for further information.
    case timedOut(Error)
    /// A secure connection could not be established. Check the associated error for further information.
    case secureConnectionFailed(Error)
    /// The HTTP status code in the response was not between 200 and 299. You can check the associated `HttpStatus` for the returned status.
    case httpStatus(HttpStatus)
    /// The file was not found in the given bundle.
    case fileNotFound
    /// The file could not be read from the disk. Check the associated error for further information.
    case cannotReadFile(Error)
    /// The file could not be written to the disk. Check the associated error for further information.
    case cannotWriteFile(Error)
    /// The defined sandbox location does not exist.
    case sandboxLocationUnavailable
    /// An error occurred while decrypting the data. Check the associated error for further information.
    case decryptionFailed(Error?)
    /// An error occurred while encrypting the data. Check the associated error for further information.
    case encryptionFailed(Error?)
}
