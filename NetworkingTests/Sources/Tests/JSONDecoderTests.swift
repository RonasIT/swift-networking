//
// Created by Nikita Zatsepilov on 2019-01-27.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking
import XCTest

final class JSONDecoderTests: XCTestCase {

    // swiftlint:disable nesting

    func testDecodingWithCustomError() {
        final class User: Decodable {
            let firstName: String
            let lastName: String
        }

        let validFixture = "{ \"firstName\": \"John\", \"lastName\": \"Doe\" }".data(using: .utf8)!
        let invalidFixtures = [
            Data([UInt8(1)]),
            Data(),
            "{ \"firstName\": \"John\" }".data(using: .utf8)!,
            "{ \"firstName\": \"John\" }".data(using: .ascii)!
        ]

        func decodeUser(from data: Data) throws {
            let decoder = JSONDecoder()
            _ = (try decoder.decode(from: data) as User)
        }

        XCTAssertNoThrow(try decodeUser(from: validFixture))
        try? invalidFixtures.forEach { fixture in
            XCTAssertThrowsError(try decodeUser(from: fixture))
        }
    }

    // swiftlint:enable nesting
}
