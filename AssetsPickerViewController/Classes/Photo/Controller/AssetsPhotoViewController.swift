//
//  AssetsPhotoViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import Photos
import TinyLog

// MARK: - AssetsPhotoViewController
open class AssetsPhotoViewController: UIViewController {
    
    open var cellType: AnyClass = AssetsPhotoCell.classForCoder()
    
    fileprivate let cellReuseIdentifier: String = UUID().uuidString
    fileprivate let footerReuseIdentifier: String = UUID().uuidString
    
    fileprivate lazy var cancelButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: String(key: "Cancel"), style: .plain, target: self, action: #selector(pressedCancel(button:)))
        return buttonItem
    }()
    fileprivate lazy var doneButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: String(key: "Done"), style: .plain, target: self, action: #selector(pressedDone(button:)))
        return buttonItem
    }()
    fileprivate let emptyView: AssetsEmptyView = {
        return AssetsEmptyView.newAutoLayout()
    }()
    fileprivate let noPermissionView: AssetsNoPermissionView = {
        return AssetsNoPermissionView.newAutoLayout()
    }()
    
    fileprivate var delegate: AssetsPickerViewControllerDelegate? {
        return (splitViewController as? AssetsPickerViewController)?.pickerDelegate
    }
    fileprivate var picker: AssetsPickerViewController! {
        return splitViewController as! AssetsPickerViewController
    }
    fileprivate var tapGesture: UITapGestureRecognizer?
    fileprivate var syncOffsetRatio: CGFloat = -1
    
    fileprivate var selectedArray = [PHAsset]()
    fileprivate var selectedMap = [String: PHAsset]()
    
    fileprivate var didSetupConstraints = false
    fileprivate var didSetInitialPosition: Bool = false
    
    fileprivate lazy var collectionView: UICollectionView = {
        
        let layout = AssetsPhotoLayout()
        self.updateLayout(layout: layout, isPortrait: UIApplication.shared.statusBarOrientation.isPortrait)
        layout.scrollDirection = .vertical
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.configureForAutoLayout()
        view.allowsMultipleSelection = true
        view.alwaysBounceVertical = true
        view.register(self.cellType, forCellWithReuseIdentifier: self.cellReuseIdentifier)
        view.register(AssetsPhotoFooterView.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: self.footerReuseIdentifier)
        view.contentInset = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
        view.backgroundColor = UIColor.clear
        view.dataSource = self
        view.delegate = self
        view.remembersLastFocusedIndexPath = true
        if #available(iOS 10.0, *) {
            view.prefetchDataSource = self
        }
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = true
        
        return view
    }()
    
    open override func loadView() {
        super.loadView()
        view = UIView()
        view.backgroundColor = .white
        view.addSubview(collectionView)
        view.addSubview(emptyView)
        view.addSubview(noPermissionView)
        view.setNeedsUpdateConstraints()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupCommon()
        setupBarButtonItems()
        updateEmptyView(count: 0)
        updateNoPermissionView()
        AssetsManager.shared.authorize { (isGranted) in
            self.updateNoPermissionView()
            if isGranted {
                self.setupAssets()
            } else {
                self.delegate?.assetsPickerCannotAccessPhotoLibrary(controller: self.picker)
            }
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didSetInitialPosition {
            let count = AssetsManager.shared.photoArray.count
            if count > 0 {
                if self.collectionView.collectionViewLayout.collectionViewContentSize.height > 0 {
                    let lastRow = self.collectionView.numberOfItems(inSection: 0) - 1
                    self.collectionView.scrollToItem(at: IndexPath(row: lastRow, section: 0), at: .bottom, animated: false)
                }
            }
            didSetInitialPosition = true
        }
    }
    
    open override func updateViewConstraints() {
        if !didSetupConstraints {
            collectionView.autoPinEdgesToSuperviewEdges()
            emptyView.autoPinEdgesToSuperviewEdges()
            noPermissionView.autoPinEdgesToSuperviewEdges()
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let photoLayout = collectionView.collectionViewLayout as? AssetsPhotoLayout {
            if let offset = photoLayout.translateOffset(forChangingSize: size, currentOffset: collectionView.contentOffset) {
                photoLayout.translatedOffset = offset
            }
            coordinator.animate(alongsideTransition: { (_) in
            }) { (_) in
                photoLayout.translatedOffset = nil
            }
        }
        updateLayout(layout: collectionView.collectionViewLayout, isPortrait: size.height > size.width)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupGestureRecognizer()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeGestureRecognizer()
    }
    
    deinit {
        logd("Released \(type(of: self))")
    }
}

// MARK: - Initial Setups
extension AssetsPhotoViewController {
    
    open func setupCommon() {
        view.backgroundColor = .white
    }
    
    open func setupBarButtonItems() {
        navigationItem.leftBarButtonItem = cancelButtonItem
        navigationItem.rightBarButtonItem = doneButtonItem
        doneButtonItem.isEnabled = false
    }
    
    open func setupAssets() {
        let manager = AssetsManager.shared
        manager.subscribe(subscriber: self)
        manager.fetchAlbums()
        manager.fetchPhotos() { photos in
            self.updateEmptyView(count: photos.count)
            if let selectedTitle = manager.selectedAlbum?.localizedTitle {
                self.title = selectedTitle
            } else {
                self.title = ""
            }
            self.collectionView.reloadData()
        }
    }
    
    open func setupGestureRecognizer() {
        if let _ = self.tapGesture {
            // ignore
        } else {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(pressedTitle))
            navigationController?.navigationBar.addGestureRecognizer(gesture)
            tapGesture = gesture
        }
    }
    
    open func removeGestureRecognizer() {
        if let tapGesture = self.tapGesture {
            navigationController?.navigationBar.removeGestureRecognizer(tapGesture)
            self.tapGesture = nil
        }
    }
}

