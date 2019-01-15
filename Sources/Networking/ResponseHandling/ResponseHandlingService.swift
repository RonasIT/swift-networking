//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public protocol ResponseHandlingServiceProtocol {
}

extension ResponseHandlingServiceProtocol {

    func handleResponse<T>(_ response: GeneralResponse<T>, callback: RequestCallback<T>) {}
}

open class ResponseHandlingService: ResponseHandlingServiceProtocol {

    let responseHandlers: [ResponseHandler]

    public init(responseHandlers: [ResponseHandler]) {
        self.responseHandlers = responseHandlers
    }

    func handleResponse<T>(_ response: GeneralResponse<T>, callback: RequestCallback<T>) {
        let handlerOrNil = responseHandlers.first { $0.canHandleResponse(response) }
        if let handler = handlerOrNil {
            handler.handleResponse(response, callback: callback)
        } else {
            switch response.dataResponse.result {
            case .failure(let error):
                callback.failure(error)
            case .success(let result):
                callback.success(result)
            }
        }
    }
}
