//
// Created by Nikita Zatsepilov on 2019-01-27.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

final class DecodableResponseSerializer<Result: Decodable>: ResponseSerializer {

    private let decoder: JSONDecoder

    init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    func serializeResponse(with data: Data?,
                           request: URLRequest?,
                           response: HTTPURLResponse?,
                           error: Error?) -> Alamofire.Result<Result> {
        if let error = error {
            return .failure(error)
        }

        var result: Alamofire.Result<Result>
        do {
            result = .success(try decoder.decode(from: data ?? Data()))
        } catch {
            result = .failure(error)
        }

        return result
    }
}
