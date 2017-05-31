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
import OptionalTypes

// MARK: - AssetsAlbumViewControllerDelegate
public protocol AssetsAlbumViewControllerDelegate {
    func assetsAlbumViewControllerCancelled(controller: AssetsAlbumViewController)
    func assetsAlbumViewController(controller: AssetsAlbumViewController, selected album: PHAssetCollection)
}

// MARK: - AssetsAlbumViewController
open class AssetsAlbumViewController: UIViewController {
    
    open var delegate: AssetsAlbumViewControllerDelegate?
    
    var pickerConfig: AssetsPickerConfig!
    
    let cellReuseIdentifier: String = UUID().uuidString
    let headerReuseIdentifier: String = UUID().uuidString
    
    lazy var cancelButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: String(key: "Cancel"), style: .plain, target: self, action: #selector(pressedCancel(button:)))
        return buttonItem
    }()
    
    lazy var searchButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(pressedSearch(button:)))
        return buttonItem
    }()
    
    var didSetupConstraints = false
    
    lazy var collectionView: UICollectionView = {
        
        let isPortrait = UIApplication.shared.statusBarOrientation.isPortrait
        
        let layout = AssetsAlbumLayout()
        self.updateLayout(layout: layout, isPortrait: isPortrait)
        layout.scrollDirection = .vertical
        
        let defaultSpace = self.pickerConfig.albumDefaultSpace
        let itemSpace = self.pickerConfig.albumItemSpace(isPortrait: isPortrait)
        let view = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        view.configureForAutoLayout()
        view.register(self.pickerConfig.albumCellType, forCellWithReuseIdentifier: self.cellReuseIdentifier)
        view.register(AssetsAlbumHeaderView.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: self.headerReuseIdentifier)
        view.contentInset = UIEdgeInsets(top: defaultSpace, left: itemSpace, bottom: defaultSpace, right: itemSpace)
        view.backgroundColor = UIColor.clear
        view.dataSource = self
        view.delegate = self
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = true
        
        return view
    }()
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public init(pickerConfig: AssetsPickerConfig) {
        super.init(nibName: nil, bundle: nil)
        self.pickerConfig = pickerConfig
    }
    
    deinit { logd("Released \(type(of: self))") }
    
    open override func loadView() {
        super.loadView()
        view = UIView()
        view.backgroundColor = .white
        
        view.addSubview(collectionView)
        view.setNeedsUpdateConstraints()
        
        AssetsManager.shared.subscribe(subscriber: self)
        AssetsManager.shared.fetchAlbums { (_) in
            self.collectionView.reloadData()
        }
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
        let isPortrait = size.height > size.width
        let space = pickerConfig.albumItemSpace(isPortrait: isPortrait)
        let insets = collectionView.contentInset
        collectionView.contentInset = UIEdgeInsets(top: insets.top, left: space, bottom: insets.bottom, right: space)
        updateLayout(layout: collectionView.collectionViewLayout, isPortrait: isPortrait)
    }
}

// MARK: - Internal APIs for UI
extension AssetsAlbumViewController {
    func setupCommon() {
        title = String(key: "Title_Albums")
        view.backgroundColor = .white
    }
    
    func setupBarButtonItems() {
        navigationItem.leftBarButtonItem = cancelButtonItem
//        navigationItem.rightBarButtonItem = searchButtonItem
    }
    
    func updateLayout(layout: UICollectionViewLayout?, isPortrait: Bool) {
        if let flowLayout = layout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = isPortrait ? pickerConfig.albumPortraitCellSize : pickerConfig.albumLandscapeCellSize
            flowLayout.minimumLineSpacing = pickerConfig.albumDefaultSpace
            flowLayout.minimumInteritemSpacing = pickerConfig.albumItemSpace(isPortrait: isPortrait)
        }
    }
}

// MARK: - UICollectionViewDelegate
extension AssetsAlbumViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        log("[\(indexPath.section)][\(indexPath.row)]")
        dismiss(animated: true, completion: {
            AssetsManager.shared.unsubscribe(subscriber: self)
        })
        delegate?.assetsAlbumViewController(controller: self, selected: AssetsManager.shared.album(at: indexPath))
    }
}

