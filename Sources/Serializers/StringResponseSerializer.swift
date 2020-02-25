//
//  Created by Nikita Zatsepilov on 05.02.2020
//  Copyright © 2020 Ronas IT. All rights reserved.
//

import Foundation

public class StringResponseSerializer: ResponseSerializer {

    public typealias Response = StringResponse

    public enum Encoding {
        case automatic
        case custom(String.Encoding)
    }

    private enum Error: LocalizedError {
        case invalidData(Data)

        var errorDescription: String? {
            switch self {
            case .invalidData(let data):
                return "⚠️ Received data with invalid format:\n\(data)"
            }
        }
    }

    private let encoding: Encoding

    public init(encoding: Encoding) {
        self.encoding = encoding
    }

    public func serialize(_ response: DataResponse) throws -> Response {
        let httpResponse = response.httpResponse
        let encoding: String.Encoding
        switch self.encoding {
        case .automatic:
            encoding = response.httpResponse.textEncoding ?? .isoLatin1
        case .custom(let customEncoding):
            encoding = customEncoding
        }

        if let result = String(data: response.result, encoding: encoding) {
            return StringResponse(result: result, httpResponse: httpResponse)
        } else {
            throw Error.invalidData(response.result)
        }
    }
}
