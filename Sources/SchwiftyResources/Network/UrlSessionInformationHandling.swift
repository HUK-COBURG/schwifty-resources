//
//  UrlSessionInformationHandling.swift
//
//
//  Created by Johannes Bosecker on 13.11.23.
//

import Foundation

public protocol UrlSessionInformationHandling {
    func willStart(request: URLRequest, identifier: String)
    func didCollectMetrics(_ metrics: URLSessionTaskMetrics, identifier: String)
    func didSucceed(response: URLResponse, data: Data, identifier: String)
    func didFail(error: Error, identifier: String)
}
