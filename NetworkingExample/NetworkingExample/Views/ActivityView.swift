//
//  Created by Dmitry Frishbuter on 09/10/2018.
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import UIKit

final class ActivityView: UIView {

    private(set) lazy var indicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.style = .whiteLarge
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        addSubview(indicator)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        indicator.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }
}
