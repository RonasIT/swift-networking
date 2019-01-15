//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public typealias ResponseHandlerCompletion<T> = (ResponseHandlingResult<T>) -> Void

public protocol ResponseHandler {

    func canHandleResponse<T>(_ response: GeneralResponse<T>) -> Bool
    func handleResponse<T>(_ response: GeneralResponse<T>, completion: @escaping ResponseHandlerCompletion<T>)
}

extension ResponseHandler {

    func handleResponse<T>(_ response: GeneralResponse<T>, callback: RequestCallback<T>) {
        handleResponse(response) { result in
            switch result {
            case .failure(let error):
                callback.failure(error)
            case .success(let result):
                callback.success(result)
            }
        }
    }
}
