//
// Created by Nikita Zatsepilov on 06/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

extension DataRequest {

    static func decodableResponseSerializer<Object: Decodable>(with decoder: JSONDecoder) -> DataResponseSerializer<Object> {
        return DataResponseSerializer { (request, response, data, error) -> Result<Object> in
            if let error = error {
                return .failure(error)
            }

            guard let data = data else {
                let error = AFError.responseSerializationFailed(reason: .inputDataNil)
                return .failure(error)
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
