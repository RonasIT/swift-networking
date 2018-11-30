//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation

// FIXME: rewrite
//final class GeneralResponseValidator: ResponseValidator {
//    enum Error: LocalizedError {
//        case wrongResponse
//        case unknown(description: String)
//
//        var errorDescription: String? {
//            switch self {
//            case .wrongResponse:
//                return "Wrong response format"
//
//            case .unknown(let description):
//                return description
//            }
//        }
//    }
//
//    func validate(response: Any) -> Swift.Error? {
//        guard let json = response as? [String: Any], let result = json["result"] as? Bool else {
//            return Error.wrongResponse
//        }
//
//        if result {
//            return nil
//        }
//
//        if let errorTitle = json["error"] as? String, let error = error(fromString: errorTitle) {
//            return error
//        }
//
//        if let errorDescription = json["message"] as? String {
//            return Error.unknown(description: errorDescription)
//        }
//
//        return Error.unknown(description: "An unknown server error occurred.")
//    }
//
//    func error(fromString string: String) -> Error? {
//        switch string {
//        // Convert errors here
//        default:
//            return nil
//        }
//    }
//}
