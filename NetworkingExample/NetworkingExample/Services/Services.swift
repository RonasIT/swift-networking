//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Networking

typealias HasServices = HasApiService &
                        HasSessionService &
                        HasReachabilityService

var Services: HasServices = MainServices() // swiftlint:disable:this variable_name

final class MainServices: HasServices {

    lazy var sessionService: SessionServiceProtocol = {
        return SessionService()
    }()

    lazy var apiService: ApiServiceProtocol = {
        return ApiService(requestAdaptingService: apiRequestAdaptingService,
                          errorHandlingService: apiErrorHandlingService)
    }()

    lazy var reachabilityService: ReachabilityServiceProtocol = {
        let reachabilityService = ReachabilityService()
        reachabilityService.startMonitoring()
        return reachabilityService
    }()

    // MARK: - Private

    private lazy var apiRequestAdaptingService: RequestAdaptingServiceProtocol = {
        let requestAdapters: [RequestAdapter] = [
            AppRequestAdapter(),
            TokenRequestAdapter(sessionService: sessionService)
        ]
        return RequestAdaptingService(requestAdapters: requestAdapters)
    }()

    private lazy var apiErrorHandlingService: ErrorHandlingServiceProtocol = {
        let errorHandlers: [ErrorHandler] = [LoggingErrorHandler(), GeneralErrorHandler()]
        return ErrorHandlingService(errorHandlers: errorHandlers)
    }()
}
