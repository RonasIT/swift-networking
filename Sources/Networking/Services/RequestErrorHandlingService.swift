//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

open class RequestErrorHandlingService: ErrorHandlingService {

    private let sessionService: SessionServiceProtocol

    public init(sessionService: SessionServiceProtocol) {
        self.sessionService = sessionService
        let unauthorizedErrorHandler = UnauthorizedErrorHandler()
        super.init(errorHandlers: [unauthorizedErrorHandler])
        unauthorizedErrorHandler.output = self
    }
}

// MARK: - UnauthorizedErrorHandlerOutput

extension RequestErrorHandlingService: UnauthorizedErrorHandlerOutput {

    func unauthorizedErrorHandlerDidReceiveError(_ input: UnauthorizedErrorHandlerInput) {
        sessionService.refreshAuthToken(success: { [weak input] in
            input?.unauthorizedErrorResolved()
        }, failure: { [weak input] error in
            input?.unauthorizedErrorResolvingFailed(with: error)
        })
    }
}
