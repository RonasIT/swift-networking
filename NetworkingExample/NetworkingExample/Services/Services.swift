//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Networking

typealias HasServices = HasApiService &
                        HasSessionService &
                        HasGeneralRequestAdaptingService &
                        HasGeneralResponseHandlingService

var Services: MainServices = MainServices() // swiftlint:disable:this variable_name

final class MainServices: HasServices {

    lazy var sessionService: SessionServiceProtocol = {
        return SessionService()
    }()

    lazy var generalRequestAdaptingService: RequestAdaptingServiceProtocol = {
        return GeneralRequestAdaptingService(sessionService: sessionService)
    }()

    lazy var generalResponseHandlingService: ResponseHandlingServiceProtocol = {
        return GeneralResponseHandlingService(sessionService: sessionService)
    }()

    lazy var apiService: ApiServiceProtocol = {
        return ApiService(requestAdaptingService: generalRequestAdaptingService,
                          responseHandlingService: generalResponseHandlingService)
    }()
}
