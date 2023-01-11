//
//  Progress.swift
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

/// Represents the process of something related to byte loading.
/// It is initialised with the number of bytes, which are already done (`bytesDone`) und the overall number of bytes (`bytesOverall`).
/// You can get a value between 0.0 and 1.0 from the `value` property.
public struct Progress {
    public let bytesDone: Int64
    public let bytesOverall: Int64
    /// Value between 0.0 and 1.0
    public var value: Float {
        guard bytesOverall > 0 else {
            return 0
        }

        return Float(bytesDone) / Float(bytesOverall)
    }
}

public typealias ProgressHandler = (Progress) -> Void
