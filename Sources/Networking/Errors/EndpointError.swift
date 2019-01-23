//
// Created by Nikita Zatsepilov on 2019-01-23.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Foundation

public protocol EndpointError {

    func error(forResponseCode responseCode: Int) -> Error?
    func error(for urlError: URLError) -> Error?
}
