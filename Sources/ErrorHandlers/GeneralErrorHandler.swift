//
// Created by Nikita Zatsepilov on 2019-01-22.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

open class GeneralErrorHandler: ErrorHandler {

    public init() {}

    open func handleError(_ error: RequestError, completion: @escaping Completion) {
        completion(.continueErrorHandling(with: map(error)))
    }

    // MARK: -  Private

    private func map(_ requestError: RequestError) -> Error {
        let endpoint = requestError.endpoint
        let error = requestError.error

        if let statusCode = requestError.statusCode {
            return map(error, statusCode: statusCode, endpoint: endpoint)
        }

        switch error {
        case let error as URLError:
            return map(error, endpoint: endpoint)
        default:
            return error
        }
    }

    private func map(_ error: Error, statusCode: StatusCode, endpoint: Endpoint) -> Error {
        if let error = endpoint.error(for: statusCode) {
            return error
        }

        switch statusCode {
        case .unauthorised401:
            return GeneralRequestError.noAuth
        case .forbidden403:
            return GeneralRequestError.forbidden
        case .notFound404:
            return GeneralRequestError.notFound
        default:
            return error
        }
    }

    private func map(_ error: URLError, endpoint: Endpoint) -> Error {
        if let error = endpoint.error(for: error.code) {
            return error
        }

        switch error.code {
        case .notConnectedToInternet:
            return GeneralRequestError.noInternetConnection
        case .timedOut:
            return GeneralRequestError.timedOut
        case .cancelled:
            return GeneralRequestError.cancelled
        default:
            return error
        }
    }
}
