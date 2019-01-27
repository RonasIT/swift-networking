//
// Created by Nikita Zatsepilov on 2019-01-26.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking
import Alamofire
import XCTest

final class ResponseSerializationTests: XCTestCase {

    func testJSONResponseSerialization() {
        let invalidJSON = "{ key: \"value\" }"
        let validJSON = "{ \"key\": \"value\" }"

        let invalidJSONData = invalidJSON.data(using: .utf8)!
        let validJSONData = validJSON.data(using: .utf8)!

        let serializer = JSONResponseSerializer(readingOptions: .allowFragments)
        XCTAssertTrue(serializer.serializeResponse(with: nil, request: nil, response: nil, error: nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: Data(), request: nil, response: nil, error: nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: nil, request: nil, response: nil, error: NSError()).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: invalidJSONData, request: nil, response: nil, error: nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: validJSONData, request: nil, response: nil, error: nil).isSuccess)
    }

    func testDecodableResponseSerialization() {
        final class User: Decodable {
            let name: String
            let email: String
        }

        let invalidJSON = "{ name: \"Test\", email: \"mail@mail.com\" }"
        let validJSON = "{ \"name\": \"Test\", \"email\": \"mail@mail.com\" }"

        let invalidJSONData = invalidJSON.data(using: .utf8)!
        let validJSONData = validJSON.data(using: .utf8)!

        let serializer: DecodableResponseSerializer<User> = DecodableResponseSerializer()
        XCTAssertTrue(serializer.serializeResponse(with: nil, request: nil, response: nil, error: nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: Data(), request: nil, response: nil, error: nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: nil, request: nil, response: nil, error: NSError()).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: invalidJSONData, request: nil, response: nil, error: nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: validJSONData, request: nil, response: nil, error: nil).isSuccess)
    }
}
