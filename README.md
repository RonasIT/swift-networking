# Networking

Networking is a network abstraction layer built on top of [Alamofire](https://github.com/Alamofire/Alamofire).

## Features

- [x] [`Endpoint` support](#endpoint)
- [x] [Flexible response](#making-a-request), including:
  * `Data`
  * `String`
  * `Decodable`
  * `[Key: Value]`
- [x] [Request adapting](#request-adapting)
- [x] [Error handling](#error-handling)
- [x] [Automatic token refreshing and request retrying](#automatic-token-refreshing-and-request-retrying) 

## Usage

### Making a Request

To send requests with specific endpoint you need to subclass `NetworkService`, like this:
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

⚠️ Important ⚠️

`Networking` expects you will keep strong references to sent request objects till completion.  
Otherwise completion handlers will be not called because request object will not exist at the response handling time. 

### Cancelling request

Instance of `CancellableRequest` provides request cancellation:

```swift
request.cancel()
```

As usual, cancelled request fails with `NSURLErrorCancelled` error code.
Except you are using `GeneralErrorHandler`, which transforms this error to `GeneralRequestError.cancelled`.

### Endpoint

Each request uses specified endpoint. Endpoint contains information, where and how request should be sent.

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

By default you should use `Endpoint` implement protocol. But if you need to use upload requests like example above, use `UploadEndpoint`, which has additional `imageBodyParts` variable.  
Each endpoint provides `isAuthorized` variable. If you are using `TokenRequestAdapter` (see [request adapting](#request-adapting) for more),
access token will be attached only for requests with authorized endpoints.  
You can also provide specified errors for endpoints, see [error handling](#error-handling) for more.

### Request adapting

⚠️ Currently supports only appending headers ⚠️

Request adapting allows you to provide additional information within request.  
The main aim of this feature is the ability to attach access token within request on sending and retrying.  
There are some other useful cases. For example, you can implement custom request adapter to attach some information about an app, 
like below.

If you need to attach access token through request adapter, there is built-in `TokenRequestAdapter`. See [automatic token refreshing](#automatic-token-refreshing-and-request-retrying) for more. 

#### Usage

1. Implement your custom request adapter:

```swift
import Networking
import UIKit.UIDevice

final class GeneralRequestAdapter: RequestAdapter {

    func adapt(_ request: AdaptiveRequest) {
        // Let's append some information about app within requests
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

3. Create your subclass of `NetworkService` with your error handling service:
```swift
lazy var profileService: ProfileServiceProtocol = {
    return ProfileService(requestAdaptingService: generalRequestAdaptingService)  
}()
```  

### Error handling

This feature provides more efficient error handling for failed requests.  
You can wrap some logic for specified errors using `ErrorHandler`s.
For example, you can log errors or redirect user to the login screen once app received specific error.
Multiple error handlers together can provide error handling chain.

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
        
        // Error will be passed to the next error handler
        completion(.continueErrorHandling(with: error.underlyingError))
    }
}
```

Each error handler should call completion handler with one of results:
* `continueErrorHandling(with: error)` - to continue error handling chain, error will be passed to the next error handler.  
If there is **no other** error handlers, request will be failed with passed error.
* `continueFailure(with: error)` - to interrupt error handling chain and fail request with passed error.
* `retryNeeded` - to interrupt error handling chain and retry request.

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
You don't need to check error code or response status code manually. `GeneralErrorHandler` will map this errors for you.
There is list of supported errors:
```swift
public enum GeneralRequestError: Error {
    // For `URLError.notConnectedToInternet`
    case noInternetConnection
    // For `URLError.timedOut`
    case timedOut
    // For `AFError` with 401 response status code
    case noAuth
    // For `AFError` with 404 response status code
    case notFound
    // For `URLError.cancelled`
    case cancelled
}
```

With `GeneralErrorHandler` you also can provide custom errors right from `Endpoint`.  
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

How it works:
1. Built-in `UnauthorizedErrorHandler` provides catching and handling `Unauthorized` error with 401 status code
2. Built-in `TokenRequestAdapter` provides auth token attaching on request sending or retrying
3. Your `SessionService`, which implements `SessionServiceProtocol` provides auth token and auth token refreshing

#### Usage

1. Create your service, which implements `Networking.SessionServiceProtocol`:

```swift
import Networking

protocol SessionServiceProtocol: Networking.SessionServiceProtocol {}

final class SessionService: SessionServiceProtocol, NetworkService {
    
    private var token: AuthToken?
    private var refreshAuthToken: String?
    
    var authToken: AuthToken? {
        return token
    }
    
    private var tokenRefreshingRequest: CancellableRequest?
    
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

2. Add `TokenRequestAdapter` to your request adapting service:

```swift
lazy var sessionService: SessionServiceProtocol = {
    return SessionService()    
}()

lazy var requestAdaptingService: RequestAdaptingServiceProtocol = {
    // `TokenRequestAdapter` depends on session service
    let tokenRequestAdapter = TokenRequestAdapter(sessionService: sessionService)  
    return RequestAdaptingService(requestAdapters: [tokenRequestAdapter])
}()
```

3. Add `UnauthorizedErrorHandler` to your error handling service:
```swift
lazy var errorHandlingService: ErrorHandlingServiceProtocol = {
    // `UnauthorizedErrorHandler` depends on session service
    let unauthorizedErrorHandler = UnauthorizedErrorHandler(sessionService: sessionService)  
    return ErrorHandlingService(errorHandlers: [unauthorizedErrorHandler])
}()
```

4. Add your request adapting service and error handling service to `NetworkService` subclass:
```swift
lazy var profileService: ProfileServiceProtocol = {
    return ProfileService(requestAdaptingService: requestAdaptingService, errorHandlingService: errorHandlingService)
}()
```


To learn more, please check example project.
