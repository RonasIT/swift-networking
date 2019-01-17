//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking

final class ApiErrorHandlingService: ErrorHandlingService {

    init(sessionService: SessionServiceProtocol) {
        let errorHandlers: [ErrorHandler] = [
            UnauthorizedErrorHandler(sessionService: sessionService),
            NotFoundErrorHandler()
        ]
        super.init(errorHandlers: errorHandlers)
    }
}
