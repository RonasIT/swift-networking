//
// Created by Nikita Zatsepilov on 2019-01-27.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

protocol ResponseSerializer {

    associatedtype Result

    func serializeResponse(with data: Data?,
                           request: URLRequest?,
                           response: HTTPURLResponse?,
                           error: Error?) -> Alamofire.Result<Result>
}

extension ResponseSerializer {

    func asDataResponseSerializer() -> DataResponseSerializer<Result> {
        return DataResponseSerializer { request, response, data, error in
            self.serializeResponse(with: data, request: request, response: response, error: error)
        }
    }
}
