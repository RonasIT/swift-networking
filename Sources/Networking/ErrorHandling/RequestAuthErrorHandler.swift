//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public protocol RequestAuthErrorHandlerInput: AnyObject {

    func requestAuthErrorResolved()
    func requestAuthErrorResolvingFailed()
}

public protocol RequestAuthErrorHandlerOutput: AnyObject {

    func requestAuthErrorHandlerDidReceiveError(_ input: RequestAuthErrorHandlerInput)
}

public final class RequestAuthErrorHandler: ErrorHandler {

    public weak var output: RequestAuthErrorHandlerOutput?

    private var isWaitingErrorResolution: Bool = false
    private var items: [AuthorizationErrorHandlerItem] = []

    public init() {}

    public func canHandleError(_ error: Error) -> Bool {
        return (error as? AFError)?.responseCode == 401
    }

    public func handleError(_ error: Error, completion: @escaping (ErrorHandlingResult) -> Void) {
        guard canHandleError(error) else {
            completion(.failure(error))
            return
        }
        items.append(AuthorizationErrorHandlerItem(error: error, completion: completion))
    }
}

// MARK: - RequestAuthErrorHandlerInput

extension RequestAuthErrorHandler: RequestAuthErrorHandlerInput {

    public func requestAuthErrorResolved() {
        items.removeAll { item in
            item.completion(.errorResolved)
            return true
        }
    }

    public func requestAuthErrorResolvingFailed() {
        items.removeAll { item in
            item.completion(.failure(item.error))
            return true
        }
    }
}

private final class AuthorizationErrorHandlerItem {

    let error: Error
    let completion: (ErrorHandlingResult) -> Void

    init(error: Error, completion: @escaping (ErrorHandlingResult) -> Void) {
        self.error = error
        self.completion = completion
    }
}
