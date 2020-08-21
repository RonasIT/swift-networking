# ⚡ Networking

Networking is a network abstraction layer built on top of [Alamofire](https://github.com/Alamofire/Alamofire).

## Table of contents 📦

- [Installation](#installation-)
- [Features](#features-)
- [Usage](#usage-)

## Installation 🎬

To integrate Networking into your Xcode project, specify it in your Cartfile:
```
git "https://projects.ronasit.com/ronas-it/ios/networking.git" "1.3.0"
```

## Features ✔️

- [⚡ Networking](#%e2%9a%a1-networking)
  - [Table of contents 📦](#table-of-contents-%f0%9f%93%a6)
  - [Installation 🎬](#installation-%f0%9f%8e%ac)
  - [Features ✔️](#features-%e2%9c%94%ef%b8%8f)
  - [Usage 🔨](#usage-%f0%9f%94%a8)
    - [Making a Request](#making-a-request)
    - [Supported response types](#supported-response-types)
    - [Cancelling request](#cancelling-request)
    - [Endpoint](#endpoint)
      - [Usage](#usage)
    - [Reachability](#reachability)
      - [Usage](#usage-1)
    - [Request adapting](#request-adapting)
      - [Usage](#usage-2)
    - [Error handling](#error-handling)
      - [Usage](#usage-3)
      - [`GeneralErrorHandler`](#generalerrorhandler)
    - [Automatic token refreshing and request retrying](#automatic-token-refreshing-and-request-retrying)
      - [Usage](#usage-4)
  - [Logging](#logging)

## Usage 🔨

### Making a Request

To make requests with specific endpoint you need to subclass `NetworkService`:
```swift
import Networking

final class AuthService: NetworkService, AuthServiceProtocol {

    private struct SignInResponse: Decodable {
        let user: User
    }

    @discardableResult
    func signIn(withEmail email: String, 
                password: String, 
                success: @escaping (User) -> Void, 
                failure: @escaping (Error) -> Void) -> CancellableRequest {
        let endpoint = AuthEndpoint.signIn(email: email, password: password)
        return request(for: endpoint, success: { (response: SignInResponse) in
            success(response.user)
        }, failure: { error in
            failure(error)
        })
    }
}

final class MediaService: NetworkService, MediaServiceProtocol {

    struct Media: Decodable {
        let id: UInt64
        let url: URL
    }

    @discardableResult
    func uploadMedia(with data: Data, 
                     success: @escaping (Media) -> Void, 
                     failure: @escaping (Error) -> Void) -> CancellableRequest {
        uploadRequest(
            for: MediaEndpoint.upload(data: data), 
            success: success, 
            failure: failure
        )
    }
}
```

### Supported response types

Networking supports  `Decodable`, `Data`, `String`, `[String: Any]` and empty response type.  

Also, you can use response with [`HTTPURLResponse`](https://developer.apple.com/documentation/foundation/httpurlresponse) to access the status code and headers:  
* `Response<Decodable>` or `DecodableResponse<Decodable>`
* `Response<Data>` or `DataResponse`
* `Response<String>` or `StringResponse`
* `Response<[String: Any]>` or `JSONResponse`
* `Response<Void>` or `EmptyResponse`

### Cancelling request

Instance of `CancellableRequest` provides request cancellation:

```swift
request.cancel()
```

As usual, cancelled request fails with `NSURLErrorCancelled` error code.
Except you are using `GeneralErrorHandler`, which transforms this error to `GeneralRequestError.cancelled`.

### Endpoint

Each request uses specific endpoint. Endpoint contains an information, where and how the request should be sent.

#### Usage

```swift
import Networking
import Alamofire

// Customize default values for all endpoints using extension

extension Endpoint {

    var baseURL: URL {
        return AppConfiguration.apiURL
    }

    var headers: [RequestHeader] {
        return [
            RequestHeaders.accept("application/json"),
            RequestHeaders.contentType("application/json")
        ]
    }

    var parameterEncoding: ParameterEncoding {
        return JSONEncoding.default
    }

    var parameters: Parameters? {
        return nil
    }
}

...

// Add endpoint

enum ProfileEndpoint: UploadEndpoint {
    case fetchProfile(Profile.ID)
    case updateAddress(Address)
    case uploadImage(imageData: Data)

    var path: String {
        switch self {
        case .profile(let profileId):
            return "profile/\(profileId)"
        case .updateAddress(let address):
            return "profile/address/\(address.id)"
        case uploadImage:
            return "profile/image"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .profile:
            return .get
        case .updateAddress:
            return .post
        case uploadImage:
            return .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case .updateAddress(let address):
            return address.asDictionary()
        default:
            return nil
        }
    }

    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    
    var imageBodyParts: [ImageBodyPart] {
        switch self {
        case .uploadImage(let imageData):
            return [ImageBodyPart(imageData: imageData)]
        default:
            return []
        }
    }

    var authorizationType: Bool {
        return .bearer
    }
}
```

Notes:
- By default you should use `Endpoint` protocol. But if you need to use upload requests like in example above, use `UploadEndpoint`, 
which has additional `imageBodyParts` property.  
- Each endpoint provides `authorizationType` property. If you are using `TokenRequestAdapter` (see [request adapting](#request-adapting) for more),
access token will be attached only for requests with authorized endpoints.  
- You can also provide custom errors for endpoints using `GeneralErrorHandler`, see [error handling](#error-handling) for more.

### Reachability

`Networking` has built-in `ReachabilityService` to observe internet connection status.

#### Usage

```swift

// Create service
let reachabilityService: ReachabilityServiceProtocol = ReachabilityService()

// Start monitoring internet connection
reachabilityService.startMonitoring()

// Stop monitoring internet connection
reachabilityService.stopMonitoring()

// Subscribe to internet connection change events
let subscription = reachabilityService.subscribe { isReachable in
    // Handler will be called while subscription is active
}

// Stop receiving the internet connection change events
subscription.unsubscribe()

// You also can check internet connection directly from service
let isNetworkConnectionAvailable = reachabilityService.isReachable

```

### Request adapting

⚠️ Currently supports only headers appending ⚠️

Request adapting allows you to provide additional information within request.

Request adapting includes:
1. `RequestAdapter`s, that provide a request adapting logic
2. `RequestAdaptingService`, that manages a request adapting chain for multiple request adapters  
3. Your `NetworkService`, that notifies request adapting service about request sending/retrying

If you need to attach an access token through a request adapter, there is built-in `TokenRequestAdapter`. See [automatic token refreshing](#automatic-token-refreshing-and-request-retrying) for more. 

#### Usage

1. Implement your custom request adapter:
```swift
import Networking
import UIKit.UIDevice

final class GeneralRequestAdapter: RequestAdapter {

    func adapt(_ request: AdaptiveRequest) {
        // You can use some general headers from `RequestHeaders` enum
        // Let's append some information about the app 
        request.appendHeader(RequestHeaders.dpi(scale: UIScreen.main.scale))
        if let appInfo = Bundle.main.infoDictionary,
           let appVersion = appInfo["CFBundleShortVersionString"] as? String {
            let header = RequestHeaders.userAgent(osVersion: UIDevice.current.systemVersion, appVersion: appVersion)
            request.appendHeader(header)
        }
    }
}
```

2. Create request adapting service with your request adapter injected:
```swift
lazy var generalRequestAdaptingService: RequestAdaptingServiceProtocol = {
   return RequestAdaptingService(requestAdapters: [GeneralRequestAdapter()]) 
}()
```

3. Create your subclass of `NetworkService` with your request adapting service injected:
```swift
lazy var profileService: ProfileServiceProtocol = {
    return ProfileService(requestAdaptingService: generalRequestAdaptingService)  
}()
```  

### Error handling

This feature provides more efficient error handling for failed requests.

There are three components of error handling:
1. `ErrorHandler`s provide error handling logic
2. `ErrorHandlingService` stores error handlers, manages error handling chain logic
3. Your `NetworkService`, that notifies the `ErrorHandlingService` about an error

Error handlers can be useful in many cases. For example, you can log errors or redirect user to a login screen.
Built-in automatic token refreshing also implemented using custom error handler.

#### Usage  
   
1. Create your own error handler:
```swift
import Networking

final class LoggingErrorHandler: ErrorHandler {
    
    func handleError(with payload: ErrorPayload, completion: @escaping (ErrorHandlingResult) -> Void) {
        print("Request failure at: \(payload.endpoint.path)")
        print("Error: \(payload.error)")
        print("Response: \(payload.response)")
        
        // Error payload will be redirected to the next error handler
        completion(.continueErrorHandling(with: payload.error))
    }
}
```

Once error handling completed, you should call completion handler with result,
which affects error handling chain:
- Use `continueErrorHandling(with: error)` to redirect your error to the next error handler. If there is no other error handlers, request will be failed.
- Use `continueFailure(with: error)` to fail request with your error right now
- Use `retryNeeded` to retry failed request

2. Create error handling service with your error handler:
```swift
lazy var generalErrorHandlingService: ErrorHandlingServiceProtocol = {
   return ErrorHandlingService(errorHandlers: [LoggingErrorHandler()]) 
}()
```

3. Pass your error handling service to `NetworkService` subclass:
```swift
lazy var profileService: ProfileServiceProtocol = {
    return ProfileService(errorHandlingService: generalErrorHandlingService)  
}()
```

#### `GeneralErrorHandler`

To simplify error handling for some general errors, any `ErrorHandlingService` uses built-in `GeneralErrorHandler` by default.
You don't need to check error code or response status code manually. `GeneralErrorHandler` will map some errors to
`GeneralRequestError`.
There is a list of supported errors:
```swift
public enum GeneralRequestError: Error {
    // For `URLError.Code.notConnectedToInternet`
    case noInternetConnection
    // For `URLError.Code.timedOut`
    case timedOut
    // `AFError` with 401 response status code
    case noAuth
    // `AFError` with 403 response status code
    case forbidden
    // `AFError` with 404 response status code
    case notFound
    // For `URLError.Code.cancelled`
    case cancelled
}
```

With `GeneralErrorHandler` you can also provide custom errors right from `Endpoint`.  
Just implement `func error(for statusCode: StatusCode) -> Error?` or `func error(for urlError: URLError) -> Error?` like below.  
If these methods return `nil`, error will be provided by `GeneralErrorHandler`.
```swift
enum ProfileEndpoint: Endpoint {
    case fetchProfile(Profile.ID)
    case uploadImage(imageData: Data)
    
    func error(for statusCode: StatusCode) -> Error? {
        if case ProfileEndpoint.profile(let profileID) = self {
            switch statusCode {
            case .notFound404:
                return ProfileError.notFound(profileID: profileID)
            default:
                return nil            
            }
        }
        return nil
    }
    
    func error(for urlErrorCode: URLError.Code) -> Error? {
        if case let ProfileEndpoint.uploadImage = self {
            switch urlErrorCode {
            case .timedOut:
                return ProfileError.imageTooLarge
            default:
                return nil
            }
        }
        return nil
    }
}
```


### Automatic token refreshing and request retrying

`Networking` can automatically refresh access tokens and retry failed requests.

There are three components of this feature:
1. `UnauthorizedErrorHandler` provides error handling logic for "unauthorized" errors with 401 status code
2. `TokenRequestAdapter` provides access token attaching on request sending/retrying
3. Your service, that implements `AccessTokenSupervisor` protocol, provides access token and access token refreshing logic

#### Usage

1. Create your service and implement `AccessTokenSupervisor` protocol:
```swift
import Networking

protocol SessionServiceProtocol: AccessTokenSupervisor {}

final class SessionService: SessionServiceProtocol, NetworkService {
    
    private var token: String?
    private var refreshToken: String?
    
    var accessToken: AccessToken? {
        return token
    }
    
    func refreshAccessToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        guard let refreshAccessToken = refreshAccessToken else {
            failure()
            return
        }
        let endpoint = AuthorizationEndpoint.refreshAccessToken(with: refreshToken)
        request(for: endpoint, success: { [weak self] (response: RefreshTokenResponse) in
            self?.token = response.accessToken
            self?.refreshToken = response.refreshToken
            success()
        }, failure: { [weak self] error in
            self?.token = nil
            failure(error)
        })
    }
}
```

2. Create `RequestAdaptingService` with `TokenRequestAdapter`:
```swift
lazy var sessionService: SessionServiceProtocol = {
    return SessionService()    
}()

lazy var requestAdaptingService: RequestAdaptingServiceProtocol = {
    let tokenRequestAdapter = TokenRequestAdapter(accessTokenSupervisor: sessionService)  
    return RequestAdaptingService(requestAdapters: [tokenRequestAdapter])
}()
```

3. Create `ErrorHandlingService` with `UnauthorizedErrorHandler`:
```swift
lazy var errorHandlingService: ErrorHandlingServiceProtocol = {
    let unauthorizedErrorHandler = UnauthorizedErrorHandler(accessTokenSupervisor: sessionService)  
    return ErrorHandlingService(errorHandlers: [unauthorizedErrorHandler])
}()
```

4. Create `NetworkService` with your error handling and request adapting services:
```swift
lazy var profileService: ProfileServiceProtocol = {
    return ProfileService(requestAdaptingService: requestAdaptingService, 
                          errorHandlingService: errorHandlingService)
}()
```

If all is correct, you can forget about expired access tokens in your app.

**Note**  
Unauthorized error handler doesn't handle errors for endpoints, which don't require authorization. For these endpoints you'll still receive unauthorized errors.


To learn more, please check example project.
