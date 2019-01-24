//
// Created by Nikita Zatsepilov on 07/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

extension DataRequest {

    typealias JSONReadingOptions = JSONSerialization.ReadingOptions

    static func jsonResponseSerializer(with readingOptions: JSONReadingOptions) -> DataResponseSerializer<[String: Any]> {
        return DataResponseSerializer { (request, response, data, error) -> Result<[String: Any]> in
            if let error = error {
                return .failure(error)
            }

            do {
                let object = try JSONSerialization.jsonObject(with: data ?? Data(), options: readingOptions)
                guard let json = object as? [String: Any] else {
                    var error = CocoaError.error(.keyValueValidation)
                    error = AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: error))
                    return .failure(error)
                }
                return .success(json)
            } catch {
                return .failure(error)
            }
        }
    }
}
