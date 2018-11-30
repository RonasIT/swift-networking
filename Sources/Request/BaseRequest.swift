//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public protocol ErrorHandler {
    func handle<T>(error: inout Error, for response: DataResponse<T>?, endpoint: Endpoint) -> Bool
}

public class BaseRequest {
    public typealias SuccessHandler<T> = (T) -> Void
    public typealias FailureHandler = (Error) -> Void

    // FIXME: add validators

    var errorHandlers: [ErrorHandler] = []
    let endpoint: Endpoint

    init(endpoint: Endpoint, sessionManager: SessionManager = SessionManager.default) {
        if case AuthorizedEndpoint.endpoint(let source, _) = endpoint {
            self.endpoint = source
        } else {
            self.endpoint = endpoint
        }
    }

    func handleError<T>(_ error: Error,
                        forResponse response: DataResponse<T>?,
                        failureHandler: FailureHandler) {
        var error = error
        for handler in errorHandlers {
            if handler.handle(error: &error, for: response, endpoint: endpoint) {
                return
            }
        }
        failureHandler(error)
    }

    func handleResponseData(_ data: Data,
                            successHandler: SuccessHandler<Data>,
                            failureHandler: FailureHandler) {
        // FIXME: use validators
        successHandler(data)
    }

    func handleResponseString(_ string: String,
                              successHandler: SuccessHandler<String>,
                              failureHandler: FailureHandler) {
        // FIXME: use validators
        successHandler(string)
    }

    func handleResponseJSON(_ json: Any,
                            successHandler: SuccessHandler<Any>,
                            failureHandler: FailureHandler) {
        // FIXME: use validators
        successHandler(json)
    }

    func handleResponseDecodableObject<Result: Decodable>(with data: Data,
                                                          decoder: JSONDecoder = JSONDecoder(),
                                                          successHandler: SuccessHandler<Result>,
                                                          failureHandler: FailureHandler) {
        // FIXME: use validators
        do {
            successHandler(try decoder.decode(from: data))
        } catch {
            failureHandler(error)
        }
    }
}
