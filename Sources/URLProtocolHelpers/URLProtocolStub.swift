//
//  URLProtocolStub.swift
//  URLProtocolHelpers
//
//  Created by Andris Lejasmeiers on 01/09/2020.
//

import Foundation

open class URLProtocolStub: URLProtocol {
  public enum Result {
    case success(Data = Data(), URLResponse = URLResponse(), delay: TimeInterval = 0)
    case failure(Error)
    case redirect(URLRequest, URLResponse = URLResponse())
  }

  private static let resultPropertyKey = "result"

  open override class func canInit(with request: URLRequest) -> Bool {
    Self.result(in: request) != nil
  }

  open override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  open override func startLoading() {
    guard let result = Self.result(in: request) else { return }
    switch result {
    case let .success(data, response, delay):
      if delay > 0 {
        Thread.sleep(forTimeInterval: delay)
      }
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
    case let .failure(error):
      client?.urlProtocol(self, didFailWithError: error)
    case let .redirect(request, response):
      client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
    }
    client?.urlProtocolDidFinishLoading(self)
  }

  open override func stopLoading() {}
}

public extension URLProtocolStub {
  class func result(in request: NSMutableURLRequest) -> Result? {
    result(in: request as URLRequest)
  }

  class func result(in request: URLRequest) -> Result? {
    property(forKey: resultPropertyKey, in: request) as? Result
  }

  /// - Note: Providing an URLRequest casted to NSMutableURLRequest won't work!
  class func setResult(_ value: Result, in request: NSMutableURLRequest) {
    setProperty(value, forKey: resultPropertyKey, in: request)
  }

  class func removeResult(in request: NSMutableURLRequest) {
    removeProperty(forKey: resultPropertyKey, in: request)
  }
}
