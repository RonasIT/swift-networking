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

This example demonstrates the common usage with `Decodable` responses.  
You also able to use `[Hashable: Any]` (JSON), `String`, `Data` or empty response:

```swift

// JSON
request(for: endpoint, readingOptions: .allowFragments, success: { (response: [String: Any]) in

}, failure: { error in
    
})

// String
request(for: endpoint, encoding: .utf8, success: { (response: String) in

}, failure: { error in
    
})

// Data
request(for: endpoint, success: { (response: Data) in

}, failure: { error in
    
})

// Empty
request(for: endpoint, success: {

}, failure: { error in
    
})

````

### Cancelling request

Instance of `CancellableRequest` provide request cancellation:

```swift
request.cancel()
```

As usual, cancelled request fails with `NSURLErrorCancelled` error code.

### Request adapting

⚠️ Currently supports only appending headers ⚠️  

Request adapting allows you to adapt requests before sending to the server.
For example you can provide access token or information about the app and device using `RequestAdapter` objects.

#### Usage

First, implement your custom request adapter, like:

```swift
import Networking
import UIKit.UIDevice

final class GeneralRequestAdapter: RequestAdapter {

    func adapt(_ request: AdaptiveRequest) {
        request.appendHeader(RequestHeaders.dpi(scale: UIScreen.main.scale))
        if let appInfo = Bundle.main.infoDictionary,
           let appVersion = appInfo["CFBundleShortVersionString"] as? String {
            let header = RequestHeaders.userAgent(osVersion: UIDevice.current.systemVersion, appVersion: appVersion)
            request.appendHeader(header)
        }
    }
}

```

Then initialize `NetworkService` subclass with your request adapting service:

```swift
lazy var generalRequestAdaptingService: RequestAdaptingServiceProtocol = {
   return RequestAdaptingService(requestAdapters: [GeneralRequestAdapter()]) 
}()

// Use request adapting in ProfileService
lazy var profileService: ProfileServiceProtocol = {
    return ProfileService(requestAdaptingService: generalRequestAdaptingService)  
}()
```

In this way all requests sent from `ProfileService` will be adapted using `DeviceInfoRequestAdapter`.

**Notes:**
- You able to use multiple request adapters, they will be executed in passed array's order.  
- You can use only one instance of `RequestAdaptingService` per `NetworkService` instance.

### Error handling

You able to provide custom error handling for failed requests.  
For example, you can log errors or refresh auth token and retry request using error handlers.  
   
First you need to create your own error handler and implement `ErrorHandler` protocol:

```swift
import Networking

final class LoggingErrorHandler: ErrorHandler {
    
    func canHandleError<T>(_ error: RequestError<T>) -> Bool {
        return true
    }
    
    func handleError<T>(_ error: RequestError<T>, completion: @escaping (ErrorHandlingResult) -> Void) {
        print("Request failure at: \(error.endpoint.path)")
        print("Error: \(error.underlyingError)")
        print("Response: \(error.response)")
        
        // Once error handled you have to call completion handler
        // Supported error handling results:
        // - `continueFailure(with: Error)` - request will be failed with passed error
        // - `retryNeeded` - request will be retried without failure
        completion(.continueFailure(with: error.underlyingError))
    }
}
```

Then initialize `NetworkService` subclass with your error handling service:

```swift
lazy var generalErrorHandlingService: ErrorHandlingServiceProtocol = {
   return ErrorHandlingService(errorHandlers: [LoggingErrorHandler()]) 
}()

// Use error handling service in ProfileService
lazy var profileService: ProfileServiceProtocol = {
    return ProfileService(errorHandlingService: generalRequestAdaptingService)  
}()
```

**Notes:**
- You able to use multiple error handlers. 
**Important**: with multiple error handlers will be used first appropriate error handler (which can handle error).
- Similar to request adapting, you can use only one instance of `ErrorHandlingService` per `NetworkService` instance.

### Automatic token refreshing and request retrying

`Networking` can automatically handle "unauthorized" errors with 401 status code.   
This feature provides automatic token refreshing and retrying failed requests.

#### Usage

First you need create your own session service and implement `Networking.SessionServiceProtocol`:

```swift
import Networking

protocol SessionServiceProtocol: Networking.SessionServiceProtocol {
    
    func logout()
}

final class SessionService: SessionServiceProtocol, NetworkService {
    
    var authToken: String? {
        // Returns your current auth token
        return "token"
    }
    
    func logout() {
        /* ... */
    }
    
    func refreshAuthToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        // Add your logic for token refreshing
        // Finally call completion handler
    }
}

```

Then you need to configure your request adapting and error handling services:
* Add `TokenRequestAdapter` for your instance of `RequestAdaptingService`
* Add `UnauthorizedErrorHandler` for your instance of `ErrorHandlingService`
* Add request adapting service, error handling service for your `NetworkService` subclass 

```swift
lazy var sessionService: SessionServiceProtocol = {
    return SessionService()    
}()

lazy var requestAdaptingService: RequestAdaptingServiceProtocol = {
    let tokenRequestAdapter = TokenRequestAdapter(sessionService: sessionService)  
    return RequestAdaptingService(requestAdapters: [tokenRequestAdapter])
}()

lazy var errorHandlingService: ErrorHandlingServiceProtocol = {
    let unauthorizedErrorHandler = UnauthorizedErrorHandler(sessionService: sessionService)  
    return ErrorHandlingService(errorHandlers: [unauthorizedErrorHandler])
}()

lazy var profileService: ProfileServiceProtocol = {
    return ProfileService(requestAdaptingService: requestAdaptingService, errorHandlingService: errorHandlingService)
}()
```


To learn more, please check example project.
