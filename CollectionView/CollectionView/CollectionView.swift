// Created by Nicholas Miller on 5/26/19.
// Copyright © 2019 nickbryanmiller. All rights reserved.

import UIKit

private class CollectionViewFlowLayout: UICollectionViewFlowLayout {

  override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
    guard
      let collectionView = collectionView as? CollectionView,
      collectionView.shouldSnapItemsToBounds,
      let firstIndexPath = collectionView.sequentialIndexPathsForVisibleItems.first,
      let firstCell = collectionView.cellForItem(at: firstIndexPath) as? ContainerCollectionViewCell,
      let firstView = firstCell.content
      else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity) }

    let firstViewFrame = collectionView.convert(firstView.frame, from: firstView.superview)

    let willFallBackToLastView = proposedContentOffset.x < firstViewFrame.midX
    let firstViewFrameX = willFallBackToLastView ? firstViewFrame.minX : firstViewFrame.maxX

    collectionView.decelerationRate =
      willFallBackToLastView && abs(velocity.x) > 3
      ? UIScrollView.DecelerationRate.normal
      : UIScrollView.DecelerationRate.fast

    var minimumSpacing: CGFloat
    switch collectionView.itemLayoutBehavior {
    case .insetFromBoundsByItemSpacing:
      minimumSpacing = willFallBackToLastView ? -collectionView.horizontalItemSpacing : 0.0
    case .fillBounds:
      minimumSpacing = willFallBackToLastView ? 0.0 : collectionView.horizontalItemSpacing
    }
    return CGPoint(x: firstViewFrameX + minimumSpacing, y: proposedContentOffset.y)
  }
}

