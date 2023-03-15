//
//  URLProtocolStub.swift
//  URLProtocolHelpers
//
//  Created by Andris Lejasmeiers on 01/09/2020.
//

import Foundation

open class URLProtocolStub: URLProtocol {
  open override class func canInit(with request: URLRequest) -> Bool {
    result(in: request) != nil
  }

  open override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  open override func startLoading() {
    guard let result = Self.result(in: request) else {
      return
    }
    guard let client else {
      return
    }
    switch result {
    case let .success(data, response, delay):
      if delay > 0 {
        Thread.sleep(forTimeInterval: delay)
      }
      client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client.urlProtocol(self, didLoad: data)
    case let .failure(error, delay):
      if delay > 0 {
        Thread.sleep(forTimeInterval: delay)
      }
      client.urlProtocol(self, didFailWithError: error)
    case let .redirect(request, response):
      client.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
    }
    client.urlProtocolDidFinishLoading(self)
  }

  open override func stopLoading() {}
}

public extension URLProtocolStub {
  enum Result {
    case success(
      Data = Data(),
      URLResponse = URLResponse(),
      TimeInterval = 0
    )
    case failure(
      Error,
      TimeInterval = 0
    )
    case redirect(
      URLRequest,
      URLResponse = URLResponse()
    )
  }

  static let resultPropertyKey = "URLProtocolStubResult"

  static func result(in request: NSMutableURLRequest) -> Result? {
    result(in: request as URLRequest)
  }

  static func result(in request: URLRequest) -> Result? {
    property(forKey: resultPropertyKey, in: request) as? Result
  }

  static func setResult(_ value: Result, in request: NSMutableURLRequest) {
    setProperty(value, forKey: resultPropertyKey, in: request)
  }

  static func removeResult(in request: NSMutableURLRequest) {
    removeProperty(forKey: resultPropertyKey, in: request)
  }
}
