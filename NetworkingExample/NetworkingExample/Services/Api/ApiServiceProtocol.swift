//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Networking

protocol HasApiService {

    var apiService: ApiServiceProtocol { get }
}

protocol ApiServiceProtocol {

    @discardableResult
    func fetchSlideshow(success: @escaping (Slideshow) -> Void, failure: @escaping Failure) -> CancellableRequest

    @discardableResult
    func postContact(_ contact: Contact, success: @escaping (Contact) -> Void, failure: @escaping Failure) -> CancellableRequest
}
