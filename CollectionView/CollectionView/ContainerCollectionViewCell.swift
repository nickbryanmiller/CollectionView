// Created by Nicholas Miller on 5/26/19.
// Copyright © 2019 nickbryanmiller. All rights reserved.

import UIKit

public final class ContainerCollectionViewCell: UICollectionViewCell {
	override init(frame: CGRect) {
		super.init(frame: .zero)
		print("created")
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var content: UIView? {
		didSet {
			content?.removeFromSuperview()
			guard let content = content else { return }
			addSubview(content)
			content.translatesAutoresizingMaskIntoConstraints = false
			content.constrainToSuperview()
		}
	}
}
