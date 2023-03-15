//
//  URLProtocolHelpersTests.swift
//  URLProtocolHelpers
//
//  Created by Andris Lejasmeiers on 01/09/2020.
//

@testable import URLProtocolHelpers
import XCTest

final class URLProtocolHelpersTests: XCTestCase {
  let sut = URLProtocolStub.self
}

// MARK: - Factory methods

extension URLProtocolHelpersTests {
  static func makeSomeURL() -> URL {
    URL(string: "https://rabobank.nl")!
  }

  static func makeSomeRequest(from mutable: NSMutableURLRequest = makeSomeMutableRequest())
  -> URLRequest {
    mutable as URLRequest
  }

  static func makeSomeMutableRequest(url: URL = makeSomeURL()) -> NSMutableURLRequest {
    NSMutableURLRequest(url: url)
  }

  static func makeSession(config: URLSessionConfiguration = makeSessionConfig()) -> URLSession {
    URLSession(configuration: config)
  }

  static func makeSessionConfig() -> URLSessionConfiguration {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolStub.self]
    return config
  }
}

// MARK: - Test the result property

extension URLProtocolHelpersTests {
  func test00ResultWhenNotSet() {
    // Given
    let request = Self.makeSomeMutableRequest()
    // When
    let result = sut.result(in: request)
    // Then
    XCTAssertNil(result)
  }

  func test01ResultWhenRequestCreatedAsMutable() {
    // Given
    let request = Self.makeSomeMutableRequest()

    defer {
      sut.removeResult(in: request)
    }

    // When
    sut.setResult(.success(), in: request)
    let result = sut.result(in: request)

    // Then
    XCTAssertNotNil(result)
    guard case .success = result else {
      return XCTFail("Expected .success")
    }
  }

  /// The intention of the test is to show what happens when casting
  /// a Swift URLRequest to an Obj-C NSMutableURLRequest.
  /// The cast succeeds, but because URLRequest is a struct (value type),
  /// casting creates a new NSMutableURLRequest instance. Setting a result
  /// on the mutable version doesn't affect the original request, demonstrating
  /// the difference between value semantics (structs) and reference semantics (classes).
  func test02ResultWhenForceCasting() throws {
    // Given
    let request = Self.makeSomeRequest()
    let mutableRequest = try XCTUnwrap(request as? NSMutableURLRequest)

    // When
    sut.setResult(.success(), in: mutableRequest)
    let failureResult = sut.result(in: request)
    let successResult = sut.result(in: mutableRequest)

    // Then
    XCTAssertNil(failureResult)
    XCTAssertNotNil(successResult)
  }

  func test03ResultWhenRemoved() {
    // Given
    let request = Self.makeSomeMutableRequest()

    // When
    sut.setResult(.success(), in: request)
    let resultBeforeRemoval = sut.result(in: request)
    sut.removeResult(in: request)
    let resultAfterRemoval = sut.result(in: request)

    // Then
    XCTAssertNotNil(resultBeforeRemoval)
    XCTAssertNil(resultAfterRemoval)
  }

  func test04ResultWhenMultipleAreSet() {
    // Given
    let firstRequest = Self.makeSomeMutableRequest()
    let secondRequest = Self.makeSomeMutableRequest()
    let firstTestData = "first".data(using: .utf8)!
    let secondTestData = "second".data(using: .utf8)!

    defer {
      sut.removeResult(in: firstRequest)
      sut.removeResult(in: secondRequest)
    }

    // When
    sut.setResult(.success(firstTestData), in: firstRequest)
    sut.setResult(.success(secondTestData), in: secondRequest)
    let firstResult = sut.result(in: firstRequest)
    let secondResult = sut.result(in: secondRequest)

    // Then
    XCTAssertNotNil(firstResult)
    if case let .success(data, _, _) = firstResult {
      XCTAssertEqual(data, firstTestData)
    } else {
      XCTFail("Expected .success on first result")
    }

    XCTAssertNotNil(secondResult)
    if case let .success(data, _, _) = secondResult {
      XCTAssertEqual(data, secondTestData)
    } else {
      XCTFail("Expected .success on second result")
    }
  }
}

// MARK: - Test the CanInit method

