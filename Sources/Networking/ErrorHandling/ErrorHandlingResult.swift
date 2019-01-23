//
// Created by Nikita Zatsepilov on 2019-01-16.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public enum ErrorHandlingResult {
    case continueFailure(with: Error)
    case continueErrorHandling(with: Error)
    case retryNeeded
}
