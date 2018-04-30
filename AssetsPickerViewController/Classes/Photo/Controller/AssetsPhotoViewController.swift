//
//  AssetsPhotoViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import Photos
import PhotosUI
import TinyLog
import Device

// MARK: - AssetsPhotoViewController
open class AssetsPhotoViewController: UIViewController {
    
    // MARK: Properties
    fileprivate var pickerConfig: AssetsPickerConfig!
    fileprivate var previewing: UIViewControllerPreviewing?
    
    fileprivate let cellReuseIdentifier: String = UUID().uuidString
    fileprivate let headerReuseIdentifier: String = UUID().uuidString
    fileprivate let footerReuseIdentifier: String = UUID().uuidString
    
    fileprivate var requestIdMap = [IndexPath: PHImageRequestID]()
    
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
        return (navigationController as? AssetsPickerViewController)?.pickerDelegate
    }
    fileprivate var picker: AssetsPickerViewController! {
        return navigationController as! AssetsPickerViewController
    }
    fileprivate var tapGesture: UITapGestureRecognizer?
    fileprivate var syncOffsetRatio: CGFloat = -1
    
    fileprivate var selectedArray = [PHAsset]()
    fileprivate var selectedMap = [String: PHAsset]()
    
    fileprivate var didSetupConstraints = false
    fileprivate var didSetInitialPosition: Bool = false
    
    fileprivate var isPortrait: Bool = true
    
    var leadingConstraint: NSLayoutConstraint?
    var trailingConstraint: NSLayoutConstraint?
    
    fileprivate lazy var collectionView: UICollectionView = {
        
        let layout = AssetsPhotoLayout(pickerConfig: self.pickerConfig)
        self.updateLayout(layout: layout, isPortrait: UIApplication.shared.statusBarOrientation.isPortrait)
        layout.scrollDirection = .vertical
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.configureForAutoLayout()
        view.allowsMultipleSelection = true
        view.alwaysBounceVertical = true
        view.register(self.pickerConfig.assetCellType, forCellWithReuseIdentifier: self.cellReuseIdentifier)
        view.register(AssetsPhotoHeaderView.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: self.headerReuseIdentifier)
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
    
    var selectedAssets: [PHAsset] {
        return selectedArray
    }
    
    // MARK: Lifecycle Methods
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init(pickerConfig: AssetsPickerConfig) {
        self.init()
        self.pickerConfig = pickerConfig
    }
    
    override open func loadView() {
        super.loadView()
        view = UIView()
        view.backgroundColor = .white
        view.addSubview(collectionView)
        view.addSubview(emptyView)
        view.addSubview(noPermissionView)
        view.setNeedsUpdateConstraints()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setupCommon()
        setupBarButtonItems()
        
        updateEmptyView(count: 0)
        updateNoPermissionView()
        
        if let selectedAssets = self.pickerConfig?.selectedAssets {
            setSelectedAssets(assets: selectedAssets)
        }
        
        AssetsManager.shared.authorize { [weak self] (isGranted) in
            guard let `self` = self else { return }
            self.updateNoPermissionView()
            if isGranted {
                self.setupAssets()
            } else {
                self.delegate?.assetsPickerCannotAccessPhotoLibrary?(controller: self.picker)
            }
        }
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if let previewing = self.previewing {
            if traitCollection.forceTouchCapability != .available {
                unregisterForPreviewing(withContext: previewing)
                self.previewing = nil
            }
        } else {
            if traitCollection.forceTouchCapability == .available {
                self.previewing = registerForPreviewing(with: self, sourceView: collectionView)
            }
        }
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didSetInitialPosition {
            if pickerConfig.assetsIsScrollToBottom {
                let count = AssetsManager.shared.assetArray.count
                if count > 0 && self.collectionView.collectionViewLayout.collectionViewContentSize.height > 0 {
                    let lastSectionIndex = count - 1
                    let lastSectionRowIndex = AssetsManager.shared.assetArray[lastSectionIndex].count - 1
                    self.collectionView.scrollToItem(at: IndexPath(row: lastSectionRowIndex, section: lastSectionIndex), at: .bottom, animated: false)
                }
            }
            didSetInitialPosition = true
        }
    }
    
    override open func updateViewConstraints() {
        if !didSetupConstraints {
            collectionView.autoPinEdge(toSuperviewEdge: .top)
            
            if #available(iOS 11.0, *) {
                leadingConstraint = collectionView.autoPinEdge(toSuperviewEdge: .leading, withInset: view.safeAreaInsets.left)
                trailingConstraint = collectionView.autoPinEdge(toSuperviewEdge: .trailing, withInset: view.safeAreaInsets.right)
            } else {
                leadingConstraint = collectionView.autoPinEdge(toSuperviewEdge: .leading)
                trailingConstraint = collectionView.autoPinEdge(toSuperviewEdge: .trailing)
            }
            collectionView.autoPinEdge(toSuperviewEdge: .bottom)
            
            emptyView.autoPinEdgesToSuperviewEdges()
            noPermissionView.autoPinEdgesToSuperviewEdges()
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }
    
    @available(iOS 11.0, *)
    override open func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        leadingConstraint?.constant = view.safeAreaInsets.left
        trailingConstraint?.constant = -view.safeAreaInsets.right
        updateLayout(layout: collectionView.collectionViewLayout)
        logi("\(view.safeAreaInsets)")
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let isPortrait = size.height > size.width
        let contentSize = CGSize(width: size.width, height: size.height)
        if let photoLayout = collectionView.collectionViewLayout as? AssetsPhotoLayout {
            if let offset = photoLayout.translateOffset(forChangingSize: contentSize, currentOffset: collectionView.contentOffset) {
                photoLayout.translatedOffset = offset
                logi("translated offset: \(offset)")
            }
            coordinator.animate(alongsideTransition: { (_) in
            }) { (_) in
                photoLayout.translatedOffset = nil
            }
        }
        updateLayout(layout: collectionView.collectionViewLayout, isPortrait: isPortrait)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationStatus()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupGestureRecognizer()
        if traitCollection.forceTouchCapability == .available {
            previewing = registerForPreviewing(with: self, sourceView: collectionView)
        }
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeGestureRecognizer()
        if let previewing = self.previewing {
            self.previewing = nil
            unregisterForPreviewing(withContext: previewing)
        }
    }
    
    open var isMomentsAlbum: Bool {
        if pickerConfig.albumIsShowMomentAlbums {
            return (AssetsManager.shared.selectedAlbum?.assetCollectionType == .moment) ?? false
        } else {
            return false
        }
    }
    
    deinit {
        logd("Released \(type(of: self))")
    }
}

