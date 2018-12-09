//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Networking

final class GeneralErrorHandlingService: ErrorHandlingService {

    init() {
        super.init(errorHandlers: [LogErrorHandler()])
    }
}
