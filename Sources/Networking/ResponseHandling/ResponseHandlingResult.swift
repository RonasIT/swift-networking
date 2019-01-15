//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public enum ResponseHandlingResult<T> {
    case success(T)
    case failure(Error)
}