// MARK: - Internal APIs for UI
extension AssetsPhotoViewController {
    
    func updateEmptyView(count: Int) {
        if emptyView.isHidden {
            if count == 0 {
                emptyView.isHidden = false
            }
        } else {
            if count > 0 {
                emptyView.isHidden = true
            }
        }
        logi("emptyView.isHidden: \(emptyView.isHidden), count: \(count)")
    }
    
    func updateNoPermissionView() {
        noPermissionView.isHidden = PHPhotoLibrary.authorizationStatus() == .authorized
        logi("isHidden: \(noPermissionView.isHidden)")
    }
    
    func updateLayout(layout: UICollectionViewLayout?, isPortrait: Bool) {
        if let flowLayout = layout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = isPortrait ? AssetsPhotoAttributes.portraitCellSize : AssetsPhotoAttributes.landscapeCellSize
            flowLayout.minimumLineSpacing = isPortrait ? AssetsPhotoAttributes.portraitLineSpace : AssetsPhotoAttributes.landscapeLineSpace
            flowLayout.minimumInteritemSpacing = isPortrait ? AssetsPhotoAttributes.portraitInteritemSpace : AssetsPhotoAttributes.landscapeInteritemSpace
        }
    }
    
    func select(asset: PHAsset, at indexPath: IndexPath) {
        if let _ = selectedMap[asset.localIdentifier] {
            logw("Invalid status.")
            return
        }
        selectedArray.append(asset)
        selectedMap[asset.localIdentifier] = asset
        
        // update selected UI
        guard let photoCell = collectionView.cellForItem(at: indexPath) as? AssetsPhotoCell else {
            logw("Invalid status.")
            return
        }
        photoCell.count = selectedArray.count
    }
    
    func deselect(asset: PHAsset, at indexPath: IndexPath) {
        guard let targetAsset = selectedMap[asset.localIdentifier] else {
            logw("Invalid status.")
            return
        }
        guard let targetIndex = selectedArray.index(of: targetAsset) else {
            logw("Invalid status.")
            return
        }
        selectedArray.remove(at: targetIndex)
        selectedMap.removeValue(forKey: targetAsset.localIdentifier)
        
        updateSelectionCount()
    }
    
    func updateSelectionCount() {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        for visibleIndexPath in visibleIndexPaths {
            if let selectedAsset = selectedMap[AssetsManager.shared.photoArray[visibleIndexPath.row].localIdentifier], let photoCell = collectionView.cellForItem(at: visibleIndexPath) as? AssetsPhotoCell {
                if let selectedIndex = selectedArray.index(of: selectedAsset) {
                    photoCell.count = selectedIndex + 1
                }
            }
        }
    }
    
    func updateNavigationStatus() {
        doneButtonItem.isEnabled = selectedArray.count > 0
        
        let counts: (imageCount: Int, videoCount: Int) = selectedArray.reduce((0, 0)) { (result, asset) -> (Int, Int) in
            let imageCount = asset.mediaType == .image ? 1 : 0
            let videoCount = asset.mediaType == .video ? 1 : 0
            return (result.0 + imageCount, result.1 + videoCount)
        }
        
        let imageCount = counts.imageCount
        let videoCount = counts.videoCount
        
        var titleString = AssetsManager.shared.selectedAlbum?.localizedTitle ?? ""
        if imageCount > 0 && videoCount > 0 {
            titleString = String(format: String(key: "Title_Selected_Items"), imageCount + videoCount)
        } else {
            if imageCount > 0 {
                if imageCount > 1 {
                    titleString = String(format: String(key: "Title_Selected_Photos"), imageCount)
                } else {
                    titleString = String(format: String(key: "Title_Selected_Photo"), imageCount)
                }
            } else if videoCount > 0 {
                if videoCount > 1 {
                    titleString = String(format: String(key: "Title_Selected_Videos"), videoCount)
                } else {
                    titleString = String(format: String(key: "Title_Selected_Video"), videoCount)
                }
            }
        }
        title = titleString
    }
    
    func updateFooter() {
        guard let footerView = collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionFooter).last as? AssetsPhotoFooterView else {
            return
        }
        footerView.set(imageCount: AssetsManager.shared.count(ofType: .image), videoCount: AssetsManager.shared.count(ofType: .video))
    }
}

