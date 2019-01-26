//
// Created by Nikita Zatsepilov on 2019-01-23.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire
import Foundation
import XCTest
@testable import Networking

final class MockRequest<Result>: BaseRequest<Result> {

    private var completion: Completion?

    override func response(completion: @escaping Completion) {
        self.completion = completion

        guard let endpoint = endpoint as? MockEndpoint else {
            XCTFail("Mock request uses mock endpoint")
            fatalError()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let `self` = self else {
                return
            }

            switch endpoint {
            case .success:
                completion(self.successResponse())
            case .failure:
                completion(self.errorResponse(withStatusCode: 400))
            case .mappedErrorForResponseCode(let responseCode, mappedError: _):
                completion(self.errorResponse(withStatusCode: responseCode))
            case .mappedErrorForURLErrorCode(let urlErrorCode, mappedError: _):
                let error = NSError(domain: NSURLErrorDomain, code: urlErrorCode.rawValue)
                completion(self.errorResponse(withStatusCode: 500, error: error))
            case .authorized:
                self.completeAuthorizedRequest(with: completion)
            case .headersValidation(let appendedHeaders):
                self.completeHeadersValidationRequest(with: appendedHeaders, completion: completion)
            default:
                XCTFail("Unsupported endpoint")
                return
            }
        }
    }

    override func cancel() {
        XCTFail("Mock request can't be cancelled, please use non-mock network service")
    }

    override func retry() {
        if let completion = completion {
            response(completion: completion)
        } else {
            XCTFail("Mock request is not sent")
        }
    }

    // MARK: - Private

    private func completeAuthorizedRequest(with completion: @escaping Completion) {
        let expectedAuthHeader = MockSessionService.Constants.validAuthHeader
        let hasAuthHeader = headers.contains { header in
            return header.key == expectedAuthHeader.key &&
                   header.value == expectedAuthHeader.value
        }
        guard hasAuthHeader else {
            completion(errorResponse(withStatusCode: 401))
            return
        }
        completion(successResponse())
    }

    private func completeHeadersValidationRequest(with appendedHeaders: [RequestHeader], completion: @escaping Completion) {
        appendedHeaders.forEach { header in
            let headerExists = headers.contains { $0.key == header.key && $0.value == header.value }
            guard headerExists else {
                completion(errorResponse(withStatusCode: 400))
                return
            }
        }
        completion(successResponse())
    }

    private func errorResponse(withStatusCode statusCode: Int, error: Error? = nil) -> DataResponse<Result> {
        let urlResponse = HTTPURLResponse(url: endpoint.url,
                                          statusCode: statusCode,
                                          httpVersion: nil,
                                          headerFields: nil)
        let error = error ?? AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: statusCode))
        let timeline = Timeline(requestCompletedTime: CFAbsoluteTimeGetCurrent())
        return DataResponse(request: nil, response: urlResponse, data: nil, result: .failure(error), timeline: timeline)
    }

    private func successResponse(with json: [String: Any] = [:]) -> DataResponse<Result> {
        let data = try? JSONSerialization.data(withJSONObject: json)
        let result = responseSerializer.serializeResponse(nil, nil, data, nil)
        let urlResponse = HTTPURLResponse(url: endpoint.url, statusCode: 200, httpVersion: nil, headerFields: nil)
        let timeline = Timeline(requestCompletedTime: CFAbsoluteTimeGetCurrent())
        return DataResponse(request: nil, response: urlResponse, data: data, result: result, timeline: timeline)
    }
}
