//
//  AssetsAlbumViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import Photos

// MARK: - AssetsAlbumViewControllerDelegate
public protocol AssetsAlbumViewControllerDelegate {
    func assetsAlbumViewControllerCancelled(controller: AssetsAlbumViewController)
    func assetsAlbumViewController(controller: AssetsAlbumViewController, selected album: PHAssetCollection)
}

// MARK: - AssetsAlbumViewController
open class AssetsAlbumViewController: UIViewController {
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return AssetsPickerConfig.statusBarStyle
    }
    
    open var delegate: AssetsAlbumViewControllerDelegate?
    
    var pickerConfig: AssetsPickerConfig!
    
    let cellReuseIdentifier: String = UUID().uuidString
    let headerReuseIdentifier: String = UUID().uuidString
    let fetchService = AssetsFetchService()
    
    lazy var cancelButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                         target: self,
                                         action: #selector(pressedCancel(button:)))
        return buttonItem
    }()
    
    lazy var collectionView: UICollectionView = {
        
        let isPortrait = UIApplication.shared.statusBarOrientation.isPortrait
        
        let layout = AssetsAlbumLayout()
        self.updateLayout(layout: layout, isPortrait: isPortrait)
        layout.scrollDirection = .vertical
        
        let defaultSpace = self.pickerConfig.albumDefaultSpace
        let itemSpace = self.pickerConfig.albumItemSpace(isPortrait: isPortrait)
        let view = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        view.register(self.pickerConfig.albumCellType, forCellWithReuseIdentifier: self.cellReuseIdentifier)
        view.register(AssetsAlbumHeaderView.classForCoder(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: self.headerReuseIdentifier)
        view.contentInset = UIEdgeInsets(top: defaultSpace, left: itemSpace, bottom: defaultSpace, right: itemSpace)
        view.backgroundColor = UIColor.clear
        view.dataSource = self
        view.delegate = self
        if #available(iOS 10.0, *) {
            view.prefetchDataSource = self
        }
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = true
        
        return view
    }()
    
    fileprivate lazy var loadingActivityIndicatorView: UIActivityIndicatorView = {
        
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                let indicator = UIActivityIndicatorView(style: .whiteLarge)
                return indicator
            } else {
                let indicator = UIActivityIndicatorView(style: .large)
                return indicator
            }
        } else {
            let indicator = UIActivityIndicatorView()
            return indicator
        }
    }()
    fileprivate lazy var loadingPlaceholderView: UIView = UIView()
    
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
		view.backgroundColor = .ap_background
        
        view.addSubview(collectionView)
        view.addSubview(loadingPlaceholderView)
        view.addSubview(loadingActivityIndicatorView)
        
        AssetsManager.shared.subscribe(subscriber: self)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupCommon()
        setupBarButtonItems()
        
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }

        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        let isFetchedAlbums = AssetsManager.shared.isFetchedAlbums
        if isFetchedAlbums {
            loadingActivityIndicatorView.stopAnimating()
            loadingPlaceholderView.isHidden = true
        } else {
            loadingActivityIndicatorView.startAnimating()
            loadingPlaceholderView.isHidden = false
        }
        
        if #available(iOS 13.0, *) {
            loadingPlaceholderView.backgroundColor = .systemBackground
        } else {
            loadingPlaceholderView.backgroundColor = .white
        }
        loadingPlaceholderView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        loadingActivityIndicatorView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: collectionView, animation: { (context) in
            let isPortrait = size.height > size.width
            let space = self.pickerConfig.albumItemSpace(isPortrait: isPortrait)
            let insets = self.collectionView.contentInset
            self.collectionView.contentInset = UIEdgeInsets(top: insets.top, left: space, bottom: insets.bottom, right: space)
            self.updateLayout(layout: self.collectionView.collectionViewLayout, isPortrait: isPortrait)
        }) { (_) in
        }
    }
}

// MARK: - Internal APIs for UI
extension AssetsAlbumViewController {
    func setupCommon() {
        title = String(key: "Title_Albums")
        view.backgroundColor = .ap_background
    }
    
    func setupBarButtonItems() {
        navigationItem.leftBarButtonItem = cancelButtonItem
    }
    
    func updateLayout(layout: UICollectionViewLayout?, isPortrait: Bool) {
        if let flowLayout = layout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = isPortrait ? pickerConfig.albumPortraitCellSize : pickerConfig.albumLandscapeCellSize
            flowLayout.minimumLineSpacing = pickerConfig.albumDefaultSpace
            flowLayout.minimumInteritemSpacing = pickerConfig.albumItemSpace(isPortrait: isPortrait)
            logi("flowLayout: itemSize=\(flowLayout.itemSize), minimumInteritemSpacing=\(flowLayout.minimumInteritemSpacing)")
        }
    }
}

