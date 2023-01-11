//
//  Progress.swift
//
//
//  Created by Johannes Bosecker on 13.12.22.
//

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
