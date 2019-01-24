//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Networking

typealias HasServices = HasApiService &
                        HasSessionService

var Services: HasServices = MainServices() // swiftlint:disable:this variable_name

final class MainServices: HasServices {

    lazy var sessionService: SessionServiceProtocol = {
        return SessionService()
    }()

    lazy var apiRequestAdaptingService: RequestAdaptingServiceProtocol = {
        let requestAdapters: [RequestAdapter] = [
            AppRequestAdapter(),
            TokenRequestAdapter(sessionService: sessionService)
        ]
        return RequestAdaptingService(requestAdapters: requestAdapters)
    }()

    lazy var apiErrorHandlingService: ErrorHandlingServiceProtocol = {
        let errorHandlers: [ErrorHandler] = [LoggingErrorHandler(), GeneralErrorHandler()]
        return ErrorHandlingService(errorHandlers: errorHandlers)
    }()

    lazy var apiService: ApiServiceProtocol = {
        return ApiService(requestAdaptingService: apiRequestAdaptingService,
                          errorHandlingService: apiErrorHandlingService)
    }()
}
