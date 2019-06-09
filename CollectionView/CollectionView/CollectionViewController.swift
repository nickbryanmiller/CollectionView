// Created by Nicholas Miller on 5/26/19.
// Copyright © 2019 nickbryanmiller. All rights reserved.

import UIKit

open class CollectionViewController: UIViewController {

  // MARK: Lifecycle

  public init(
    scrollDirection: UICollectionView.ScrollDirection,
    shouldSnapItemsToBounds: Bool = false,
    itemLayoutBehavior: CollectionView.ItemLayoutBehavior = .insetFromBoundsByItemSpacing)
  {
    collectionView = CollectionView(
      scrollDirection: scrollDirection,
      shouldSnapItemsToBounds: shouldSnapItemsToBounds,
      itemLayoutBehavior: itemLayoutBehavior)
    super.init(nibName: nil, bundle: nil)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
	
	open override func loadView() {
		self.view = collectionView
	}

  // MARK: Public

  public let collectionView: CollectionView

}
