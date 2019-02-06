//
// Created by Nikita Zatsepilov on 2019-01-23.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire
import Foundation
import XCTest
@testable import Networking

final class MockRequest<Result>: Networking.Request<Result> {

    private let mockEndpoint: MockEndpoint

    private var completion: Completion?

    init(endpoint: MockEndpoint, responseSerializer: DataResponseSerializer<Result>) {
        self.mockEndpoint = endpoint
        super.init(sessionManager: .default, endpoint: endpoint, responseSerializer: responseSerializer)
    }

    override func response(completion: @escaping Completion) {
        self.completion = completion

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let `self` = self else {
                return
            }

            guard self.hasValidAuth() else {
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
                completion(self.makeResponse(with: error))
                return
            }

            guard self.hasValidHeaders() else {
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 400))
                completion(self.makeResponse(with: error))
                return
            }

            completion(self.makeResponse())
        }
    }

    override func retry() -> Bool {
        guard let completion = completion else {
            return false
        }
        response(completion: completion)
        return true
    }

    override func cancel() -> Bool {
        XCTFail("Please test cancellation using real requests")
        return false
    }

    // MARK: - Private

    private func hasValidAuth() -> Bool {
        let endpoint = mockEndpoint
        if let token = endpoint.expectedAccessToken?.token {
            return headers.contains { $0.key == "Authorization" && $0.value == "Bearer \(token)" }
        } else {
            return true
        }
    }

    private func hasValidHeaders() -> Bool {
        let endpoint = mockEndpoint
        guard !endpoint.expectedHeaders.isEmpty else {
            return true
        }

        return endpoint.expectedHeaders.allSatisfy { header in
            return headers.contains { $0.key == header.key && $0.value == header.value }
        }
    }

    private func makeResponse(with error: Error? = nil) -> DataResponse<Result> {
        var result: Alamofire.Result<Result>
        if let error = error {
            result = .failure(error)
        } else {
            switch mockEndpoint.result {
            case .failure(with: let error):
                result = .failure(error)
            case .success(with: let data):
                result = responseSerializer.serializeResponse(nil, nil, data, nil)
            }
        }

        let timeline = Timeline(requestCompletedTime: CFAbsoluteTimeGetCurrent())
        return DataResponse(request: nil, response: nil, data: nil, result: result, timeline: timeline)
    }
}
