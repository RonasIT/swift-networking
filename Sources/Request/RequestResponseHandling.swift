//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation

protocol RequestResponseHandling {

    typealias SuccessHandler<T> = (T) -> Void
    typealias FailureHandler = (Error) -> Void

    func handleResponseData(_ data: Data,
                            success: SuccessHandler<Data>,
                            failure: FailureHandler)

    func handleResponseString(_ string: String,
                              success: SuccessHandler<String>,
                              failure: FailureHandler)

    func handleResponseJSON(_ json: Any,
                            success: SuccessHandler<Any>,
                            failure: FailureHandler)

    func handleResponseDecodableObject<Result: Decodable>(with data: Data,
                                                          decoder: JSONDecoder,
                                                          success: SuccessHandler<Result>,
                                                          failure: FailureHandler)
}

extension RequestResponseHandling {

    func handleResponseData(_ data: Data,
                            success: SuccessHandler<Data>,
                            failure: FailureHandler) {
        // FIXME: use validators
        success(data)
    }

    func handleResponseString(_ string: String,
                              success: SuccessHandler<String>,
                              failure: FailureHandler) {
        // FIXME: use validators
        success(string)
    }

    func handleResponseJSON(_ json: Any,
                            success: SuccessHandler<Any>,
                            failure: FailureHandler) {
        // FIXME: use validators
        success(json)
    }

    func handleResponseDecodableObject<Result: Decodable>(with data: Data,
                                                          decoder: JSONDecoder = JSONDecoder(),
                                                          success: SuccessHandler<Result>,
                                                          failure: FailureHandler) {
        // FIXME: use validators
        do {
            success(try decoder.decode(from: data))
        } catch {
            failure(error)
        }
    }
}
