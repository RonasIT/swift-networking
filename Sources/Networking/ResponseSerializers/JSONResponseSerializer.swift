//
// Created by Nikita Zatsepilov on 2019-01-27.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

final class JSONResponseSerializer: ResponseSerializer {

    typealias Result = [String: Any]

    private let readingOptions: JSONSerialization.ReadingOptions

    init(readingOptions: JSONSerialization.ReadingOptions = .allowFragments) {
        self.readingOptions = readingOptions
    }

    func serializeResponse(with data: Data?,
                           request: URLRequest?,
                           response: HTTPURLResponse?,
                           error: Error?) -> Alamofire.Result<[String: Any]> {
        if let error = error {
            return .failure(error)
        }

        do {
            let object = try JSONSerialization.jsonObject(with: data ?? Data(), options: readingOptions)
            guard let json = object as? [String: Any] else {
                return .failure(CocoaError.error(.keyValueValidation))
            }
            return .success(json)
        } catch {
            return .failure(error)
        }
    }
}
