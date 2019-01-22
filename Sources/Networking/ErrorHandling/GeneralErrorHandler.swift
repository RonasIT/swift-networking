//
// Created by Nikita Zatsepilov on 2019-01-22.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Foundation

open class GeneralErrorHandler: ErrorHandler {

    public init() {}

    public func canHandleError<T>(_ error: RequestError<T>) -> Bool {
        guard let statusCode = error.response.response?.statusCode else {
            return canHandleError(withCode: (error.underlyingError as NSError).code)
        }
        return canHandleError(withStatusCode: statusCode)
    }

    public func handleError<T>(_ error: RequestError<T>, completion: @escaping Completion) {
        if let statusCode = error.response.response?.statusCode {
            handleError(error, statusCode: statusCode, completion: completion)
        } else {
            let urlErrorCode = (error.underlyingError as NSError).code
            handleError(error, urlErrorCode: urlErrorCode, completion: completion)
        }
    }

    // MARK: - Private

    private func canHandleError(withStatusCode statusCode: Int) -> Bool {
        switch statusCode {
        case 401, 404:
            return true
        default:
            return false
        }
    }

    private func canHandleError(withCode urlErrorCode: Int) -> Bool {
        switch urlErrorCode {
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorTimedOut,
             NSURLErrorCancelled:
            return true
        default:
            return false
        }
    }

    private func handleError<T>(_ requestError: RequestError<T>, statusCode: Int, completion: @escaping Completion) {
        var error: Error
        switch statusCode {
        case 401:
            error = GeneralRequestError.noAuth
        case 404:
            error = GeneralRequestError.notFound
        default:
            error = requestError.underlyingError
        }
        completion(.continueErrorHandling(with: error))
    }

    private func handleError<T>(_ requestError: RequestError<T>, urlErrorCode: Int, completion: @escaping Completion) {
        var error: Error
        switch urlErrorCode {
        case NSURLErrorNotConnectedToInternet:
            error = GeneralRequestError.noInternetConnection
        case NSURLErrorTimedOut:
            error = GeneralRequestError.timedOut
        case NSURLErrorCancelled:
            error = GeneralRequestError.cancelled
        default:
            error = requestError.underlyingError
        }
        completion(.continueErrorHandling(with: error))
    }
}
