//
//  Created by Nikita Zatsepilov on 06.11.2019
//  Copyright © 2019 Ronas IT. All rights reserved.
//

import Alamofire

final class DetailedResponseSerializer<Serializer: ResponseSerializer>: ResponseSerializer {

    typealias Result = DetailedResponse<Serializer.Result>

    private let serializer: Serializer

    init(serializer: Serializer) {
        self.serializer = serializer
    }

    func serializeResponse(with data: Data?,
                           request: URLRequest?,
                           response: HTTPURLResponse?,
                           error: Error?) -> Alamofire.Result<Result> {
        guard let response = response else {
            let responseError = error ?? AFError.responseValidationFailed(reason: .dataFileNil)
            return .failure(responseError)
        }

        let result = serializer.serializeResponse(
            with: data,
            request: request,
            response: response,
            error: error
        )

        switch result {
        case .failure(let error):
            return .failure(error)
        case .success(let result):
            let response = DetailedResponse(
                statusCode: response.statusCode,
                headers: response.allHeaderFields,
                result: result
            )
            return .success(response)
        }
    }
}