public class CollectionView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

  // MARK: Lifecycle

  public init(
    scrollDirection: UICollectionView.ScrollDirection,
    shouldSnapItemsToBounds: Bool = false,
    itemLayoutBehavior: ItemLayoutBehavior = .insetFromBoundsByItemSpacing)
  {
    self.shouldSnapItemsToBounds = shouldSnapItemsToBounds
    self.itemLayoutBehavior = itemLayoutBehavior
    flowLayout = CollectionViewFlowLayout()
    flowLayout.scrollDirection = scrollDirection
    super.init(frame: CGRect.zero, collectionViewLayout: flowLayout)
    translatesAutoresizingMaskIntoConstraints = false
    setUpSelf()
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Public

  public struct ViewData {
    let view: UIView
    let dataItem: Any
    let section: CollectionSectionProtocol
  }

  @available(*, unavailable, message:"set shouldSnapItemsToBounds instead")
  public override var isPagingEnabled: Bool {
    get { return false }
    set { }
  }

  public var shouldUseDefaultItemSize: Bool = true
  public var numberOfItemsInWidth: Int = 1 {
    didSet { shouldUseDefaultItemSize = false }
  }
  public var numberOfItemsInHeight: Int = 1 {
    didSet { shouldUseDefaultItemSize = false }
  }

  /// The item layout behavior determines how item spacing is factored into
  /// calculating the size of items based on how many items should fit on screen
  public enum ItemLayoutBehavior {
    /// Items will be sized large enough so that the items at each edge
    /// will touch the bounds of the collection view
    case fillBounds

    /// Items will be sized small enough so that the items at each edge are an
    /// item spacing distance away from the bounds of the collection view.
    case insetFromBoundsByItemSpacing
  }

  public var horizontalItemSpacing: CGFloat {
    get {
			switch flowLayout.scrollDirection {
			case .vertical: return flowLayout.minimumInteritemSpacing
			case .horizontal: return flowLayout.minimumLineSpacing
			@unknown default:
				fatalError("unknown scrollDirection")
			}
    }
    set {
      switch flowLayout.scrollDirection {
      case .vertical: flowLayout.minimumInteritemSpacing = newValue
      case .horizontal: flowLayout.minimumLineSpacing = newValue
			@unknown default:
				fatalError("unknown scrollDirection")
      }
      setCollectionViewLayout(flowLayout, animated: false)
    }
  }

  public var verticalItemSpacing: CGFloat {
    get {
			switch flowLayout.scrollDirection {
			case .vertical: return flowLayout.minimumLineSpacing
			case .horizontal: return flowLayout.minimumInteritemSpacing
			@unknown default:
				fatalError("unknown scrollDirection")
			}
    }
    set {
      switch flowLayout.scrollDirection {
      case .vertical: flowLayout.minimumLineSpacing = newValue
      case .horizontal: flowLayout.minimumInteritemSpacing = newValue
			@unknown default:
				fatalError("unknown scrollDirection")
			}
      setCollectionViewLayout(flowLayout, animated: false)
    }
  }

  public var sectionInset: UIEdgeInsets {
    get { return flowLayout.sectionInset }
    set {
      flowLayout.sectionInset = newValue
      setCollectionViewLayout(flowLayout, animated: false)
    }
  }

  public var collectionViewDidScrollBlock: ((CollectionView) -> Void)?

  public var visibleViewsWithData: [ViewData] {
    var viewDataItems: [ViewData] = []
    for indexPath in sequentialIndexPathsForVisibleItems {
      let section = sections[indexPath.section]
      if let cell = cellForItem(at: indexPath) as? ContainerCollectionViewCell,
        let view = cell.content
      {
        let dataItem = section.dataItem(atIndex: indexPath.row)
        let viewData = ViewData(view: view, dataItem: dataItem, section: section)
        viewDataItems.append(viewData)
      }
    }
    return viewDataItems
  }

  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    return sections.count
  }

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return sections.count == 0 ? 0 : sections[section].count
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  {
    let section = sections[indexPath.section]
    guard
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: section.reuseIdentifier,
        for: indexPath) as? ContainerCollectionViewCell
      else {
        return UICollectionViewCell()
    }

    if cell.content == nil {
      cell.content = section.createViewBlock(atItemIndex: indexPath.row)
    }
    if let content = cell.content {
      section.configure(view: content, atItemIndex: indexPath.row)
    }

    return cell
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath) -> CGSize
  {
    if shouldUseDefaultItemSize { return flowLayout.itemSize }

    let numberOfSpacesInWidth = itemLayoutBehavior == .fillBounds ? numberOfItemsInWidth - 1 : numberOfItemsInWidth + 1
    let totalHorizontalSpacing = CGFloat(numberOfSpacesInWidth) * horizontalItemSpacing
    let itemWidth: CGFloat = (bounds.width - totalHorizontalSpacing) / CGFloat(numberOfItemsInWidth)

    let numberOfSpacesInHeight = itemLayoutBehavior == .fillBounds ? numberOfItemsInHeight - 1 : numberOfItemsInHeight + 1
    let totalVerticalSpacing = CGFloat(numberOfSpacesInHeight) * verticalItemSpacing
    let itemHeight: CGFloat = (bounds.height - totalVerticalSpacing) / CGFloat(numberOfItemsInHeight)

    return CGSize(width: itemWidth, height: itemHeight)
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    willDisplay cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath)
  {
    sections[indexPath.section].didScroll(toItemAtIndex: indexPath.row)
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    didEndDisplaying cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath)
  {
    guard
      let cell = cell as? ContainerCollectionViewCell,
      let content = cell.content
      else { return }
    sections[indexPath.section].didEndDisplayingViewHandler(view: content)
  }

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    collectionViewDidScrollBlock?(self)
  }

  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    for indexPath in indexPathsForVisibleItems {
      sections[indexPath.section].didScroll(toItemAtIndex: indexPath.row)
    }
  }

  @discardableResult
  public func scrollToItemInSection<DataType, View: UIView>(
    _ section: CollectionSection<DataType, View>,
    to position: UICollectionView.ScrollPosition,
    where predicate: ((DataType) -> Bool)? = nil,
    animated: Bool = false) -> DataType?
  {
    guard let indexPath = indexPathForItemInSection(section, where: predicate) else { return nil }
    scrollToItem(at: indexPath, at: position, animated: animated)
    return section.data[indexPath.row]
  }

  @discardableResult
  public func addSection<DataType, View: UIView>(
    createViewBlock: @escaping () -> View,
    configViewBlock: @escaping (View, DataType) -> Void,
    data: [DataType]) -> CollectionSection<DataType, View>
  {
    let section = CollectionSection(
      createViewBlock: createViewBlock,
      configViewBlock: configViewBlock,
      data: data)
    register(ContainerCollectionViewCell.self, forCellWithReuseIdentifier: section.reuseIdentifier)
    sections.append(section)
    return section
  }

  public func setDidScrollToItemHandler<DataType, View>(
    forSection section: CollectionSection<DataType, View>,
    handler: @escaping ((DataType) -> Void))
  {
    section.didScrollToItemHandler = handler
  }

  public func setDidEndDisplayingViewHandler<DataType, View>(
    forSection section: CollectionSection<DataType, View>,
    handler: @escaping ((View) -> Void))
  {
    section.didEndDisplayingViewHandler = handler
  }

  // MARK: Private

  private let flowLayout: CollectionViewFlowLayout
  private var sections: [InternalCollectionSection] = []
  fileprivate let shouldSnapItemsToBounds: Bool
  fileprivate let itemLayoutBehavior: ItemLayoutBehavior

  private func setUpSelf() {
    delegate = self
    dataSource = self
    horizontalItemSpacing = 0.0
    verticalItemSpacing = 0.0
    sectionInset = UIEdgeInsets.zero
    decelerationRate = shouldSnapItemsToBounds ? UIScrollView.DecelerationRate.fast : UIScrollView.DecelerationRate.normal
  }

  private func indexPathForItemInSection<DataType, View: UIView>(
    _ section: CollectionSection<DataType, View>,
    where predicate: ((DataType) -> Bool)? = nil) -> IndexPath?
  {
    guard
			let sectionIndex = sections.firstIndex(where: { section.isEqualTo(section: $0) }),
      section.count > 0
      else { return nil }

    var itemIndex = 0
    if let predicate = predicate {
			guard let index = section.data.firstIndex(where: predicate) else { return nil }
      itemIndex = index
    }
    return IndexPath(row: itemIndex, section: sectionIndex)
  }

  fileprivate var sequentialIndexPathsForVisibleItems: [IndexPath] {
    // Apple does not put the indexpaths in sequential order
    return indexPathsForVisibleItems.sorted()
  }

}

