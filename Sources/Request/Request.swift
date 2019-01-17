//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

final class Request<Result>: BaseRequest<Result> {

    private var request: DataRequest?
    private var completion: Completion?

    override func response(completion: @escaping Completion) {
        self.completion = completion
        let request = sessionManager.request(endpoint.url,
                                             method: endpoint.method,
                                             parameters: endpoint.parameters,
                                             encoding: endpoint.parameterEncoding,
                                             headers: headers.httpHeaders).validate()
        request.response(responseSerializer: responseSerializer, completionHandler: completion)
    }

    override func cancel() {
        request?.cancel()
        request = nil
        completion = nil
    }

    override func retry() {
        if let completion = completion {
            response(completion: completion)
        }
    }
}
