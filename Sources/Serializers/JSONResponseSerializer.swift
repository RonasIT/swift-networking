//
// Created by Nikita Zatsepilov on 2019-01-27.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Foundation

final class JSONResponseSerializer: ResponseSerializer {

    typealias Response = JSONResponse

    private enum Error: LocalizedError {
        case invalidJSON(Any)

        var errorDescription: String? {
            switch self {
            case .invalidJSON(let json):
                return "⚠️ Received json with unexpected format:\n\(json)"
            }
        }
    }

    private let readingOptions: JSONSerialization.ReadingOptions

    init(readingOptions: JSONSerialization.ReadingOptions = .allowFragments) {
        self.readingOptions = readingOptions
    }

    func serialize(_ response: DataResponse) throws -> Response {
        let result = try JSONSerialization.jsonObject(with: response.result, options: readingOptions)

        if let result = result as? Response.Result {
            return Response(result: result, httpResponse: response.httpResponse)
        } else {
            throw Error.invalidJSON(result)
        }
    }
}
