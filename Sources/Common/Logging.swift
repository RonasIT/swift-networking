//
// Created by Nikita Zatsepilov on 2019-02-07.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import os.log

enum LogCategory {
    case requestAdapting
    case request
    case accessTokenRefreshing
    case errorHandling

    private var name: String {
        switch self {
        case .requestAdapting:
            return "Request adapting"
        case .request:
            return "Request"
        case .accessTokenRefreshing:
            return "Access token refreshing"
        case .errorHandling:
            return "Error handling"
        }
    }

    fileprivate func makeLog() -> OSLog {
        return OSLog(subsystem: Logging.Constants.subsystem, category: name)
    }
}

enum LogType {
    case `default`
    case info
    case debug
    case error
    case fault

    var osLogType: OSLogType {
        switch self {
        case .info:
            return .info
        case .debug:
            return .debug
        case .default:
            return .default
        case .error:
            return .error
        case .fault:
            return .fault
        }
    }
}

public enum Logging {

    public static var isEnabled: Bool = false

    fileprivate enum Constants {
        static let subsystem: String = "com.ronas-it.networking"
    }

    private static var logs: [LogCategory: OSLog] = [:]

    static func log(type: LogType, category: LogCategory, _ message: String) {
        guard isEnabled else {
            return
        }

        var format: StaticString
        switch type {
        case .info, .default:
            format = "⚪ %@"
        case .debug:
            format = "🔵 %@"
        case .error:
            format = "🔴️ %@"
        case .fault:
            format = "❌ %@"
        }
        os_log(format, log: osLog(for: category), type: type.osLogType, message)
    }

    // MARK: - Private

    private static func osLog(for category: LogCategory) -> OSLog {
        guard let log = logs[category] else {
            let log = category.makeLog()
            logs[category] = log
            return log
        }
        return log
    }
}
