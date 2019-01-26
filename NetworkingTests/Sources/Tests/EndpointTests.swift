//
// Created by Nikita Zatsepilov on 2019-01-26.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking
import XCTest

final class EndpointTests: XCTestCase {

    func testValidEndpointURL() {
        let baseURL = URL(string: "https://apple.com")!
        let path = "iphone"
        let endpoint = MockEndpoint.urlValidation(baseURL: baseURL, path: path)
        XCTAssertEqual(endpoint.url.absoluteString, "https://apple.com/iphone")
    }
}
