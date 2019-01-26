//
// Created by Nikita Zatsepilov on 2019-01-26.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking
import Alamofire
import XCTest

final class ResponseSerializationTests: XCTestCase {

    func testResponseJSONSerialization() {
        let invalidJSON = "{ key: \"value\" }"
        let validJSON = "{ \"key\": \"value\" }"

        let invalidJSONData = invalidJSON.data(using: .utf8)!
        let validJSONData = validJSON.data(using: .utf8)!

        let serializer = DataRequest.jsonResponseSerializer(with: .allowFragments)
        let result = serializer.serializeResponse(nil, nil, nil, nil)
        
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(serializer.serializeResponse(nil, nil, Data(), nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(nil, nil, nil, NSError()).isFailure)
        XCTAssertTrue(serializer.serializeResponse(nil, nil, invalidJSONData, nil).isFailure)
        XCTAssertTrue(serializer.serializeResponse(nil, nil, validJSONData, nil).isSuccess)
    }
}
