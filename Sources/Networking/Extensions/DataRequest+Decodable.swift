//
// Created by Nikita Zatsepilov on 06/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire



extension DataRequest {

    static func decodableResponseSerializer<Object: Decodable>(with decoder: JSONDecoder) -> DataResponseSerializer<Object> {
        return DataResponseSerializer { (request, response, data, error) -> Result<Object> in
            if let error = error {
                return .failure(error)
            }

            do {
                return .success(try decoder.decode(from: data ?? Data()))
            } catch {
                return .failure(error)
            }
        }
    }
}
