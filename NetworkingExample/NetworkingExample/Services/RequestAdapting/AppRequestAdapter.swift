//
// Created by Nikita Zatsepilov on 2019-01-24.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking
import UIKit.UIDevice

final class AppRequestAdapter: RequestAdapter {

    func adapt(_ request: AdaptiveRequest) {
        request.appendHeader(RequestHeaders.dpi(scale: UIScreen.main.scale))
        if let appInfo = Bundle.main.infoDictionary,
           let appVersion = appInfo["CFBundleShortVersionString"] as? String {
            let header = RequestHeaders.userAgent(osVersion: UIDevice.current.systemVersion, appVersion: appVersion)
            request.appendHeader(header)
        }
    }
}
