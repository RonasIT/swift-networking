//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire
import UIKit

protocol AppErrorsHandlerOutput: class {
    func noAuthErrorOccurred(_ error: Error)
}

final class AppErrorsHandler: GeneralErrorHandler {

    weak var output: AppErrorsHandlerOutput?

    override func handle<T>(error: inout Error, for response: Alamofire.DataResponse<T>?, endpoint: Endpoint) -> Bool {
        if !handle(&error, byCode: (error as NSError).code) {
            if let responseData = response?.data, !responseData.isEmpty {
                do {
                    let errorResponse: AppErrorResponse = try JSONDecoder().decode(from: responseData)
                    return handle(error: &error, for: errorResponse, endpoint: endpoint)
                }
                catch {
                    print(error.localizedDescription)
                }
            }
        }
        else if error as? GeneralRequestError == .noAuth {
            output?.noAuthErrorOccurred(error)
            return true
        }

        return false
    }

    private func handle(error: inout Error, for response: AppErrorResponse, endpoint: Endpoint) -> Bool {
        if let endpointError = endpoint.error(for: response.error.code, description: response.error.description) {
            error = endpointError
        }
        else {
            error = AppError.unknown(description: response.error.description)
        }
        return false
    }
}

enum AppError: Error {
    case unknown(description: String)
}

//extension AppError: LocalizedError {
//
//    var errorDescription: String? {
//        switch self {
//        case let .unknown(description):
//            return description
//        }
//    }
//}

// MARK: - PaymentsErrorResponse

private final class AppErrorResponse: Codable {
    let error: ServerError
}
