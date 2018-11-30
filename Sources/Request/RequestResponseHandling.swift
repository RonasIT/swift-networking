//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation

protocol RequestResponseHandling {

    func handleResponseData(_ data: Data,
                            successHandler: SuccessHandler<Data>,
                            failureHandler: FailureHandler)

    func handleResponseString(_ string: String,
                              successHandler: SuccessHandler<String>,
                              failureHandler: FailureHandler)

    func handleResponseJSON(_ json: Any,
                            successHandler: SuccessHandler<Any>,
                            failureHandler: FailureHandler)

    func handleResponseDecodableObject<Result: Decodable>(with data: Data,
                                                          decoder: JSONDecoder,
                                                          successHandler: SuccessHandler<Result>,
                                                          failureHandler: FailureHandler)
}

extension RequestResponseHandling {

    func handleResponseData(_ data: Data,
                            successHandler: SuccessHandler<Data>,
                            failureHandler: FailureHandler) {
        // FIXME: use validators
        successHandler(data)
    }

    func handleResponseString(_ string: String,
                              successHandler: SuccessHandler<String>,
                              failureHandler: FailureHandler) {
        // FIXME: use validators
        successHandler(string)
    }

    func handleResponseJSON(_ json: Any,
                            successHandler: SuccessHandler<Any>,
                            failureHandler: FailureHandler) {
        // FIXME: use validators
        successHandler(json)
    }

    func handleResponseDecodableObject<Result: Decodable>(with data: Data,
                                                          decoder: JSONDecoder = JSONDecoder(),
                                                          successHandler: SuccessHandler<Result>,
                                                          failureHandler: FailureHandler) {
        // FIXME: use validators
        do {
            successHandler(try decoder.decode(from: data))
        } catch {
            failureHandler(error)
        }
    }
}