public protocol CollectionSectionProtocol {
  // Note: Equatable leads down a rabbit hole
  func isEqualTo(section: CollectionSectionProtocol) -> Bool
}

private protocol InternalCollectionSection: CollectionSectionProtocol {
  var reuseIdentifier: String { get }
  var count: Int { get }
  func createViewBlock(atItemIndex index: Int) -> UIView
  func configure(view: UIView, atItemIndex index: Int)
  func didScroll(toItemAtIndex index: Int)
  func didEndDisplayingViewHandler(view: UIView)
  func dataItem(atIndex index: Int) -> Any
}

public class CollectionSection<DataType, View: UIView>: InternalCollectionSection {

  // MARK: Lifecycle

  fileprivate init(
    createViewBlock: @escaping () -> View,
    configViewBlock: @escaping (View, DataType) -> Void,
    data: [DataType])
  {
    self.createViewBlock = createViewBlock
    self.configViewBlock = configViewBlock
    self.data = data
    reuseIdentifier = String(describing: View.self)
  }

  // MARK: Pubilc

  public func isEqualTo(section: CollectionSectionProtocol) -> Bool {
    guard let section = section as? CollectionSection<DataType, View> else {
      return false
    }
    return section === self
  }

  // MARK: Private

  fileprivate let data: [DataType]
  private let createViewBlock: () -> View
  private let configViewBlock: (View, DataType) -> Void
  fileprivate let reuseIdentifier: String
  fileprivate var didScrollToItemHandler: ((DataType) -> Void)? = nil
  fileprivate var didEndDisplayingViewHandler: ((View) -> Void)? = nil

  fileprivate var count: Int {
    get { return data.count }
  }

  fileprivate func createViewBlock(atItemIndex index: Int) -> UIView {
    return createViewBlock()
  }

  fileprivate func configure(view: UIView, atItemIndex index: Int) {
    if let view = view as? View {
      configViewBlock(view, data[index])
    }
  }

  fileprivate func didScroll(toItemAtIndex index: Int) {
    didScrollToItemHandler?(data[index])
  }

  fileprivate func didEndDisplayingViewHandler(view: UIView) {
    if let view = view as? View {
      didEndDisplayingViewHandler?(view)
    }
  }

  fileprivate func dataItem(atIndex index: Int) -> Any {
    return data[index]
  }
}
