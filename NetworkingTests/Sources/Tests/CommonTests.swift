//
// Created by Nikita Zatsepilov on 2019-01-30.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking
import XCTest

final class CommonTests: XCTestCase {

    func testCustomDecodingErrorDescription() {
        let data = "{ \"key\": \"value\" }".data(using: .utf8)!
        let decoder = JSONDecoder()
        do {
            _ = try decoder.decode([String].self, from: data)
            XCTFail("Decoding should be failed")
        } catch let error as DecodingError {
            XCTAssertEqual(error.description, error.errorDescription)
        } catch {
            XCTFail("Unexpected error")
        }
    }

    func testCustomRequestHeader() {
        let key = "key"
        let value = "value"
        let header = RequestHeaders.custom(key: key, value: value)
        XCTAssertEqual(header.key, key, "Custom header key is not valid")
        XCTAssertEqual(header.value, value, "Custom header value is not valid")
    }
}
