# URLProtocolHelpers

Provides a `URLProtocolStub` testing double implementing `URLProtocol`.
Allows to pre-configure the data and response or error of an `URLRequest` result. If result is not specified, the `URLSession's` task would time out returning `NSURLErrorTimedOut` error code.

## Usage

```swift
func testSuccessPath() {
  // Given
  let configuration = URLSessionConfiguration.ephemeral
  configuration.protocolClasses = [URLProtocolStub.self]
  
  let session = URLSession(configuration: configuration)
  let url = URL(string: "https://rabobank.nl")!
  let request = NSMutableURLRequest(url: url)
  
  let testData = "first".data(using: .utf8)!
  let testResponse = HTTPURLResponse(
    url: url,
    statusCode: 200,
    httpVersion: nil,
    headerFields: nil
  )!

  defer {
    URLProtocolStub.removeResult(in: request)
  }

  // When
  URLProtocolStub.setResult(.success(testData, testResponse), in: request)

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
```
