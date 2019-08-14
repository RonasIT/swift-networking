//
// Created by Nikita Zatsepilov on 2019-01-23.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire
import Networking

struct MockEndpoint: UploadEndpoint {

    enum Result {
        case failure(Error)
        case success(Data)
    }

    let result: Result

    var baseURL: URL = URL(string: "localhost")!
    var path: String = "mock"
    var method: HTTPMethod = .get
    var headers: [RequestHeader] = []
    var parameters: Parameters? = nil
    var parameterEncoding: ParameterEncoding = URLEncoding.default
    var requiresAuthorization: Bool = false
    var imageBodyParts: [ImageBodyPart] = []

    var errorForResponseCode: Error?
    var errorForURLErrorCode: Error?

    var expectedHeaders: [RequestHeader] = []
    var expectedAccessToken: String?

    var responseDelay: Double = .random(in: 0.5...1)

    init(result: String, encoding: String.Encoding = .utf8) {
        self.result = .success(result.data(using: encoding)!)
    }

    init(result: Data = Data()) {
        self.result = .success(result)
    }

    init(result: [String: Any], options: JSONSerialization.WritingOptions = .prettyPrinted) {
        self.result = .success(try! JSONSerialization.data(withJSONObject: result, options: options))
    }

    init<T>(result: T, encoder: JSONEncoder = JSONEncoder()) where T: Codable {
        self.result = .success(try! encoder.encode(result))
    }

    init(result: Error) {
        self.result = .failure(result)
    }

    func error(for urlErrorCode: URLError.Code) -> Error? {
        return errorForURLErrorCode
    }

    func error(forResponseCode responseCode: Int) -> Error? {
        return errorForResponseCode
    }
}
