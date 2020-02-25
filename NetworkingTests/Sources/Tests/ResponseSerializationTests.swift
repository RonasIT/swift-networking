//
// Created by Nikita Zatsepilov on 2019-01-26.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking
import Alamofire
import XCTest

final class ResponseSerializationTests: XCTestCase {

    func testStringResponseSerialization() {

        @discardableResult
        func serialize(_ data: Data, encoding: String.Encoding) throws -> String {
            let response = DataResponse(result: data, httpResponse: HTTPURLResponse())
            let serializer = StringResponseSerializer(encoding: .custom(encoding))
            return try serializer.serialize(response).result
        }

        XCTAssertEqual(try serialize("📱".data(using: .utf8)!, encoding: .utf8), "📱")
        XCTAssertEqual(try serialize("📱".data(using: .unicode)!, encoding: .unicode), "📱")
    }

    func testJSONResponseSerialization() {
        let invalidResponse = DataResponse(
            result: "{ key: \"value\" }".data(using: .utf8)!,
            httpResponse: HTTPURLResponse()
        )
        let responseWithArray = DataResponse(
            result: "[\"value\"]".data(using: .utf8)!,
            httpResponse: HTTPURLResponse()
        )
        let validResponse = DataResponse(
            result: "{ \"key\": \"value\" }".data(using: .utf8)!,
            httpResponse: HTTPURLResponse()
        )

        let serializer = JSONResponseSerializer(readingOptions: .allowFragments)
        XCTAssertThrowsError(try serializer.serialize(invalidResponse))
        XCTAssertThrowsError(try serializer.serialize(responseWithArray))
        XCTAssertNoThrow(try serializer.serialize(validResponse))
    }

    // swiftlint:disable nesting

    func testDecodableResponseSerialization() {
        final class User: Decodable {
            let name: String
            let email: String
        }

        let invalidJSONData = "{ name: \"Test\", email: \"mail@mail.com\" }".data(using: .utf8)!
        let invalidResponse = DataResponse(result: invalidJSONData, httpResponse: HTTPURLResponse())

        let validJSONData = "{ \"name\": \"Test\", \"email\": \"mail@mail.com\" }".data(using: .utf8)!
        let validResponse = DataResponse(result: validJSONData, httpResponse: HTTPURLResponse())

        let serializer: DecodableResponseSerializer<User> = DecodableResponseSerializer()
        XCTAssertThrowsError(try serializer.serialize(invalidResponse))
        XCTAssertNoThrow(try serializer.serialize(validResponse))
    }

    // swiftlint:enable nesting
}
