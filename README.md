# Networking

Networking is a network abstraction layer built on top of [Alamofire](https://github.com/Alamofire/Alamofire).

## Features

- [x] `Endpoint` support
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

`Networking` doesn't keep strong references to sent requests.   
To correctly execute any request, you should keep `strong` reference to it until completion handler will be executed.

### Cancelling request

Instance of `CancellableRequest` provide request cancellation:

```swift
request.cancel()
```

As usual, cancelled request fails with `NSURLErrorCancelled` error code.
Except you are using `GeneralErrorHandler`, which transforms this error to `GeneralRequestError.cancelled`.

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

### Automatic token refreshing and request retrying

⚠️ Supports OAuth 2.0 Bearer Token ⚠️

`Networking` can automatically refresh tokens and retry failed requests.

How it works:
1. Build-in `UnauthorizedErrorHandler` provides catching and handling `Unauthorized` error with 401 status code
2. Build-in `TokenRequestAdapter` provides auth token attaching on request sending or retrying
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

2. Add `TokenRequestAdapter` to your request adapting service, which depends on your session service:

```swift
lazy var sessionService: SessionServiceProtocol = {
    return SessionService()    
}()

lazy var requestAdaptingService: RequestAdaptingServiceProtocol = {
    let tokenRequestAdapter = TokenRequestAdapter(sessionService: sessionService)  
    return RequestAdaptingService(requestAdapters: [tokenRequestAdapter])
}()
```

3. Add `UnauthorizedErrorHandler` to your error handling service, which also depends on your session service:
```swift
lazy var errorHandlingService: ErrorHandlingServiceProtocol = {
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
