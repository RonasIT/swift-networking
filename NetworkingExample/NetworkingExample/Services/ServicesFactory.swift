//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Networking

final class ServicesFactory {

    static let sessionService: SessionServiceProtocol = SessionService()
    static let generalRequestAdaptingService: RequestAdaptingServiceProtocol = GeneralRequestAdaptingService(sessionService: sessionService)
    static let generalErrorHandlingService: ErrorHandlingServiceProtocol = GeneralErrorHandlingService()
    static let apiService: ApiServiceProtocol = ApiService(requestAdaptingService: generalRequestAdaptingService,
                                                           errorHandlingService: generalErrorHandlingService)

}
