//
// Created by Nikita Zatsepilov on 06/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

extension DataRequest {

    static func decodableResponseSerializer<Object: Decodable>(with decoder: JSONDecoder)
                    -> DataResponseSerializer<Object> {
        return DataResponseSerializer { (request, response, data, error) -> Result<Object> in
            guard let data = data else {
                if let error = error {
                    return .failure(error)
                }

                let code = NSURLErrorCannotParseResponse
                let defaultError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: code))
                return .failure(defaultError)
            }

            do {
                return .success(try decoder.decode(from: data))
            }
            catch {
                return .failure(error)
            }
        }
    }

    @discardableResult
    func responseObject<Object: Decodable>(queue: DispatchQueue? = nil,
                                           decoder: JSONDecoder = JSONDecoder(),
                                           completionHandler: @escaping (DataResponse<Object>) -> Void) -> Self {
        let responseSerializer: DataResponseSerializer<Object> = DataRequest.decodableResponseSerializer(with: decoder)
        return response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}
