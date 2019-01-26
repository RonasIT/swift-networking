//
// Created by Nikita Zatsepilov on 2019-01-26.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking
import Alamofire
import XCTest

final class MultipartFormDataTests: XCTestCase {

    func testImageBodyPartAppending() {
        let base64Encoded = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
        let imageData = Data(base64Encoded: base64Encoded)!
        let imageBodyPart = ImageBodyPart(imageData: imageData, name: "image", fileName: "image.jpg", mimeType: "jpg")
        let multipartFormData = MultipartFormData()
        multipartFormData.appendImageBodyParts([imageBodyPart])
        multipartFormData.appendParametersBodyParts(["parameter": "value"])
        XCTAssertNoThrow(try multipartFormData.encode())
    }
}
