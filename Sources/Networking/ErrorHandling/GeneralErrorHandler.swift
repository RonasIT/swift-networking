//
// Created by Nikita Zatsepilov on 2019-01-22.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

open class GeneralErrorHandler: ErrorHandler {

    public init() {}

    public func handleError<T>(_ error: RequestError<T>, completion: @escaping Completion) {
        let endpoint = error.endpoint
        switch error.error {
        case let error as AFError:
            handleAFError(error, endpoint: endpoint, completion: completion)
        case let error as NSError where error.domain == NSURLErrorDomain:
            let code = URLError.Code(rawValue: error.code)
            handleError(with: code, endpoint: endpoint, completion: completion)
        default:
            completion(.continueErrorHandling(with: error.error))
        }
    }

    // MARK: - Private

    private func handleAFError(_ error: AFError, endpoint: Endpoint, completion: @escaping Completion) {
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

    private func handleError(with urlErrorCode: URLError.Code, endpoint: Endpoint, completion: @escaping Completion) {
        if let error = endpoint.error(for: urlErrorCode) {
            completion(.continueErrorHandling(with: error))
            return
        }

        var mappedError: Error
        switch urlErrorCode {
        case URLError.notConnectedToInternet:
            mappedError = GeneralRequestError.noInternetConnection
        case URLError.timedOut:
            mappedError = GeneralRequestError.timedOut
        case URLError.cancelled:
            mappedError = GeneralRequestError.cancelled
        default:
            mappedError = NSError(domain: NSURLErrorDomain, code: urlErrorCode.rawValue)
        }
        completion(.continueErrorHandling(with: mappedError))
    }
}
