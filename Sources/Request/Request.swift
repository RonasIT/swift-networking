//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

protocol Request: BasicRequest, AdaptiveRequest, Cancellable, Retryable {

    typealias Completion<T> = (DataResponse<T>) -> Void
    typealias ResponseSerializer = DataResponseSerializerProtocol

    func response<Serializer: ResponseSerializer>(queue: DispatchQueue?,
                                                  responseSerializer: Serializer,
                                                  completion: @escaping Completion<Serializer.SerializedObject>)
}
