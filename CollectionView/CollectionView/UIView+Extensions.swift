// Created by Nicholas Miller on 5/26/19.
// Copyright © 2019 nickbryanmiller. All rights reserved

import UIKit

public extension UIView {
	func constrainToSuperview() {
		guard let superview = superview else { return }
		leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
		trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
		topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
		bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
	}
}
