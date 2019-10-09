//
// Created by Nikita Zatsepilov on 2019-01-23.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import XCTest
import Alamofire
@testable import Networking

final class MockNetworkService: NetworkService {

    // swiftlint:disable fatal_error_message

    override func request<Result>(for endpoint: Endpoint,
                                  responseSerializer: DataResponseSerializer<Result>,
                                  success: @escaping Success<Result>,
                                  failure: @escaping Failure) -> CancellableRequest {
        guard let endpoint = endpoint as? MockEndpoint else {
            XCTFail("Mock endpoint required")
            fatalError()
        }

        let request = MockRequest(endpoint: endpoint, responseSerializer: responseSerializer)
        return response(for: request, success: success, failure: failure)
    }

    override func uploadRequest<Result>(for endpoint: UploadEndpoint,
                                        responseSerializer: DataResponseSerializer<Result>,
                                        success: @escaping Success<Result>,
                                        failure: @escaping Failure) -> CancellableRequest {
        guard let endpoint = endpoint as? MockEndpoint else {
            XCTFail("Mock endpoint required")
            fatalError()
        }

        let request = MockRequest(endpoint: endpoint, responseSerializer: responseSerializer)
        return response(for: request, success: success, failure: failure)
    }

    // swiftlint:enable fatal_error_message
}
