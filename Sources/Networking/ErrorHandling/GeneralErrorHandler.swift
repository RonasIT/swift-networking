//
// Created by Nikita Zatsepilov on 2019-01-22.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

open class GeneralErrorHandler: ErrorHandler {

    public init() {}

    public func handleError<T>(_ error: RequestError<T>, completion: @escaping Completion) {
        let endpoint = error.endpoint
        switch error.underlyingError {
        case let error as AFError:
            handleError(error, endpoint: endpoint, completion: completion)
        case let error as URLError:
            handleError(error, endpoint: endpoint, completion: completion)
        default:
            completion(.continueErrorHandling(with: error.underlyingError))
        }
    }

    // MARK: - Private

    private func handleError(_ error: AFError, endpoint: Endpoint, completion: @escaping Completion) {
        guard let responseCode = error.responseCode else {
            completion(.continueErrorHandling(with: error))
            return
        }

        if let endpointError = endpoint.error(forResponseCode: responseCode) {
            completion(.continueErrorHandling(with: endpointError))
            return
        }

        var mappedError: Error
        switch responseCode {
        case 401:
            mappedError = GeneralRequestError.noAuth
        case 404:
            mappedError = GeneralRequestError.notFound
        default:
            mappedError = error
        }
        completion(.continueErrorHandling(with: mappedError))
    }

    private func handleError(_ error: URLError, endpoint: Endpoint, completion: @escaping Completion) {
        if let endpointError = endpoint.error(for: error) {
            completion(.continueErrorHandling(with: endpointError))
            return
        }

        var mappedError: Error
        switch error {
        case URLError.notConnectedToInternet:
            mappedError = GeneralRequestError.noInternetConnection
        case URLError.timedOut:
            mappedError = GeneralRequestError.timedOut
        case URLError.cancelled:
            mappedError = GeneralRequestError.cancelled
        default:
            mappedError = error
        }
        completion(.continueErrorHandling(with: mappedError))
    }
}
