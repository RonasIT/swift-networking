//
// Created by Nikita Zatsepilov on 2019-01-26.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking
import Alamofire
import XCTest

final class EndpointTests: XCTestCase {

    func testValidEndpointURL() {
        var endpoint = MockEndpoint()
        endpoint.baseURL = URL(string: "https://apple.com")!
        endpoint.path = "iphone"
        XCTAssertEqual(endpoint.url.absoluteString, "https://apple.com/iphone")
    }
    
    func testDefaultEndpointErrors() {
        struct TestEndpoint: Endpoint {
            var baseURL: URL { return URL(string: "localhost")! }
            var path: String { return "test" }
            var method: HTTPMethod { return .get }
            var headers: [RequestHeader] { return [] }
            var parameters: Parameters? { return nil }
            var parameterEncoding: ParameterEncoding { return URLEncoding.default }
            var requiresAuthorization: Bool { return false }
        }
        
        let endpoint = TestEndpoint()
        XCTAssertNil(endpoint.error(for: .cancelled))
        XCTAssertNil(endpoint.error(forResponseCode: 400))
    }

    // MARK: - Headers
    
    func testHTTPHeadersConversion() {
        struct Header: RequestHeader, Equatable {
            let key: String
            let value: String
        }

        let expectedHTTPHeaders = [
            "key0": "overriddenValue0",
            "key1": "overriddenValue1",
            "key2": "value2"
        ]

        let headers: [RequestHeader] = [
            Header(key: "key0", value: "value0"),
            Header(key: "key1", value: "value1"),
            Header(key: "key2", value: "value2"),
            // Values of duplicated keys will be overridden
            Header(key: "key0", value: "overriddenValue0"),
            Header(key: "key1", value: "overriddenValue1"),
        ]

        XCTAssertEqual(headers.httpHeaders, expectedHTTPHeaders)
    }

    func testCommonHeaders() {
        var header = RequestHeaders.authorization("token")
        XCTAssertEqual(header.key, "Authorization")
        XCTAssertEqual(header.value, "Bearer token")

        header = RequestHeaders.contentType("application/json")
        XCTAssertEqual(header.key, "Content-Type")
        XCTAssertEqual(header.value, "application/json")

        header = RequestHeaders.dpi(scale: 2.0)
        XCTAssertEqual(header.key, "dpi")
        XCTAssertEqual(header.value, "@2x")


        header = RequestHeaders.userAgent(osVersion: "12.0", appVersion: "1.0.0")
        XCTAssertEqual(header.key, "User-Agent")
        XCTAssertEqual(header.value, "iOS 12.0 version 1.0.0")
    }
}