extension URLProtocolHelpersTests {
  func test05CanInitWhenResultUnspecified() {
    // Given
    let request = Self.makeSomeMutableRequest()
    // When
    let flag = sut.canInit(with: request as URLRequest)
    // Then
    XCTAssertFalse(flag)
  }

  func test06CanInitWhenResultSpecified() {
    // Given
    let request = Self.makeSomeMutableRequest()

    defer {
      sut.removeResult(in: request)
    }

    // When
    sut.setResult(.success(), in: request)
    let result = sut.canInit(with: request as URLRequest)

    // Then
    XCTAssertTrue(result)
  }
}

// MARK: - Test the startLoading method

extension URLProtocolHelpersTests {
  func test07LoadingNotFinishedWhenResultNotSet() {
    // Given
    class URLProtocolSubStub: URLProtocolStub {
      open override class func canInit(with _: URLRequest) -> Bool { true }
    }

    let config = Self.makeSessionConfig()
    config.protocolClasses = [URLProtocolSubStub.self]

    let session = Self.makeSession(config: config)
    let request = Self.makeSomeMutableRequest()
    request.timeoutInterval = 0.01

    // When
    let expect = expectation(description: #function)
    var requestError: Error?
    session
      .dataTask(with: request as URLRequest) { _, _, error in
        requestError = error
        expect.fulfill()
      }
      .resume()

    // Then
    waitForExpectations(timeout: 0.1)

    guard let error = requestError as NSError? else {
      return XCTFail("Expected NSError error")
    }
    XCTAssertEqual(error.code, NSURLErrorTimedOut)
  }

  func test08RequestWithSuccessfulResult() {
    // Given
    let session = Self.makeSession()
    let request = Self.makeSomeMutableRequest()
    let testData = Data()
    let testResponse = URLResponse()

    defer {
      sut.removeResult(in: request)
    }

    // When
    sut.setResult(.success(testData, testResponse), in: request)

    let expect = expectation(description: #function)
    var resultData: Data?
    var resultResponse: URLResponse?
    var responseError: Error?
    session
      .dataTask(with: request as URLRequest) { data, response, error in
        resultData = data
        resultResponse = response
        responseError = error
        expect.fulfill()
      }
      .resume()

    // Then
    waitForExpectations(timeout: 0.1)

    XCTAssertNil(responseError)
    XCTAssertEqual(testData, resultData)
    XCTAssertEqual(testResponse.url, resultResponse?.url)
  }

  func test09RequestWithFailureResult() {
    // Given
    let session = Self.makeSession()
    let request = Self.makeSomeMutableRequest()
    let testError = NSError(
      domain: NSURLErrorDomain,
      code: NSURLErrorBadServerResponse,
      userInfo: nil
    )

    defer {
      sut.removeResult(in: request)
    }

    // When
    sut.setResult(.failure(testError), in: request)

    let expect = expectation(description: #function)
    var requestData: Data?
    var requestResponse: URLResponse?
    var requestError: NSError?
    session
      .dataTask(with: request as URLRequest) { data, response, error in
        requestData = data
        requestResponse = response
        requestError = error as? NSError
        expect.fulfill()
      }
      .resume()

    // Then
    waitForExpectations(timeout: 0.1)

    XCTAssertEqual(requestError?.domain, testError.domain)
    XCTAssertEqual(requestError?.code, testError.code)
    XCTAssertNil(requestData)
    XCTAssertNil(requestResponse)
  }

  func test10RequestWithDelayedSuccessfulResult() {
    // Given
    let session = Self.makeSession()
    let request = Self.makeSomeMutableRequest()
    let testData = Data()
    let testResponse = URLResponse()

    defer {
      sut.removeResult(in: request)
    }

    // When
    sut.setResult(.success(testData, testResponse, 1.0), in: request)

    let taskCompleted = expectation(description: #function)
    taskCompleted.isInverted = true
    session
      .dataTask(with: request as URLRequest) { _, _, _ in
        taskCompleted.fulfill()
      }
      .resume()

    // Then
    // Without the delay (Thread.sleep at startLoading), the expectation here would fail.
    waitForExpectations(timeout: 0.01)
  }
}