// MARK: - Initial Setups
extension AssetsPhotoViewController {
    
    func setupCommon() {
        view.backgroundColor = .white
    }
    
    func setupBarButtonItems() {
        navigationItem.leftBarButtonItem = cancelButtonItem
        navigationItem.rightBarButtonItem = doneButtonItem
        doneButtonItem.isEnabled = false
    }
    
    func setupAssets() {
        let manager = AssetsManager.shared
        manager.subscribe(subscriber: self)
        manager.fetchAlbums()
        manager.fetchAssets() { [weak self] albums in
            guard let `self` = self else { return }
            
            self.updateEmptyView(count: albums.count)
            self.title = self.title(forAlbum: manager.selectedAlbum)
            
            if self.selectedArray.count > 0 {
                self.collectionView.performBatchUpdates({ [weak self] in
                    self?.collectionView.reloadData()
                    }, completion: { [weak self] (finished) in
                        guard let `self` = self else { return }
                        // initialize preselected assets
                        self.selectedArray.forEach({ [weak self] (asset) in
                            if let pathToSelect = AssetsManager.shared.indexPath(for: asset) {
                                self?.collectionView.selectItem(at: pathToSelect, animated: false, scrollPosition: UICollectionViewScrollPosition(rawValue: 0))
                            }
                        })
                        self.updateSelectionCount()
                })
            }
        }
    }
    
