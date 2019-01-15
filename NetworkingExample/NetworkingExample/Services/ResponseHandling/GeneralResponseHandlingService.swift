//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Networking

protocol HasGeneralResponseHandlingService {

    var generalResponseHandlingService: ResponseHandlingServiceProtocol { get }
}

final class GeneralResponseHandlingService: ResponseHandlingService {

    private let sessionService: SessionServiceProtocol

    init(sessionService: SessionServiceProtocol) {
        self.sessionService = sessionService
        let authErrorHandler = AuthorizationErrorResponseHandler()
        super.init(responseHandlers: [authErrorHandler])
        authErrorHandler.output = self
    }
}

// MARK: - AuthorizationErrorHandlerOutput

extension GeneralResponseHandlingService: AuthorizationErrorHandlerOutput {

    public func authorizationErrorHandlerDidReceiveError(_ input: AuthorizationErrorHandlerInput) {
        sessionService.refreshToken { succeed in
            input.authorizationErrorResolvingFailed()
        }
    }
}
