//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Networking

protocol HasApiErrorHandlingService {

    var apiErrorHandlingService: ErrorHandlingServiceProtocol { get }
}

final class ApiErrorHandlingService: ErrorHandlingService {

    private let sessionService: SessionServiceProtocol

    init(sessionService: SessionServiceProtocol) {
        self.sessionService = sessionService
        let requestAuthErrorHandler = RequestAuthErrorHandler()
        super.init(errorHandlers: [requestAuthErrorHandler])
        requestAuthErrorHandler.output = self
    }
}

// MARK: - RequestAuthErrorHandlerOutput

extension ApiErrorHandlingService: RequestAuthErrorHandlerOutput {

    public func requestAuthErrorHandlerDidReceiveError(_ input: RequestAuthErrorHandlerInput) {
        sessionService.refreshToken { succeed in
            if succeed {
                input.requestAuthErrorResolved()
            } else {
                input.requestAuthErrorResolvingFailed()
            }
        }
    }
}
