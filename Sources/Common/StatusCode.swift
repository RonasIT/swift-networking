//
//  Created by Dmitry Frishbuter on 20.08.2020
//  Copyright © 2020 Ronas IT. All rights reserved.
//

public enum StatusCode: Int {

    // MARK: -  Informational
    case continue100 = 100
    case switchingProtocols101 = 101
    case processing102 = 102

    // MARK: -  Success
    case ok200 = 200
    case created201 = 201
    case accepted202 = 202
    case nonAuthoritativeInformation203 = 203
    case noContent204 = 204
    case resetContent205 = 205
    case partialContent206 = 206
    case multiStatus207 = 207
    case alreadyReported208 = 208
    case IMUsed209 = 209

    // MARK: -  Redirection
    case multipleChoices300 = 300
    case movedPermanently301 = 301
    case found302 = 302
    case seeOther303 = 303
    case notModified304 = 304
    case useProxy305 = 305
    case switchProxy306 = 306
    case temporaryRedirect307 = 307
    case permanentRedirect308 = 308

    // MARK: -  Client error
    case badRequest400 = 400
    case unauthorised401 = 401
    case paymentRequired402 = 402
    case forbidden403 = 403
    case notFound404 = 404
    case methodNotAllowed405 = 405
    case notAcceptable406 = 406
    case proxyAuthenticationRequired407 = 407
    case requestTimeout408 = 408
    case conflict409 = 409
    case gone410 = 410
    case lengthRequired411 = 411
    case preconditionFailed412 = 412
    case requestEntityTooLarge413 = 413
    case requestURITooLong414 = 414
    case unsupportedMediaType415 = 415
    case requestedRangeNotSatisfiable416 = 416
    case expectationFailed417 = 417
    case iAmATeapot418 = 418
    case authenticationTimeout419 = 419
    case methodFailureSpringFramework420 = 420
    case misdirectedRequest421 = 421
    case unprocessableEntity422 = 422
    case locked423 = 423
    case failedDependency424 = 424
    case unorderedCollection425 = 425
    case upgradeRequired426 = 426
    case preconditionRequired428 = 428
    case tooManyRequests429 = 429
    case requestHeaderFieldsTooLarge431 = 431
    case noResponseNginx444 = 444
    case unavailableForLegalReasons451 = 451
    case requestHeaderTooLargeNginx494 = 494
    case certErrorNginx495 = 495
    case noCertNginx496 = 496
    case HTTPToHTTPSNginx497 = 497
    case clientClosedRequest499 = 499

    // MARK: -  Server error
    case internalServerError500 = 500
    case notImplemented501 = 501
    case badGateway502 = 502
    case serviceUnavailable503 = 503
    case gatewayTimeout504 = 504
    case HTTPVersionNotSupported505 = 505
    case variantAlsoNegotiates506 = 506
    case insufficientStorage507 = 507
    case loopDetected508 = 508
    case bandwidthLimitExceeded509 = 509
    case notExtended510 = 510
    case networkAuthenticationRequired511 = 511
    case connectionTimedOut522 = 522
    case networkReadTimeoutErrorUnknown598 = 598
    case networkConnectTimeoutErrorUnknown599 = 599

    public var code: Int {
        return rawValue
    }
}
