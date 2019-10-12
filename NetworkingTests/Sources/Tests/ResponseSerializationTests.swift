//
// Created by Nikita Zatsepilov on 2019-01-26.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking
import Alamofire
import XCTest

final class ResponseSerializationTests: XCTestCase {

    func testJSONResponseSerialization() {
        let invalidJSONData = "{ key: \"value\" }".data(using: .utf8)!
        let validJSONData = "{ \"key\": \"value\" }".data(using: .utf8)!
        let unexpectedJSONData =  "[\"value\"]".data(using: .utf8)!

        let serializer = JSONResponseSerializer(readingOptions: .allowFragments)
        XCTAssertTrue(serializer.serializeResponse(with: nil, request: nil, response: nil, error: nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: Data(), request: nil, response: nil, error: nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: nil, request: nil, response: nil, error: NSError()).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: invalidJSONData, request: nil, response: nil, error: nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: unexpectedJSONData, request: nil, response: nil, error: nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: validJSONData, request: nil, response: nil, error: nil).isSuccess)
    }

    // swiftlint:disable nesting

    func testDecodableResponseSerialization() {
        final class User: Decodable {
            let name: String
            let email: String
        }

        let invalidJSONData = "{ name: \"Test\", email: \"mail@mail.com\" }".data(using: .utf8)!
        let validJSONData = "{ \"name\": \"Test\", \"email\": \"mail@mail.com\" }".data(using: .utf8)!

        let serializer: DecodableResponseSerializer<User> = DecodableResponseSerializer()
        XCTAssertTrue(serializer.serializeResponse(with: nil, request: nil, response: nil, error: nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: Data(), request: nil, response: nil, error: nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: nil, request: nil, response: nil, error: NSError()).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: invalidJSONData, request: nil, response: nil, error: nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(with: validJSONData, request: nil, response: nil, error: nil).isSuccess)
    }

    // swiftlint:enable nesting
}