// MARK: - UI Event Handlers
extension AssetsPhotoViewController {
    
    func pressedCancel(button: UIBarButtonItem) {
        splitViewController?.dismiss(animated: true, completion: nil)
        delegate?.assetsPickerDidCancel(controller: picker)
    }
    
    func pressedDone(button: UIBarButtonItem) {
        splitViewController?.dismiss(animated: true, completion: nil)
        delegate?.assetsPicker(controller: picker, selected: selectedArray)
    }
    
    func pressedTitle(gesture: UITapGestureRecognizer) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
        let navigationController = UINavigationController()
        let controller = AssetsAlbumViewController()
        controller.delegate = self
        navigationController.viewControllers = [controller]
        present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - UIScrollViewDelegate
extension AssetsPhotoViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {}
}

// MARK: - UICollectionViewDelegate
extension AssetsPhotoViewController: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let delegate = self.delegate {
            return delegate.assetsPicker(controller: picker, shouldSelect: AssetsManager.shared.photoArray[indexPath.row], at: indexPath)
        } else {
            return true
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = AssetsManager.shared.photoArray[indexPath.row]
        select(asset: asset, at: indexPath)
        updateNavigationStatus()
        delegate?.assetsPicker(controller: picker, didSelect: asset, at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if let delegate = self.delegate {
            return delegate.assetsPicker(controller: picker, shouldDeselect: AssetsManager.shared.photoArray[indexPath.row], at: indexPath)
        } else {
            return true
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let asset = AssetsManager.shared.photoArray[indexPath.row]
        deselect(asset: asset, at: indexPath)
        updateNavigationStatus()
        delegate?.assetsPicker(controller: picker, didDeselect: asset, at: indexPath)
    }
}

// MARK: - UICollectionViewDataSource
extension AssetsPhotoViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = AssetsManager.shared.photoArray.count
        updateEmptyView(count: count)
        return count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        guard var photoCell = cell as? AssetsPhotoCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return cell
        }
        photoCell.isVideo = AssetsManager.shared.photoArray[indexPath.row].mediaType == .video
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard var photoCell = cell as? AssetsPhotoCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return
        }
        
        let asset = AssetsManager.shared.photoArray[indexPath.row]
        photoCell.isVideo = asset.mediaType == .video
        if photoCell.isVideo {
            photoCell.duration = asset.duration
        }
        
        if let selectedAsset = selectedMap[asset.localIdentifier] {
            // update cell UI as selected
            if let targetIndex = selectedArray.index(of: selectedAsset) {
                photoCell.count = targetIndex + 1
            }
        } else {
            // update cell UI as normal
        }
        AssetsManager.shared.image(at: indexPath.row, size: AssetsPhotoAttributes.thumbnailCacheSize, completion: { (image) in
            photoCell.imageView.image = image
        })
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: footerReuseIdentifier, for: indexPath) as? AssetsPhotoFooterView else {
            logw("Failed to cast AssetsPhotoFooterView.")
            return AssetsPhotoFooterView()
        }
        footerView.setNeedsUpdateConstraints()
        footerView.updateConstraintsIfNeeded()
        footerView.set(imageCount: AssetsManager.shared.count(ofType: .image), videoCount: AssetsManager.shared.count(ofType: .video))
        return footerView
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AssetsPhotoViewController: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if collectionView.numberOfSections - 1 == section {
            if collectionView.bounds.width > collectionView.bounds.height {
                return CGSize(width: collectionView.bounds.width, height: AssetsPhotoAttributes.landscapeCellSize.width * 2/3)
            } else {
                return CGSize(width: collectionView.bounds.width, height: AssetsPhotoAttributes.portraitCellSize.width * 2/3)
            }
        } else {
            return .zero
        }
    }
}