    func setupGestureRecognizer() {
        if let _ = self.tapGesture {
            // ignore
        } else {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(pressedTitle))
            navigationController?.navigationBar.addGestureRecognizer(gesture)
            gesture.delegate = self
            tapGesture = gesture
        }
    }
    
    func removeGestureRecognizer() {
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
    
    func updateLayout(layout: UICollectionViewLayout, isPortrait: Bool? = nil) {
        guard let flowLayout = layout as? UICollectionViewFlowLayout else { return }
        if let isPortrait = isPortrait {
            self.isPortrait = isPortrait
        }
        flowLayout.itemSize = self.isPortrait ? pickerConfig.assetPortraitCellSize(forViewSize: UIScreen.main.portraitContentSize) : pickerConfig.assetLandscapeCellSize(forViewSize: UIScreen.main.landscapeContentSize)
        flowLayout.minimumLineSpacing = self.isPortrait ? pickerConfig.assetPortraitLineSpace : pickerConfig.assetLandscapeLineSpace
        flowLayout.minimumInteritemSpacing = self.isPortrait ? pickerConfig.assetPortraitInteritemSpace : pickerConfig.assetLandscapeInteritemSpace
        flowLayout.sectionHeadersPinToVisibleBounds = true
    }
    
    func setSelectedAssets(assets: [PHAsset]) {
        selectedArray.removeAll()
        selectedMap.removeAll()
        
        _ = assets.filter { AssetsManager.shared.isExist(asset: $0) }
            .map { [weak self] asset in
                guard let `self` = self else { return }
                self.selectedArray.append(asset)
                self.selectedMap.updateValue(asset, forKey: asset.localIdentifier)
        }
    }
    
    func select(album: PHAssetCollection) {
        if AssetsManager.shared.select(album: album) {
            // set title with selected count if exists
            if selectedArray.count > 0 {
                updateNavigationStatus()
            } else {
                title = title(forAlbum: album)
            }
            collectionView.reloadData()
            
            for asset in selectedArray {
                if let index = AssetsManager.shared.indexPath(for: asset) {
                    logi("reselecting: \(index)")
                    collectionView.selectItem(at: index, animated: false, scrollPosition: .init(rawValue: 0))
                }
            }
            let count = AssetsManager.shared.assetArray.count
            if count > 0 {
                let lastSectionIndex = count - 1
                let lastSectionRowIndex = AssetsManager.shared.assetArray[lastSectionIndex].count - 1
                collectionView.scrollToItem(at: IndexPath(row: lastSectionRowIndex, section: lastSectionIndex), at: .bottom, animated: false)
            }
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
        guard var photoCell = collectionView.cellForItem(at: indexPath) as? AssetsPhotoCellProtocol else {
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
            guard AssetsManager.shared.assetArray.count > visibleIndexPath.row else {
                logw("Referred wrong index\(visibleIndexPath.row) while asset count is \(AssetsManager.shared.assetArray.count).")
                break
            }
            
            if AssetsManager.shared.assetArray.indices.contains(visibleIndexPath.section) {
                logw("Visible asset at section: \(visibleIndexPath.section) and row: \(visibleIndexPath.row) have been removed")
                break
            } else if AssetsManager.shared.assetArray[visibleIndexPath.section].indices.contains(visibleIndexPath.row) {
                logw("Visible asset at section: \(visibleIndexPath.section) and row: \(visibleIndexPath.row) have been removed")
                break
            }
            
            if let selectedAsset = selectedMap[AssetsManager.shared.assetArray[visibleIndexPath.section][visibleIndexPath.row].localIdentifier], var photoCell = collectionView.cellForItem(at: visibleIndexPath) as? AssetsPhotoCellProtocol {
                if let selectedIndex = selectedArray.index(of: selectedAsset) {
                    photoCell.count = selectedIndex + 1
                }
            }
        }
    }
    
    func updateNavigationStatus() {
        
        doneButtonItem.isEnabled = selectedArray.count >= (pickerConfig.assetsMinimumSelectionCount > 0 ? pickerConfig.assetsMinimumSelectionCount : 1)
        
        let counts: (imageCount: Int, videoCount: Int) = selectedArray.reduce((0, 0)) { (result, asset) -> (Int, Int) in
            let imageCount = asset.mediaType == .image ? 1 : 0
            let videoCount = asset.mediaType == .video ? 1 : 0
            return (result.0 + imageCount, result.1 + videoCount)
        }
        
        let imageCount = counts.imageCount
        let videoCount = counts.videoCount
        
        var titleString: String = title(forAlbum: AssetsManager.shared.selectedAlbum)
        
        if imageCount > 0 && videoCount > 0 {
            titleString = String(format: String(key: "Title_Selected_Items"), NumberFormatter.decimalString(value: imageCount + videoCount))
        } else {
            if imageCount > 0 {
                if imageCount > 1 {
                    titleString = String(format: String(key: "Title_Selected_Photos"), NumberFormatter.decimalString(value: imageCount))
                } else {
                    titleString = String(format: String(key: "Title_Selected_Photo"), NumberFormatter.decimalString(value: imageCount))
                }
            } else if videoCount > 0 {
                if videoCount > 1 {
                    titleString = String(format: String(key: "Title_Selected_Videos"), NumberFormatter.decimalString(value: videoCount))
                } else {
                    titleString = String(format: String(key: "Title_Selected_Video"), NumberFormatter.decimalString(value: videoCount))
                }
            }
        }
        title = titleString
    }

    func updateHeader() {
        guard let headerView = collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader).last as? AssetsPhotoHeaderView else {
            return
        }
        // TODO: update header text
        headerView.set(location: "hahaha", subLocation: ["subloc sdfafa"], date: nil)
    }
    
    func updateFooter() {
        guard let footerView = collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionFooter).last as? AssetsPhotoFooterView else {
            return
        }
        footerView.set(imageCount: AssetsManager.shared.count(ofType: .image), videoCount: AssetsManager.shared.count(ofType: .video))
    }
    
    func presentAlbumController(animated: Bool = true) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
        let navigationController = UINavigationController()
        if #available(iOS 11.0, *) {
            navigationController.navigationBar.prefersLargeTitles = true
        }
        let controller = AssetsAlbumViewController(pickerConfig: self.pickerConfig)
        controller.delegate = self
        navigationController.viewControllers = [controller]
        
        self.navigationController?.present(navigationController, animated: animated, completion: nil)
    }
    
    func title(forAlbum album: PHAssetCollection?) -> String {
        if album?.assetCollectionType == .moment {
            return "Moments ▾"
        }
        
        var titleString: String!
        if let albumTitle = album?.localizedTitle {
            titleString = "\(albumTitle) ▾"
        } else {
            titleString = ""
        }
        return titleString
    }
}

