//
// Created by Nikita Zatsepilov on 2019-01-19.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking
import Alamofire
import XCTest

final class RequestTests: XCTestCase {

    private var request: CancellableRequest?

    override func tearDown() {
        super.tearDown()
        request = nil
    }

    func testRequestWithDataResult() {
        testRequestWithDataResult(isTestingUploadRequest: false)
    }

    func testUploadRequestWithDataResult() {
        testRequestWithDataResult(isTestingUploadRequest: true)
    }

    func testRequestWithStringResult() {
        testRequestWithStringResult(isTestingUploadRequest: false)
    }

    func testUploadRequestWithStringResult() {
        testRequestWithStringResult(isTestingUploadRequest: true)
    }

    func testRequestWithDecodableResult() {
        testRequestWithDecodableResult(isTestingUploadRequest: false)
    }

    func testUploadRequestWithDecodableResult() {
        testRequestWithDecodableResult(isTestingUploadRequest: true)
    }

    func testRequestWithJSONResult() {
        testRequestWithJSONResult(isTestingUploadRequest: false)
    }

    func testUploadRequestWithJSONResult() {
        testRequestWithJSONResult(isTestingUploadRequest: true)
    }

    func testRequestWithEmptyResult() {
        testRequestWithEmptyResult(isTestingUploadRequest: false)
    }

    func testUploadRequestWithEmptyResult() {
        testRequestWithEmptyResult(isTestingUploadRequest: true)
    }

    func testCancellation() {
        let responseExpectation = expectation(description: "Expecting cancellation error in response")
        responseExpectation.assertForOverFulfill = true

        // We have to test implementation of real request
        let errorHandlingService = ErrorHandlingService()
        let networkService = NetworkService(errorHandlingService: errorHandlingService)
        request = networkService.request(for: HTTPBinEndpoint.status(200), success: {
            XCTFail("Invalid case")
        }, failure: { error in
            switch error {
            case let error as GeneralRequestError where error == .cancelled:
                responseExpectation.fulfill()
            default:
                XCTFail("Invalid error")
            }
        })
        request?.cancel()

        wait(for: [responseExpectation], timeout: 10)
    }
    
    func testUploadCancellation() {
        let responseExpectation = expectation(description: "Expecting cancellation error in response")
        responseExpectation.assertForOverFulfill = true

        // We have to test implementation of real request
        let errorHandlingService = ErrorHandlingService()
        let networkService = NetworkService(errorHandlingService: errorHandlingService)
        request = networkService.uploadRequest(for: HTTPBinEndpoint.uploadStatus(200), success: {
            XCTFail("Invalid case")
        }, failure: { error in
            switch error {
            case let error as GeneralRequestError where error == .cancelled:
                responseExpectation.fulfill()
            default:
                XCTFail("Invalid error")
            }
        })
        request?.cancel()

        wait(for: [responseExpectation], timeout: 10)
    }

    func testRequestMemoryLeak() {
        let lifecycleExpectation = expectation(description: "Expecting request callbacks are not called")

        // We have to test implementation of real request
        let networkService = NetworkService()
        weak var request = networkService.request(for: HTTPBinEndpoint.status(200), success: {
            XCTFail("Invalid case")
        }, failure: { _ in
            XCTFail("Invalid case")
        })
        
        _ = XCTWaiter.wait(for: [lifecycleExpectation], timeout: 3)
        XCTAssertNil(request)
        lifecycleExpectation.fulfill()
    }
    
    func testUploadRequestMemoryLeak() {
        let lifecycleExpectation = expectation(description: "Expecting request callbacks are not called")

        // We have to test implementation of real request
        let networkService = NetworkService()
        weak var request = networkService.uploadRequest(for: HTTPBinEndpoint.status(200), success: {
            XCTFail("Invalid case")
        }, failure: { _ in
            XCTFail("Invalid case")
        })
        
        _ = XCTWaiter.wait(for: [lifecycleExpectation], timeout: 3)
        XCTAssertNil(request)
        lifecycleExpectation.fulfill()
    }

    // MARK: - Private

