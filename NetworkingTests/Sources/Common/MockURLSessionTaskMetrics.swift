//
//  Created by Dmitry Frishbuter on 21.08.2020
//  Copyright © 2020 Ronas IT. All rights reserved.
//

import Foundation.NSURLSession

final class MockURLSessionTaskMetrics: URLSessionTaskMetrics {

    private let _taskInterval: DateInterval
    override var taskInterval: DateInterval {
        return _taskInterval
    }

    init(taskInterval: DateInterval) {
        _taskInterval = taskInterval
    }
}