// MARK: - UICollectionViewDataSource
extension AssetsAlbumViewController: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        let count = AssetsManager.shared.numberOfSections
        logi("\(count)")
        return count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = AssetsManager.shared.numberOfAlbums(inSection: section)
        logi("numberOfItemsInSection[\(section)] \(count)")
        return count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        guard let _ = cell as? AssetsAlbumCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return cell
        }
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        return cell
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
        log("willDisplay[\(indexPath.section)][\(indexPath.row)]")
        guard var albumCell = cell as? AssetsAlbumCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return
        }
        albumCell.album = AssetsManager.shared.album(at: indexPath)
        albumCell.titleText = AssetsManager.shared.title(at: indexPath)
        albumCell.count = AssetsManager.shared.numberOfAssets(at: indexPath)
        albumCell.imageView.image = nil
        AssetsManager.shared.imageOfAlbum(at: indexPath, size: pickerConfig.albumCacheSize, isNeedDegraded: false) { (image) in
            UIView.transition(
                with: albumCell.imageView,
                duration: 0.20,
                options: .transitionCrossDissolve,
                animations: { albumCell.imageView.image = image },
                completion: nil
            )
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AssetsAlbumViewController: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return pickerConfig.albumLineSpace
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return pickerConfig.albumItemSpace(isPortrait: collectionView.bounds.height > collectionView.bounds.width)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if collectionView.numberOfSections > 1 && AssetsManager.shared.numberOfAlbums(inSection: 1) > 0 && section == 1 {
            if collectionView.bounds.width > collectionView.bounds.height {
                return CGSize(width: collectionView.bounds.width, height: pickerConfig.assetLandscapeCellSize.width * 2/3)
            } else {
                return CGSize(width: collectionView.bounds.width, height: pickerConfig.assetPortraitCellSize.width * 2/3)
            }
        }
        return .zero
    }
}

// MARK: - UI Event Handlers
extension AssetsAlbumViewController {
    
    func pressedCancel(button: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: {
            AssetsManager.shared.unsubscribe(subscriber: self)
        })
        delegate?.assetsAlbumViewControllerCancelled(controller: self)
    }
    
    func pressedSearch(button: UIBarButtonItem) {
        
    }
}

// MARK: - AssetsManagerDelegate
extension AssetsAlbumViewController: AssetsManagerDelegate {
    
    public func assetsManager(manager: AssetsManager, authorizationStatusChanged oldStatus: PHAuthorizationStatus, newStatus: PHAuthorizationStatus) {}

    public func assetsManager(manager: AssetsManager, reloadedAlbumsInSection section: Int) {
        logi("reloadedAlbumsInSection section: \(section)")
        collectionView.reloadSections(IndexSet(integer: section))
    }
    
    public func assetsManager(manager: AssetsManager, insertedAlbums albums: [PHAssetCollection], at indexPaths: [IndexPath]) {
        logi("insertedAlbums at indexPaths: \(indexPaths)")
        collectionView.insertItems(at: indexPaths)
    }
    
    public func assetsManager(manager: AssetsManager, removedAlbums albums: [PHAssetCollection], at indexPaths: [IndexPath]) {
        logi("removedAlbums at indexPaths: \(indexPaths)")
        collectionView.deleteItems(at: indexPaths)
    }
    
    public func assetsManager(manager: AssetsManager, updatedAlbums albums: [PHAssetCollection], at indexPaths: [IndexPath]) {
        logi("updatedAlbums at indexPaths: \(indexPaths)")
        collectionView.reloadItems(at: indexPaths)
    }
    
    public func assetsManager(manager: AssetsManager, reloadedAlbum album: PHAssetCollection, at indexPath: IndexPath) {
        logi("reloadedAlbum at indexPath: \(indexPath)")
        collectionView.reloadItems(at: [indexPath])
    }
    
    public func assetsManager(manager: AssetsManager, insertedAssets assets: [PHAsset], at indexPaths: [IndexPath]) {}
    public func assetsManager(manager: AssetsManager, removedAssets assets: [PHAsset], at indexPaths: [IndexPath]) {}
    public func assetsManager(manager: AssetsManager, updatedAssets assets: [PHAsset], at indexPaths: [IndexPath]) {}
}