    private func testRequestWithDataResult(isTestingUploadRequest: Bool) {
        let service = MockNetworkService()
        let expectedResult = "result".data(using: .utf8)!
        let endpoint = MockEndpoint(result: expectedResult)
        let expectation = self.expectation(description: "Expecting same result")
        expectation.assertForOverFulfill = true
        func validate(_ result: Data) {
            XCTAssertEqual(result, expectedResult)
            expectation.fulfill()
        }
        if isTestingUploadRequest {
            request = service.uploadRequest(for: endpoint, success: { validate($0) }, failure: { _ in
                XCTFail("Invalid case")
            })
        } else {
            request = service.request(for: endpoint, success: { validate($0) }, failure: { _ in
                XCTFail("Invalid case")
            })
        }
        wait(for: [expectation], timeout: 5)
    }

    private func testRequestWithStringResult(isTestingUploadRequest: Bool) {
        let service = MockNetworkService()
        let expectedResult = "result"
        let endpoint = MockEndpoint(result: expectedResult)
        let expectation = self.expectation(description: "Expecting same result")
        expectation.assertForOverFulfill = true
        func validate(_ result: String) {
            XCTAssertEqual(result, expectedResult)
            expectation.fulfill()
        }
        if isTestingUploadRequest {
            request = service.uploadRequest(for: endpoint, success: { validate($0) }, failure: { _ in
                XCTFail("Invalid case")
            })
        } else {
            request = service.request(for: endpoint, success: { validate($0) }, failure: { _ in
                XCTFail("Invalid case")
            })
        }
        wait(for: [expectation], timeout: 5)
    }

    private func testRequestWithDecodableResult(isTestingUploadRequest: Bool) {
        struct User: Equatable, Codable {
            let firstName: String
            let lastName: String
            let birthDate: Date
        }
        let service = MockNetworkService()
        let expectedResult = User(firstName: "John", lastName: "Doe", birthDate: Date())
        let endpoint = MockEndpoint(result: expectedResult)
        let expectation = self.expectation(description: "Expecting same result")
        expectation.assertForOverFulfill = true
        func validate(_ result: User) {
            XCTAssertEqual(result, expectedResult)
            expectation.fulfill()
        }
        if isTestingUploadRequest {
            request = service.uploadRequest(for: endpoint, success: { validate($0) }, failure: { _ in
                XCTFail("Invalid case")
            })
        } else {
            request = service.request(for: endpoint, success: { validate($0) }, failure: { _ in
                XCTFail("Invalid case")
            })
        }
        wait(for: [expectation], timeout: 5)
    }

    private func testRequestWithJSONResult(isTestingUploadRequest: Bool) {
        let networkService = MockNetworkService()
        let expectedResult: [String: String] = [
            "firstName": "John",
            "lastName": "Doe"
        ]

        // We want to test `[String: Any]` response with JSONSerialization
        // We need pass expected result as `[String: Any]`,
        // because `[String: String]` is `Codable` type
        let endpoint = MockEndpoint(result: expectedResult as [String: Any])
        let expectation = self.expectation(description: "Expecting same result")
        expectation.assertForOverFulfill = true
        func validate(_ result: [String: String]) {
            XCTAssertEqual(result, expectedResult)
            expectation.fulfill()
        }
        if isTestingUploadRequest {
            request = networkService.uploadRequest(for: endpoint, success: { (result: [String: Any]) in
                // Cast back to `[String: String]` to validate with expected result
                guard let result = result as? [String: String] else {
                    XCTFail("Unexpected result")
                    return
                }
                validate(result)
            }, failure: { error in
                XCTFail("Invalid case")
            })
        } else {
            request = networkService.request(for: endpoint, success: { (result: [String: Any]) in
                // Cast back to `[String: String]` to validate with expected result
                guard let result = result as? [String: String] else {
                    XCTFail("Unexpected result")
                    return
                }
                validate(result)
            }, failure: { error in
                XCTFail("Invalid case")
            })
        }
        wait(for: [expectation], timeout: 5)
    }

    private func testRequestWithEmptyResult(isTestingUploadRequest: Bool) {
        let service = MockNetworkService()
        let endpoint = MockEndpoint()
        let expectation = self.expectation(description: "Expecting success")
        expectation.assertForOverFulfill = true

        if isTestingUploadRequest {
            request = service.uploadRequest(
                for: endpoint,
                success: { expectation.fulfill() },
                failure: { _ in XCTFail("Invalid case")}
            )
        } else {
            request = service.request(
                for: endpoint,
                success: { expectation.fulfill() },
                failure: { _ in XCTFail("Invalid case")}
            )
        }
        wait(for: [expectation], timeout: 5)
    }
}
