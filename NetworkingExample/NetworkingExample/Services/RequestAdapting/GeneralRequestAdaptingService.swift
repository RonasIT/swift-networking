//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Networking

protocol HasGeneralRequestAdaptingService {

    var generalRequestAdaptingService: RequestAdaptingServiceProtocol { get }
}

final class GeneralRequestAdaptingService: RequestAdaptingService {

    init(sessionService: SessionServiceProtocol) {
        super.init(requestAdapters: [TokenRequestAdapter(sessionService: sessionService)])
    }
}
