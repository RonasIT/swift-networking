//
// Created by Nikita Zatsepilov on 2019-01-23.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import XCTest
import Alamofire
@testable import Networking

final class MockNetworkService: NetworkService {

    // swiftlint:disable fatal_error_message

    override func request<Response>(for endpoint: Endpoint,
                                    responseSerializer: AnyResponseSerializer<Response>,
                                    success: @escaping Success<Response>,
                                    failure: @escaping Failure) -> CancellableRequest {
        guard let endpoint = endpoint as? MockEndpoint else {
            XCTFail("Mock endpoint required")
            fatalError()
        }

        let request = MockRequest(endpoint: endpoint)
        return send(request, responseSerializer: responseSerializer, success: success, failure: failure)
    }

    override func uploadRequest<Response>(for endpoint: UploadEndpoint,
                                          responseSerializer: AnyResponseSerializer<Response>,
                                          success: @escaping Success<Response>,
                                          failure: @escaping Failure) -> CancellableRequest {
        guard let endpoint = endpoint as? MockEndpoint else {
            XCTFail("Mock endpoint required")
            fatalError()
        }

        let request = MockRequest(endpoint: endpoint)
        return send(request, responseSerializer: responseSerializer, success: success, failure: failure)
    }

    // swiftlint:enable fatal_error_message
}