// MARK: - UI Event Handlers
extension AssetsPhotoViewController {
    
    @objc func pressedCancel(button: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: {
            self.delegate?.assetsPicker?(controller: self.picker, didDismissByCancelling: true)
        })
        delegate?.assetsPickerDidCancel?(controller: picker)
    }
    
    @objc func pressedDone(button: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: {
            self.delegate?.assetsPicker?(controller: self.picker, didDismissByCancelling: false)
        })
        delegate?.assetsPicker(controller: picker, selected: selectedArray)
    }
    
    @objc func pressedTitle(gesture: UITapGestureRecognizer) {
        presentAlbumController()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension AssetsPhotoViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let navigationBar = navigationController?.navigationBar else { return false }
        let point = touch.location(in: navigationBar)
        // Ignore touches on navigation buttons on both sides.
        return point.x > navigationBar.bounds.width / 4 && point.x < navigationBar.bounds.width * 3 / 4
    }
}

// MARK: - UIScrollViewDelegate
extension AssetsPhotoViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        logi("contentOffset: \(scrollView.contentOffset)")
    }
}

// MARK: - UICollectionViewDelegate
extension AssetsPhotoViewController: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let delegate = self.delegate {
            return delegate.assetsPicker?(controller: picker, shouldSelect: AssetsManager.shared.assetArray[indexPath.section][indexPath.row], at: indexPath) ?? true
        } else {
            return true
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = AssetsManager.shared.assetArray[indexPath.section][indexPath.row]
        select(asset: asset, at: indexPath)
        updateNavigationStatus()
        delegate?.assetsPicker?(controller: picker, didSelect: asset, at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if let delegate = self.delegate {
            return delegate.assetsPicker?(controller: picker, shouldDeselect: AssetsManager.shared.assetArray[indexPath.section][indexPath.row], at: indexPath) ?? true
        } else {
            return true
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let asset = AssetsManager.shared.assetArray[indexPath.section][indexPath.row]
        deselect(asset: asset, at: indexPath)
        updateNavigationStatus()
        delegate?.assetsPicker?(controller: picker, didDeselect: asset, at: indexPath)
    }
}

// MARK: - UICollectionViewDataSource
extension AssetsPhotoViewController: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return AssetsManager.shared.assetArray.count
//        if let selectedAlbumType = AssetsManager.shared.selectedAlbum?.assetCollectionType {
//            return AssetsManager.shared.fetchedAlbumsArray[AssetsManager.shared.albumSection(forType: selectedAlbumType)].count
//        }
//        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = AssetsManager.shared.assetArray[section].count
        updateEmptyView(count: count)
        return count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        guard var photoCell = cell as? AssetsPhotoCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return cell
        }
        photoCell.isVideo = AssetsManager.shared.assetArray[indexPath.section][indexPath.row].mediaType == .video
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard var photoCell = cell as? AssetsPhotoCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return
        }
        
        let asset = AssetsManager.shared.assetArray[indexPath.section][indexPath.row]
        photoCell.asset = asset
        photoCell.isVideo = asset.mediaType == .video
        if photoCell.isVideo {
            photoCell.duration = asset.duration
        }
        
        if let selectedAsset = selectedMap[asset.localIdentifier] {
            // update cell UI as selected
            if let targetIndex = selectedArray.index(of: selectedAsset) {
                photoCell.count = targetIndex + 1
            }
        }
        
        cancelFetching(at: indexPath)
        let requestId = AssetsManager.shared.image(at: IndexPath(row: indexPath.row, section: indexPath.section), size: pickerConfig.assetCacheSize, completion: { [weak self] (image, isDegraded) in
            if self?.isFetching(indexPath: indexPath) ?? true {
                if !isDegraded {
                    self?.removeFetching(indexPath: indexPath)
                }
                UIView.transition(
                    with: photoCell.imageView,
                    duration: 0.125,
                    options: .transitionCrossDissolve,
                    animations: {
                        photoCell.imageView.image = image
                },
                    completion: nil
                )
            }
        })
        registerFetching(requestId: requestId, at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cancelFetching(at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == "UICollectionElementKindSectionFooter" {
            guard let suppView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: footerReuseIdentifier, for: indexPath) as? AssetsPhotoFooterView else {
                logw("Failed to cast AssetsPhotoFooterView.")
                return AssetsPhotoFooterView()
            }
            suppView.setNeedsUpdateConstraints()
            suppView.updateConstraintsIfNeeded()
            suppView.set(imageCount: AssetsManager.shared.count(ofType: .image), videoCount: AssetsManager.shared.count(ofType: .video))
            return suppView
        } else {
            guard let suppView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as? AssetsPhotoHeaderView else {
                logw("Failed to cast AssetsPhotoHeaderView.")
                return AssetsPhotoHeaderView()
            }
            suppView.setNeedsUpdateConstraints()
            suppView.updateConstraintsIfNeeded()
            
//            let asset = AssetsManager.shared.assetArray[indexPath.section][0]
            let group = AssetsManager.shared.sortedAlbumsArray[AssetsManager.shared.albumSection(forType: .moment)][indexPath.section]
            suppView.set(location: group.localizedTitle, subLocation: group.localizedLocationNames, date: group.startDate)
            
            return suppView
        }
    }
}

