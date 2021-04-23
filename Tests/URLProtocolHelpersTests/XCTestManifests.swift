//
//  XCTestManifests.swift
//  URLProtocolHelpers
//
//  Created by Andris Lejasmeiers on 01/09/2020.
//

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  [testCase(URLProtocolHelpersTests.allTests)]
}
#endif
