# ⚡ Networking

Networking is a network abstraction layer built on top of [Alamofire](https://github.com/Alamofire/Alamofire).

## Table of contents 📦

- [Installation](#installation-)
- [Features](#features-)
- [Usage](#usage-)

## Installation 🎬

To integrate Networking into your Xcode project, specify it in your Cartfile:
```
git "https://projects.ronasit.com/ronas-it/ios/networking.git" "1.1.0"
```

## Features ✔️

- [x] [`Endpoint` support](#endpoint)
- [x] [Flexible response](#making-a-request), including:
  * `Data`
  * `String`
  * `Decodable`
  * `[String: Any]`
- [x] [Reachability](#reachability)
- [x] [Request adapting](#request-adapting)
- [x] [Error handling](#error-handling)
- [x] [Automatic token refreshing and request retrying](#automatic-token-refreshing-and-request-retrying)
- [x] [Logging](#logging) 

## Usage 🔨

### Making a Request

To make requests with specific endpoint you need to subclass `NetworkService`:
```swift
import Networking

final class ProfileService: NetworkService, ProfileServiceProtocol {

    @discardableResult
    func fetchProfile(withId profileId: String, success: @escaping (Profile) -> Void, failure: Failure) -> CancellableRequest {
        let endpoint = ProfileEndpoint.fetchProfile(withId: profileId)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return request(for: endpoint, decoder: decoder, success: { (response: ProfileResponse) in
            success(response.profile)
        }, failure: { error in
            failure(error)
        })
    }
    
    @discardableResult
    func uploadProfileImage(with imageData: Data, success: @escaping (Profile) -> Void, failure: Failure) -> CancellableRequest {
        let endpoint = ProfileEndpoint.uploadImage(with: imageData)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return uploadRequest(for: endpoint, decoder: decoder, success: { (response: UploadProfileImageResponse) in
            success(response.profile)
        }, failure: { error in
            failure(error)
        })
    }
}

private final class ProfileResponse: Decodable {
    let profile: Profile
}
    
private final class UploadProfileImageResponse: Decodable {
    let imageURL: URL
}

// In your models
final class Profile: Codable {
    let id: UInt64
    let firstName: String
    let lastName: String
    let imageURL: URL
}
```

The example above uses `Decodable` response. But you also able to use other types of response like below:
```swift
// `[String: Any]`
request(for: endpoint, readingOptions: .allowFragments, success: { (response: [String: Any]) in

}, failure: { error in
    
})

// `String`
request(for: endpoint, encoding: .utf8, success: { (response: String) in

}, failure: { error in
    
})

// `Data`
request(for: endpoint, success: { (response: Data) in

}, failure: { error in
    
})

// Or empty
request(for: endpoint, success: {

}, failure: { error in
    
})
```

### Cancelling request

Instance of `CancellableRequest` provides request cancellation:

```swift
request.cancel()
```

As usual, cancelled request fails with `NSURLErrorCancelled` error code.
Except you are using `GeneralErrorHandler`, which transforms this error to `GeneralRequestError.cancelled`.

### Endpoint

Each request uses specific endpoint. Endpoint contains information, where and how request should be sent.

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
    
    case profile(profileId: String)
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

    var requiresAuthorization: Bool {
        return true
    }
}
```

Notes:
- By default you should use `Endpoint` protocol. But if you need to use upload requests like in example above, use `UploadEndpoint`, 
which has additional `imageBodyParts` variable.  
- Each endpoint provides `requiresAuthorization` variable. If you are using `TokenRequestAdapter` (see [request adapting](#request-adapting) for more),
access token will be attached only for requests with authorized endpoints.  
- You can also provide custom errors for endpoints using `GeneralErrorHandler`, see [error handling](#error-handling) for more.

### Reachability

`Networking` has built-in `ReachabilityService` to observe internet connection.

#### Usage

```swift

// Create service
let reachabilityService: ReachabilityServiceProtocol = ReachabilityService()

// Start monitoring internet connection
reachabilityService.startMonitoring()

// Stop monitoring internet connection
reachabilityService.stopMonitoring()

// Subscribe on internet connection change events
let subscription = reachabilityService.subscribe { isReachable in
    // Handler will be called while subscription is active
}

// Use to stop receive internet connection change events in subscription handler
subscription.unsubscribe()

// You also can check internet connection directly from service
let isNetworkConnectionAvailable = reachabilityService.isReachable

```

### Request adapting

⚠️ Currently supports only appending headers ⚠️

Request adapting allows you to provide additional information within request.

Request adapting includes:
1. `RequestAdapter`s, which provide request adapting logic
2. `RequestAdaptingService`, which manages request adapting chain for multiple request adapters  
3. Your `NetworkService`, which notifies request adapting service about request sending/retrying

If you need to attach access token through request adapter, there is built-in `TokenRequestAdapter`. See [automatic token refreshing](#automatic-token-refreshing-and-request-retrying) for more. 

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

2. Create request adapting service with your request adapter:
```swift
lazy var generalRequestAdaptingService: RequestAdaptingServiceProtocol = {
   return RequestAdaptingService(requestAdapters: [GeneralRequestAdapter()]) 
}()
```

3. Create your subclass of `NetworkService` with your request adapting service:
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
3. Your `NetworkService`, which notifies `ErrorHandlingService` about an error

Error handlers can be useful in many cases. For example, you can log errors or redirect user to the login screen.
Built-in automatic token refreshing also implemented using custom error handler.

#### Usage  
   
1. Create your own error handler:

```swift
import Networking

final class LoggingErrorHandler: ErrorHandler {
    
    func handleError<T>(_ requestError: RequestError<T>, completion: @escaping (ErrorHandlingResult) -> Void) {
        print("Request failure at: \(requestError.endpoint.path)")
        print("Error: \(requestError.error)")
        print("Response: \(requestError.response)")
        
        // Error will be redirected to the next error handler
        completion(.continueErrorHandling(with: requestError.error))
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
Just implement `func error(forResponseCode responseCode: Int) -> Error?` or `func error(for urlError: URLError) -> Error?` like below.  
If this methods return `nil`, error will be provided by `GeneralErrorHandler`.
```swift
enum ProfileEndpoint: Endpoint {
    case profile(profileId: String)
    case uploadImage(imageData: Data)
    
    func error(forResponseCode responseCode: Int) -> Error? {
        if case let ProfileEndpoint.profile(profileId: let profileId) = self {
            switch responseCode {
                case 404:
                    return ProfileError.notFound(profileId: profileId)
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

⚠️ Supports only OAuth 2.0 Bearer Token ⚠️

`Networking` can automatically refresh access tokens and retry failed requests.

There are three components of this feature:
1. `UnauthorizedErrorHandler` provides error handling logic for "unauthorized" errors with 401 status code
2. `TokenRequestAdapter` provides access token attaching on request sending/retrying
3. Your service, which implements `AccessTokenSupervisor` protocol and provides access token and access token refreshing logic

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
Unauthorized error handler doesn't handle errors for endpoints, which don't require authorizerion. For this endpoints you still will receive unauthorized errors.

## Logging

For debugging purposes you can enable logging in Networking, just specify:
```swift
import Networking

Logging.isEnabled = true
```
Once logging is enabled, you able to view logs in XCode console or from Console of macOS.


To learn more, please check example project.