// MARK: - Image Fetch Utility
extension AssetsPhotoViewController {
    
    func cancelFetching(at indexPath: IndexPath) {
        if let requestId = requestIdMap[indexPath] {
            requestIdMap.removeValue(forKey: indexPath)
            AssetsManager.shared.cancelRequest(requestId: requestId)
        }
    }
    
    func registerFetching(requestId: PHImageRequestID, at indexPath: IndexPath) {
        requestIdMap[indexPath] = requestId
    }
    
    func removeFetching(indexPath: IndexPath) {
        if let _ = requestIdMap[indexPath] {
            requestIdMap.removeValue(forKey: indexPath)
        }
    }
    
    func isFetching(indexPath: IndexPath) -> Bool {
        if let _ = requestIdMap[indexPath] {
            return true
        } else {
            return false
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AssetsPhotoViewController: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if collectionView.numberOfSections - 1 == section {
            if collectionView.bounds.width > collectionView.bounds.height {
                return CGSize(width: collectionView.bounds.width, height: pickerConfig.assetLandscapeCellSize(forViewSize: collectionView.bounds.size).width * 2/3)
            } else {
                return CGSize(width: collectionView.bounds.width, height: pickerConfig.assetPortraitCellSize(forViewSize: collectionView.bounds.size).width * 2/3)
            }
        } else {
            return .zero
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if isMomentsAlbum {
            if collectionView.bounds.width > collectionView.bounds.height {
                return CGSize(width: collectionView.bounds.width, height: pickerConfig.assetLandscapeCellSize(forViewSize: collectionView.bounds.size).width * 2/3)
            } else {
                return CGSize(width: collectionView.bounds.width, height: pickerConfig.assetPortraitCellSize(forViewSize: collectionView.bounds.size).width * 2/3)
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
            assets.append(AssetsManager.shared.assetArray[indexPath.section][indexPath.row])
        }
        AssetsManager.shared.cache(assets: assets, size: pickerConfig.assetCacheSize)
    }
}

// MARK: - AssetsAlbumViewControllerDelegate
extension AssetsPhotoViewController: AssetsAlbumViewControllerDelegate {
    
    public func assetsAlbumViewControllerCancelled(controller: AssetsAlbumViewController) {
        logi("Cancelled.")
    }
    
    public func assetsAlbumViewController(controller: AssetsAlbumViewController, selected album: PHAssetCollection) {
        select(album: album)
    }
}

// MARK: - AssetsManagerDelegate
extension AssetsPhotoViewController: AssetsManagerDelegate {
    
    public func assetsManager(manager: AssetsManager, authorizationStatusChanged oldStatus: PHAuthorizationStatus, newStatus: PHAuthorizationStatus) {
        if oldStatus != .authorized {
            if newStatus == .authorized {
                updateNoPermissionView()
                AssetsManager.shared.fetchAssets(isRefetch: true, completion: { [weak self] (_) in
                    self?.collectionView.reloadData()
                })
            }
        } else {
            updateNoPermissionView()
        }
    }
    
    public func assetsManager(manager: AssetsManager, reloadedAlbumsInSection section: Int) {}
    
    public func assetsManager(manager: AssetsManager, insertedAlbums albums: [PHAssetCollection], at indexPaths: [IndexPath]) {
        if manager.albumType(forSection: indexPaths[0].section) == .moment {
//            var sections = IndexSet()
//            for path in indexPaths {
//                sections.insert(path.row)
//            }
//            collectionView.insertSections(sections)
//            collectionView.insertItems(at: indexPaths)
        }
    }
    
    public func assetsManager(manager: AssetsManager, removedAlbums albums: [PHAssetCollection], at indexPaths: [IndexPath]) {
        logi("removedAlbums at indexPaths: \(indexPaths)")
        if manager.albumType(forSection: indexPaths[0].section) != .moment {
            guard let selectedAlbum = manager.selectedAlbum else {
                logw("selected album is nil.")
                return
            }
            if albums.contains(selectedAlbum) {
                select(album: manager.defaultAlbum ?? manager.cameraRollAlbum)
            }
        } else {
//            var sections = IndexSet()
//            for path in indexPaths {
//                sections.insert(path.row)
//            }
//            collectionView.deleteSections(sections)
//            collectionView.deleteItems(at: indexPaths)
        }
    }
    
    public func assetsManager(manager: AssetsManager, updatedAlbums albums: [PHAssetCollection], at indexPaths: [IndexPath]) {
        if manager.albumType(forSection: indexPaths[0].section) != .moment {
//            var sections = IndexSet()
//            for path in indexPaths {
//                sections.insert(path.row)
//            }
//            collectionView.reloadSections(sections)
//            collectionView.reloadItems(at: indexPaths)
        }
    }
    
    public func assetsManager(manager: AssetsManager, reloadedAlbum album: PHAssetCollection, at indexPath: IndexPath) {
        if manager.albumType(forSection: indexPath.section) != .moment {
//            collectionView.reloadSections(IndexSet(integer: indexPath.row))
//            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    public func assetsManager(manager: AssetsManager, insertedAssets assets: [PHAsset], at indexPaths: [IndexPath], inNewSection newSection: Bool = false) {
        logi("insertedAssets at: \(indexPaths)")
        if newSection {
            var sections = IndexSet()
            for path in indexPaths {
                sections.insert(path.section)
            }
            collectionView.insertSections(sections)
        } else {
            collectionView.insertItems(at: indexPaths)
        }
            
        if (self.pickerConfig.albumIsShowMomentAlbums) {
            updateHeader()
        }
        updateFooter()
    }
    
    public func assetsManager(manager: AssetsManager, removedAssets assets: [PHAsset], at indexPaths: [IndexPath], completeSection: Bool = false) {
        logi("removedAssets at: \(indexPaths)")
        for removedAsset in assets {
            if let index = selectedArray.index(of: removedAsset) {
                selectedArray.remove(at: index)
                selectedMap.removeValue(forKey: removedAsset.localIdentifier)
            }
        }
        
        if completeSection {
            var sections = IndexSet()
            for path in indexPaths {
                sections.insert(path.section)
            }
            collectionView.deleteSections(sections)
        } else {
            collectionView.deleteItems(at: indexPaths)
        }
        
        updateSelectionCount()
        updateNavigationStatus()
        if (self.pickerConfig.albumIsShowMomentAlbums) {
            updateHeader()
        }
        updateFooter()
    }
    
    public func assetsManager(manager: AssetsManager, updatedAssets assets: [PHAsset], at indexPaths: [IndexPath]) {
        logi("updatedAssets at: \(indexPaths)")
        collectionView.reloadItems(at: indexPaths)
        updateNavigationStatus()
        updateFooter()
    }
}

// MARK - UIViewControllerPreviewingDelegate
@available(iOS 9.0, *)
extension AssetsPhotoViewController: UIViewControllerPreviewingDelegate {
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        logi("\(location)")
        guard let pressingIndexPath = collectionView.indexPathForItem(at: location) else { return nil }
        guard let pressingCell = collectionView.cellForItem(at: pressingIndexPath) else { return nil }
        previewingContext.sourceRect = pressingCell.frame
        let previewController = AssetsPreviewController()
        previewController.asset = AssetsManager.shared.assetArray[pressingIndexPath.section][pressingIndexPath.row]
        return previewController
    }
    
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        logi("viewControllerToCommit: \(type(of: viewControllerToCommit))")
    }
}
