//
// Created by Nikita Zatsepilov on 2019-01-27.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

final class DecodableResponseSerializer<Result: Decodable>: ResponseSerializer {

    typealias Response = DecodableResponse<Result>

    private let decoder: JSONDecoder

    init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    func serialize(_ response: DataResponse) throws -> Response {
        let result: Response.Result = try decoder.decode(from: response.result)
        return Response(result: result, httpResponse: response.httpResponse)
    }
}
