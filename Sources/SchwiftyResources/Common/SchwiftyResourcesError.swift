//
//  SchwiftyResourcesError.swift
//
//
//  Created by Johannes Bosecker on 12.12.22.
//

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
