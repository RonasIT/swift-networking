//
// Created by Nikita Zatsepilov on 2019-01-26.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public typealias CancellableRequest = BasicRequest & Cancellable
public typealias AdaptiveRequest = BasicRequest & MutableRequest
typealias RetryableRequest = AdaptiveRequest & Retryable

public protocol BasicRequest: AnyObject {

    var endpoint: Endpoint { get }
}

public protocol MutableRequest {

    var headers: [RequestHeader] { get }

    func appendHeader(_ header: RequestHeader)
}

public protocol Cancellable {

    @discardableResult
    func cancel() -> Bool
}

protocol Retryable {

    @discardableResult
    func retry() -> Bool
}
