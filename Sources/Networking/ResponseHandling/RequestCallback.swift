//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public final class RequestCallback<T> {

    let success: Success<T>
    let failure: Failure

    init(success: @escaping Success<T>, failure: @escaping Failure) {
        self.success = success
        self.failure = failure
    }
}