// MARK: - UICollectionViewDataSourcePrefetching
extension AssetsPhotoViewController: UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        var assets = [PHAsset]()
        for indexPath in indexPaths {
            assets.append(AssetsManager.shared.photoArray[indexPath.row])
        }
        AssetsManager.shared.cache(assets: assets, size: AssetsPhotoAttributes.thumbnailCacheSize)
    }
}

// MARK: - AssetsAlbumViewControllerDelegate
extension AssetsPhotoViewController: AssetsAlbumViewControllerDelegate {
    
    public func assetsAlbumViewControllerCancelled(controller: AssetsAlbumViewController) {
        log("")
    }
    
    public func assetsAlbumViewController(controller: AssetsAlbumViewController, selected album: PHAssetCollection) {
        
        if AssetsManager.shared.select(album: album) {
            
            title = album.localizedTitle
            collectionView.reloadData()
            
            for asset in selectedArray {
                if let index = AssetsManager.shared.photoArray.index(of: asset) {
                    logi("reselecting: \(index)")
                    collectionView.selectItem(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .init(rawValue: 0))
                }
            }
            if AssetsManager.shared.photoArray.count > 0 {
                collectionView.scrollToItem(at: IndexPath(row: AssetsManager.shared.photoArray.count - 1, section: 0), at: .bottom, animated: false)
            }
        }
    }
}

// MARK: - AssetsManagerDelegate
extension AssetsPhotoViewController: AssetsManagerDelegate {
    
    public func assetsManager(manager: AssetsManager, authorizationStatusChanged oldStatus: PHAuthorizationStatus, newStatus: PHAuthorizationStatus) {
        if oldStatus != .authorized {
            if newStatus == .authorized {
                updateNoPermissionView()
                AssetsManager.shared.fetchPhotos(isRefetch: true, completion: { (_) in
                    self.collectionView.reloadData()
                })
            }
        } else {
            updateNoPermissionView()
        }
    }
    
    public func assetsManagerReloaded(manager: AssetsManager) {
        
    }
    
    public func assetsManager(manager: AssetsManager, reloadedAlbum album: PHAssetCollection, at indexPath: IndexPath) {
        logi("reloaded album: \(indexPath)")
    }
    
    public func assetsManager(manager: AssetsManager, insertedAssets assets: [PHAsset], at indexPaths: [IndexPath]) {
        logi("insertedAssets at: \(indexPaths)")
        collectionView.insertItems(at: indexPaths)
        updateFooter()
    }
    
    public func assetsManager(manager: AssetsManager, removedAssets assets: [PHAsset], at indexPaths: [IndexPath]) {
        logi("removedAssets at: \(indexPaths)")
        for removedAsset in assets {
            if let index = selectedArray.index(of: removedAsset) {
                selectedArray.remove(at: index)
                selectedMap.removeValue(forKey: removedAsset.localIdentifier)
            }
        }
        collectionView.deleteItems(at: indexPaths)
        updateSelectionCount()
        updateNavigationStatus()
        updateFooter()
    }
    
    public func assetsManager(manager: AssetsManager, updatedAssets assets: [PHAsset], at indexPaths: [IndexPath]) {
        logi("updatedAssets at: \(indexPaths)")
        collectionView.reloadItems(at: indexPaths)
        updateNavigationStatus()
        updateFooter()
    }
}
