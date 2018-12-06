//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire
import Foundation

open class GeneralErrorHandler: ErrorHandler {

    public init() {

    }

    public func handle<T>(error: inout Error, for response: DataResponse<T>?, endpoint: Endpoint) -> Bool {
        handle(&error, byCode: (error as NSError).code)
        return false
    }

    @discardableResult
    func handle(_ error: inout Error, byCode code: Int) -> Bool {
        if let afError = error as? Alamofire.AFError,
            let code = afError.responseCode {
            switch code {
            case 401:
                error = GeneralRequestError.noAuth
                return true
            case 404:
                error = GeneralRequestError.notFound
                return true
            default:
                return false
            }
        }
        else {
            switch code {
            case NSURLErrorNotConnectedToInternet:
                error = GeneralRequestError.noInternetConnection
                return true
            case NSURLErrorTimedOut:
                error = GeneralRequestError.timedOut
                return true
            case NSURLErrorCancelled:
                error = GeneralRequestError.cancelled
                return true
            default:
                return false
            }
        }
    }
}
