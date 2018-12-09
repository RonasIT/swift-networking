//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

public protocol AdaptiveRequest {

    func add(_ header: RequestHeader)
}

extension AdaptiveRequest where Self: NetworkRequest {

    func add(_ header: RequestHeader) {
        let headerIndexOrNil = headers.firstIndex { $0.key == header.key }
        if let headerIndex = headerIndexOrNil {
            headers[headerIndex] = header
            return
        }

        headers.append(header)
    }
}
