//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Networking

protocol HasApiRequestAdaptingService {

    var apiRequestAdaptingService: RequestAdaptingServiceProtocol { get }
}

final class ApiRequestAdaptingService: RequestAdaptingService {

    init(sessionService: SessionServiceProtocol) {
        super.init(requestAdapters: [TokenRequestAdapter(sessionService: sessionService)])
    }
}
