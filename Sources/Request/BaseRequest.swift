//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public protocol ResponseValidator {
    func validate(response: Any) -> Error?
}

public protocol ErrorHandler {
    func handle<T>(error: inout Error, for response: DataResponse<T>?, endpoint: Endpoint) -> Bool
}

public class BaseRequest<ResponseType> {
    typealias CompletionHandler<T> = (T?, Error?) -> Void

    var responseValidators: [ResponseValidator] = []
    var errorHandlers: [ErrorHandler] = []
    let responseBuilder: AnyResponseBuilder<ResponseType>
    let endpoint: Endpoint

    var completionHandler: CompletionHandler<ResponseType>?

    init<U: ResponseBuilder>(endpoint: Endpoint,
                             responseBuilder: U,
                             sessionManager: SessionManager = SessionManager.default) where U.Response == ResponseType {
        self.responseBuilder = AnyResponseBuilder(responseBuilder)
        if case AuthorizedEndpoint.endpoint(let source, _) = endpoint {
            self.endpoint = source
        }
        else {
            self.endpoint = endpoint
        }
    }

    func handleResponseData(_ responseData: Any) {
        for validator in responseValidators {
            if let error = validator.validate(response: responseData) {
                // swiftlint:disable:next syntactic_sugar
                handleError(error, forResponse: Optional<DataResponse<Any>>(nilLiteral: ()))
                return
            }
        }
        let response = responseBuilder.buildResponse(from: responseData)
        if let completionHandler = completionHandler {
            completionHandler(response, nil)
        }
    }

    func handleError<T>(_ error: Error, forResponse response: DataResponse<T>?) {
        var error = error
        for handler in errorHandlers {
            if handler.handle(error: &error, for: response, endpoint: endpoint) {
                return
            }
        }
        if let completionHandler = completionHandler {
            completionHandler(nil, error)
        }
    }
}
