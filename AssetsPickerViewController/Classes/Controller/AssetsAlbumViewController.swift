//
//  AssetsAlbumViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import Photos
import TinyLog
import PureLayout

// MARK: - AssetsAlbumViewController
open class AssetsAlbumViewController: UIViewController {
    
    let cellReuseIdentifier: String = UUID().uuidString
    let headerReuseIdentifier: String = UUID().uuidString
    
    var cellType: AnyClass = AssetsAlbumCell.classForCoder()
    let defaultSpace: CGFloat = { return 20 }()
    lazy var cellWidth: CGFloat = {
        let deviceSize = UIScreen.main.bounds.size
        return (deviceSize.width - 3 * self.defaultSpace) / 2
    }()
    var interitemSpace: CGFloat { return self.defaultSpace }
    
    lazy var cancelButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: String(key: "Cancel"), style: .plain, target: self, action: #selector(pressedCancel(button:)))
        return buttonItem
    }()
    
    lazy var viewModel: AssetsAlbumViewModelProtocol = {
        let vm = AssetsAlbumViewModel()
        vm.delegate = self
        return vm
    }()
    
    var didSetupConstraints = false
    
    lazy var collectionView: UICollectionView = {
        
        let flowLayout = AssetsAlbumLayout()
        
        flowLayout.scrollDirection = .vertical
        
        let view = UICollectionView(frame: self.view.bounds, collectionViewLayout: flowLayout)
        view.configureForAutoLayout()
        view.register(AssetsAlbumCell.classForCoder(), forCellWithReuseIdentifier: self.cellReuseIdentifier)
        view.register(AssetsAlbumHeaderView.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: self.headerReuseIdentifier)
        view.backgroundColor = UIColor.clear
        view.dataSource = self
        view.delegate = self
        if #available(iOS 10.0, *) {
            view.prefetchDataSource = self
        }
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = true
        view.decelerationRate = UIScrollViewDecelerationRateFast
        view.contentInset = UIEdgeInsets(top: self.defaultSpace, left: self.defaultSpace, bottom: self.defaultSpace, right: self.defaultSpace)
        return view
    }()
    
    public convenience init(cellType: AnyClass) {
        self.init()
        self.cellType = cellType
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    open func commonInit() {}
    
    deinit { logd("Released \(type(of: self))") }
    
    open override func loadView() {
        super.loadView()
        view = UIView()
        view.backgroundColor = .white
        
        view.addSubview(collectionView)
        view.setNeedsUpdateConstraints()
        
        viewModel.start()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupCommon()
        setupBarButtonItems()
    }
    
    open override func updateViewConstraints() {
        super.updateViewConstraints()
        
        if !didSetupConstraints {
            collectionView.autoPinEdgesToSuperviewEdges()
            didSetupConstraints = true
        }
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - Initial Setups
extension AssetsAlbumViewController {
    open func setupCommon() {
        title = String(key: "Title_Albums")
        view.backgroundColor = .white
    }
    
    open func setupBarButtonItems() {
        navigationItem.leftBarButtonItem = cancelButtonItem
    }
}

// MARK: - UICollectionViewDelegate
extension AssetsAlbumViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}

// MARK: - UICollectionViewDataSource
extension AssetsAlbumViewController: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int { return viewModel.numberOfSections }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems(inSection: section)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        guard let albumCell = cell as? AssetsAlbumCell else {
            logw("Failed to cast UICollectionViewCell.")
            return cell
        }
        return albumCell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as? AssetsAlbumHeaderView else {
            logw("Failed to cast AssetsAlbumHeaderView.")
            return AssetsAlbumHeaderView()
        }
        headerView.setNeedsUpdateConstraints()
        headerView.updateConstraintsIfNeeded()
        return headerView
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        logi("[\(indexPath.section)][\(indexPath.row)]")
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AssetsAlbumViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height: cellWidth * 1.25)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return defaultSpace
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return defaultSpace
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if viewModel.numberOfSections - 1 == section {
            return CGSize(width: collectionView.frame.size.width, height: 60)
        } else {
            return .zero
        }
    }
}

// MARK: - UICollectionViewDataSourcePrefetching
extension AssetsAlbumViewController: UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        
    }
}

// MARK: - UI Event Handlers
extension AssetsAlbumViewController {
    
    func pressedCancel(button: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - AssetsViewModelDelegate
extension AssetsAlbumViewController: AssetsAlbumViewModelDelegate {
    
    public func assetsAlbumViewModel(viewModel: AssetsAlbumViewModel, createdSection section: Int) {
        if section > 0 {
            collectionView.insertSections(IndexSet(integer: section))
        }
        collectionView.reloadSections(IndexSet(integer: section))
    }
    
    public func assetsAlbumViewModel(viewModel: AssetsAlbumViewModel, removedAlbums: [PHAssetCollection], at indexPaths: [IndexPath]) {
        
    }
    
    public func assetsAlbumViewModel(viewModel: AssetsAlbumViewModel, removedSection section: Int) {
        
    }
    
    public func assetsAlbumViewModel(viewModel: AssetsAlbumViewModel, addedAlbums: [PHAssetCollection], at indexPaths: [IndexPath]) {
        
    }
}