// MARK: - UICollectionViewDelegate
extension AssetsAlbumViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if LogConfig.isAlbumCellLogEnabled { logi("[\(indexPath.section)][\(indexPath.row)]") }
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
        if LogConfig.isAlbumCellLogEnabled { logi("\(count)") }
        return count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = AssetsManager.shared.numberOfAlbums(inSection: section)
        if LogConfig.isAlbumCellLogEnabled { logi("numberOfItemsInSection[\(section)]: \(count)") }
        return count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if LogConfig.isAlbumCellLogEnabled { logi("cellForItemAt[\(indexPath.section)][\(indexPath.row)]") }
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
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as? AssetsAlbumHeaderView else {
            logw("Failed to cast AssetsAlbumHeaderView.")
            return AssetsAlbumHeaderView()
        }
        headerView.setNeedsUpdateConstraints()
        headerView.updateConstraintsIfNeeded()
        return headerView
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard var albumCell = cell as? AssetsAlbumCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return
        }
        albumCell.album = AssetsManager.shared.album(at: indexPath)
        albumCell.titleText = AssetsManager.shared.title(at: indexPath)
        albumCell.count = AssetsManager.shared.numberOfAssets(at: indexPath)
        
        if LogConfig.isAlbumCellLogEnabled { logi("[\(indexPath.section)][\(indexPath.row)] willDisplay[\(albumCell.titleText ?? "")]") }
        
        fetchService.cancelFetching(at: indexPath)
        if let requestId = AssetsManager.shared.imageOfAlbum(at: indexPath, size: pickerConfig.albumCacheSize, isNeedDegraded: true, completion: { (image) in
            if let image = image {
                if LogConfig.isAlbumImageSizeLogEnabled {
                    //logi("[\(indexPath.section)][\(indexPath.row)] \(albumCell.titleText ?? ""): imageSize: \(image.size)")
                }
                if let _ = albumCell.imageView.image {
                    UIView.transition(
                        with: albumCell.imageView,
                        duration: 0.20,
                        options: .transitionCrossDissolve,
                        animations: {
                            albumCell.imageView.image = image
                    },
                        completion: nil
                    )
                } else {
                    albumCell.imageView.image = image
                }
            } else {
                albumCell.imageView.image = nil
            }
        }) {
            fetchService.registerFetching(requestId: requestId, at: indexPath)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        fetchService.cancelFetching(at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let albumCell = collectionView.cellForItem(at: indexPath) as? AssetsAlbumCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return false
        }
        albumCell.imageView.dmr_dim(animated: false, color: .ap_label, alpha: 0.5)
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let albumCell = collectionView.cellForItem(at: indexPath) as? AssetsAlbumCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return
        }
        albumCell.imageView.dmr_undim()
    }
}

extension AssetsAlbumViewController: UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        var assets = [PHAsset]()
        for albumIndexPath in indexPaths {
            let album = AssetsManager.shared.album(at: albumIndexPath)
            if let asset = AssetsManager.shared.fetchResult(forAlbum: album)?.lastObject {
                assets.append(asset)
            }
        }
        if assets.count > 0 {
            AssetsManager.shared.cache(assets: assets, size: pickerConfig.albumCacheSize)
            if LogConfig.isAlbumCellLogEnabled { logi("Caching album images at \(indexPaths)") }
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
                return CGSize(width: collectionView.bounds.width, height: pickerConfig.assetLandscapeCellSize(forViewSize: collectionView.bounds.size).width * 2/3)
            } else {
                return CGSize(width: collectionView.bounds.width, height: pickerConfig.assetPortraitCellSize(forViewSize: collectionView.bounds.size).width * 2/3)
            }
        }
        return .zero
    }
}

// MARK: - UI Event Handlers
extension AssetsAlbumViewController {
    
    @objc func pressedCancel(button: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: {
            AssetsManager.shared.unsubscribe(subscriber: self)
        })
        delegate?.assetsAlbumViewControllerCancelled(controller: self)
    }
    
    @objc func pressedSearch(button: UIBarButtonItem) {
        
    }
}

// MARK: - AssetsManagerDelegate
extension AssetsAlbumViewController: AssetsManagerDelegate {
    
    public func assetsManagerFetched(manager: AssetsManager) {
        collectionView.reloadData()
        let isFetchedAlbums = AssetsManager.shared.isFetchedAlbums
        if isFetchedAlbums {
            loadingActivityIndicatorView.stopAnimating()
            loadingPlaceholderView.isHidden = true
        } else {
            loadingActivityIndicatorView.startAnimating()
            loadingPlaceholderView.isHidden = false
        }
    }
    
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
