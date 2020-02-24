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

    func testURLResponseTextEncodings() {
        let encodings: [String: String.Encoding] = [
            "utf8": .utf8,
            "utf-16le": .utf16LittleEndian,
            "ascii": .ascii,
            "iso-8859-1": .isoLatin1
        ]

        encodings.forEach { encoding in
            let response = urlResponse(withTextEncodingName: encoding.key)
            XCTAssertNotNil(response.textEncoding)
            XCTAssertEqual(encoding.value, response.textEncoding)
        }

        let responseWithoutEncodig = urlResponse(withTextEncodingName: nil)
        XCTAssertNil(responseWithoutEncodig.textEncoding)
    }

    // MARK: - Private

    private func urlResponse(withTextEncodingName textEncodingName: String?) -> URLResponse {
        return URLResponse(
            url: URL(string: "https://apple.com")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: textEncodingName
        )
    }
}
