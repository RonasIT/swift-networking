#  Networking

Wrapper for [Alamofire](https://github.com/Alamofire/Alamofire) with convenient mechanism of error handling and parsing of response, based on usage of Swift generics and `Codable` protocol.

## Features

* `Endpoints` support
* `Codable` support
* `Generics` support
* Flexible error handling

## Usage

### Making a Request

To implement requests with specific endpoint you need to subclass `NetworkService` and define request methods:


```swift
import Networking

final class ApiService: NetworkService, ApiServiceProtocol {

    @discardableResult
    func fetchSlideshow(success: @escaping (Slideshow) -> Void, failure: Failure?) -> Request<GeneralResponse>? {
        return request(for: AnythingEndpoint.fetchSlideshow, success: { (result: SlideshowResponse) in
            success(result.slideshow)
        }, failure: { error in
            failure?(error)
        })
    }
}

```

### Cancelling request

Any request can be cancelled:

```swift
request.cancel()
```

### Parsing response

Responce parsing is provided with `Codable` like this:

```swift
class SlideshowResponse: Codable {
    let slideshow: Slideshow
}

class Slideshow: Codable {
    let author: String
    let date: String
    let slides: [Slide]
    let title: String
}

class Slide: Codable {
    let title: String
    let type: String
    let items: [String]?
}
```

When `Codable` protocol is implemented, data is automatically parsed to the model.

### Error handling

`NetworkService` has default error handler:

```swift
var errorHandlers: [ErrorHandler] = [GeneralErrorHandler()]
```

Also you can set your custom error handlers to this property by implementing protocol `ErrorHandler`. This protocol contains just one method:

```swift
func handle<T>(error: inout Error, for response: DataResponse<T>?, endpoint: Endpoint) -> Bool
```

To learn more, please download example project from this repo.