//
// Created by Nikita Zatsepilov on 2019-01-23.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire
import Foundation
import XCTest
@testable import Networking

final class MockRequest: Networking.Request {

    enum Constants {
        static let successStatusCode: Int = 200
    }

    private let mockEndpoint: MockEndpoint

    private var completion: Completion?

    init(endpoint: MockEndpoint) {
        self.mockEndpoint = endpoint
        super.init(sessionManager: .default, endpoint: endpoint)
    }

    override func response(completion: @escaping Completion) {
        self.completion = completion

        let requestStartTime = CFAbsoluteTimeGetCurrent()
        DispatchQueue.main.asyncAfter(deadline: .now() + mockEndpoint.responseDelay) {
            let requestEndTime = CFAbsoluteTimeGetCurrent()
            guard self.hasValidAuth() else {
                let response = self.makeResponse(
                    requestStartTime: requestStartTime,
                    requestCompletedTime: requestEndTime,
                    statusCode: 401,
                    error: AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
                )
                completion(self, response)
                return
            }

            guard self.hasValidHeaders() else {
                let response = self.makeResponse(
                    requestStartTime: requestStartTime,
                    requestCompletedTime: requestEndTime,
                    statusCode: 400,
                    error: AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 400))
                )
                completion(self, response)
                return
            }

            let response = self.makeResponse(
                requestStartTime: requestStartTime,
                requestCompletedTime: requestEndTime,
                statusCode: Constants.successStatusCode
            )
            completion(self, response)
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
        if let token = endpoint.expectedAccessToken {
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

    private func makeResponse(requestStartTime: CFAbsoluteTime,
                              requestCompletedTime: CFAbsoluteTime,
                              statusCode: Int? = nil,
                              error: Error? = nil) -> Response {
        var result: Alamofire.Result<Data>
        if let error = error {
            result = .failure(error)
        } else {
            switch mockEndpoint.result {
            case .failure(let error):
                result = .failure(error)
            case .success(let data):
                result = .success(data)
            }
        }

        var response: HTTPURLResponse?
        if let statusCode = statusCode {
            response = HTTPURLResponse(
                url: endpoint.url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )
        }

        let timeline = Timeline(
            requestStartTime: requestStartTime,
            requestCompletedTime: requestCompletedTime
        )
        return Response(
            request: nil,
            response: response,
            data: nil,
            result: result,
            timeline: timeline
        )
    }
}
