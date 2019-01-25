# ⚡ Networking

Networking is a network abstraction layer built on top of [Alamofire](https://github.com/Alamofire/Alamofire).

## Features ✔️

- [x] [`Endpoint` support](#endpoint)
- [x] [Flexible response](#making-a-request), including:
  * `Data`
  * `String`
  * `Decodable`
  * `[Key: Value]`
- [x] [Request adapting](#request-adapting)
- [x] [Error handling](#error-handling)
- [x] [Automatic token refreshing and request retrying](#automatic-token-refreshing-and-request-retrying) 

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

This example demonstrates the common usage with `Decodable` response.  
You also able to use other types of response like below.  
`[Hashable: Any]` (JSON with generic key):
```swift
request(for: endpoint, readingOptions: .allowFragments, success: { (response: [String: Any]) in

}, failure: { error in
    
})
````
`String`:
```swift
request(for: endpoint, encoding: .utf8, success: { (response: String) in

}, failure: { error in
    
})
````
`Data`:
```swift
request(for: endpoint, success: { (response: Data) in

}, failure: { error in
    
})
````
Or empty:
```swift
request(for: endpoint, success: {

}, failure: { error in
    
})
````

⚠️ Request lifecycle ⚠️

`Networking` expects you will keep strong references to sent requests.  
Otherwise request object will not exist at response handling time and success/failure handler will be not called. 

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

enum ProfileEndpoint: UploadEndpoint {
    
    case profile(profileId: String)
    case updateAddress(Address)
    case uploadImage(imageData: Data)

    var baseURL: URL {
        return URL(string: "https://api-url.com")!
    }

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

    var headers: [RequestHeader] {
        return []
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

    var isAuthorized: Bool {
        return true
    }
}
```

By default you should use `Endpoint` protocol. But if you need to use upload requests like in example above, use `UploadEndpoint`, which has additional `imageBodyParts` variable.  
Each endpoint provides `isAuthorized` variable. If you are using `TokenRequestAdapter` (see [request adapting](#request-adapting) for more),
access token will be attached only for requests with authorized endpoints.  
You can also provide custom errors for endpoints using `GeneralErrorHandler`, see [error handling](#error-handling) for more.

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
    
    func handleError<T>(_ error: RequestError<T>, completion: @escaping (ErrorHandlingResult) -> Void) {
        // Request errors appear here
        print("Request failure at: \(error.endpoint.path)")
        print("Error: \(error.underlyingError)")
        print("Response: \(error.response)")
        
        // Redirect error to the next error handler
        completion(.continueErrorHandling(with: error.underlyingError))
    }
}
```

Once error handling completed, you should call completion handler with result,
which affects error handling chain:
- Use `continueErrorHandling(with: error)` to redirect your error to the next error handler. If there is no other error handlers, request will be failed.
- Use `continueFailure(with: error)` fail request with your error right now
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
You don't need to check error code or response status code manually. `GeneralErrorHandler` will help you with it by mapping errors to
`GeneralRequestError`.
There is a list of supported errors:
```swift
public enum GeneralRequestError: Error {
    // For `URLError.notConnectedToInternet`
    case noInternetConnection
    // For `URLError.timedOut`
    case timedOut
    // For `AFError` (Alamofire error) with 401 response status code
    case noAuth
    // For `AFError` with 404 response status code
    case notFound
    // For `URLError.cancelled`
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
    
    func error(for urlError: URLError) -> Error? {
        if case let ProfileEndpoint.uploadImage = self {
            switch urlError {
            case URLError.timedOut:
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

`Networking` can automatically refresh tokens and retry failed requests.

There are three components of this feature:
1. `UnauthorizedErrorHandler` provides error handling logic for "unauthorized" errors with 401 status code
2. `TokenRequestAdapter` provides auth token attaching on request sending/retrying
3. Your service, which implements `SessionServiceProtocol` provides auth token and auth token refreshing logic

#### Usage

1. Create your service and implement `SessionServiceProtocol`:

```swift
import Networking

protocol SessionServiceProtocol: Networking.SessionServiceProtocol {}

final class SessionService: SessionServiceProtocol, NetworkService {
    
    private var token: AuthToken?
    private var refreshAuthToken: String?
    private var tokenRefreshingRequest: CancellableRequest?
    
    var authToken: AuthToken? {
        return token
    }
    
    func refreshAuthToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        guard let refreshAuthToken = refreshAuthToken else {
            failure()
            return
        }
        
        let endpoint = AuthorizationEndpoint.refreshToken(with: refreshAuthToken)
        tokenRefreshingRequest = request(for: endpoint, success: { [weak self] (response: RefreshTokenResponse) in
            self?.token = AuthToken(token: response.token, expiryDate: response.expiryDate)
            success()
        }, failure: { [weak self] error in
            self?.token = nil
            failure(error)
        })
    }
}
```

2. Create `RequestAdaptingService` with `TokenRequestAdapter`

```swift
lazy var sessionService: SessionServiceProtocol = {
    return SessionService()    
}()

lazy var requestAdaptingService: RequestAdaptingServiceProtocol = {
    let tokenRequestAdapter = TokenRequestAdapter(sessionService: sessionService)  
    return RequestAdaptingService(requestAdapters: [tokenRequestAdapter])
}()
```

3. Create `ErrorHandlingService` with `UnauthorizedErrorHandler`:
```swift
lazy var errorHandlingService: ErrorHandlingServiceProtocol = {
    let unauthorizedErrorHandler = UnauthorizedErrorHandler(sessionService: sessionService)  
    return ErrorHandlingService(errorHandlers: [unauthorizedErrorHandler])
}()
```

4. Create `NetworkService` with your error handling and request adapting services:
```swift
lazy var profileService: ProfileServiceProtocol = {
    return ProfileService(requestAdaptingService: requestAdaptingService, errorHandlingService: errorHandlingService)
}()
```

If all is correct, you can expect this result:
1. First, unauthorized error will trigger token refreshing in your `SessionService`.
2. While we're refreshing token, all new failed requests with "unauthorized" error will be collected for future.
3. Once token refreshing completed, failed requests will be adapted (access token changed, we should update request headers) and retried.
4. If token refreshing failed, all pending requests will be failed.

To learn more, please check example project.
