//
//  Created by Dmitry Frishbuter on 10/10/2018.
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import UIKit

final class SlideCollectionViewCell: UICollectionViewCell {

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .cyan
        contentView.addSubview(titleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        let size = titleLabel.sizeThatFits(contentView.bounds.size)
        let origin = CGPoint(x: (contentView.bounds.width - size.width) / 2, y: (contentView.bounds.height - size.height) / 2)
        titleLabel.frame = CGRect(origin: origin, size: size)
    }
}
