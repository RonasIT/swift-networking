//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public protocol AuthorizationErrorHandlerInput: AnyObject {

    func authorizationErrorResolved()
    func authorizationErrorResolvingFailed()
}

public protocol AuthorizationErrorHandlerOutput: AnyObject {

    func authorizationErrorHandlerDidReceiveError(_ input: AuthorizationErrorHandlerInput)
}

public final class AuthorizationErrorResponseHandler: ResponseHandler {

    public weak var output: AuthorizationErrorHandlerOutput?

    private var failedRequests: [RetryableRequest] = []
    private var failureHandlers: [() -> Void] = []

    public init() {}

    public func canHandleResponse<T>(_ response: GeneralResponse<T>) -> Bool {
        guard let responseCode = (response.dataResponse.error as? AFError)?.responseCode,
              responseCode == 401 else {
            return false
        }
        return true
    }

    public func handleResponse<T>(_ response: GeneralResponse<T>, completion: @escaping ResponseHandlerCompletion<T>) {
        guard let error = response.dataResponse.error else {
            return
        }

        failedRequests.append(response.request)
        failureHandlers.append {
            completion(.failure(error))
        }
        output?.authorizationErrorHandlerDidReceiveError(self)
    }
}

// MARK: - AuthorizationErrorHandlerInput

extension AuthorizationErrorResponseHandler: AuthorizationErrorHandlerInput {

    public func authorizationErrorResolved() {
        failureHandlers.removeAll()
        failedRequests.forEach { $0.retry() }
        failedRequests.removeAll()
    }

    public func authorizationErrorResolvingFailed() {
        failureHandlers.forEach { handler in
            handler()
        }
        failedRequests.removeAll()
        failureHandlers.removeAll()
    }
}
