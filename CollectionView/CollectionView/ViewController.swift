// Created by Nicholas Miller on 5/26/19.
// Copyright © 2019 nickbryanmiller. All rights reserved.

import UIKit

class ViewController: CollectionViewController {
	
	// MARK: Lifecycle
	
	init() {
		super.init(scrollDirection: .vertical)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		print("did load")
		view.backgroundColor = .white
		setUpCollectionView()
	}
	
	private func setUpCollectionView() {
		collectionView.numberOfItemsInWidth = 3
		collectionView.numberOfItemsInHeight = 5
		
		collectionView.horizontalItemSpacing = 4.0
		collectionView.verticalItemSpacing = 4.0
		
		var data = [Int]()
		for i in 0...1000000 { data.append(i) }
		collectionView.addSection(
			createViewBlock: { return LabelView() },
			configViewBlock: { view, model in
				view.backgroundColor = model % 2 == 0 ? .red : .blue
				view.label.text = String(model)
			},
			data: data)
	}
}

final class LabelView: UIView {
	init() {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		
		setUpLabel()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public let label = UILabel(frame: .zero)
	
	private func setUpLabel() {
		label.textAlignment = .center
		label.baselineAdjustment = .alignCenters
		label.textColor = .white
		addSubview(label)
		label.translatesAutoresizingMaskIntoConstraints = false
		label.constrainToSuperview()
	}
}

