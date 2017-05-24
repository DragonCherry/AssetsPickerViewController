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
    
    let cellReuseIdentifier: String = UUID().uuidString
    let footerReuseIdentifier: String = UUID().uuidString
    
    lazy var cancelButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: String(key: "Cancel"), style: .plain, target: self, action: #selector(pressedCancel(button:)))
        return buttonItem
    }()
    lazy var doneButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: String(key: "Done"), style: .plain, target: self, action: #selector(pressedDone(button:)))
        return buttonItem
    }()
    
    fileprivate var tapGesture: UITapGestureRecognizer?
    fileprivate var selectedAlbum: PHAssetCollection?
    fileprivate var syncOffsetRatio: CGFloat = -1
    
    var didSetupConstraints = false
    
    lazy var collectionView: UICollectionView = {
        
        let layout = AssetsPhotoLayout()
        self.updateLayout(layout: layout, isPortrait: UIApplication.shared.statusBarOrientation.isPortrait)
        layout.scrollDirection = .vertical
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.configureForAutoLayout()
        view.allowsMultipleSelection = true
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
        view.setNeedsUpdateConstraints()
        
        AssetsManager.shared.subscribe(subscriber: self)
        AssetsManager.shared.fetchAlbums()
        AssetsManager.shared.fetchPhotos(album: nil, cacheSize: PhotoAttributes.thumbnailCacheSize) { _ in
            self.collectionView.reloadData()
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupCommon()
        setupBarButtonItems()
    }
    
    open override func updateViewConstraints() {
        if !didSetupConstraints {
            collectionView.autoPinEdgesToSuperviewEdges()
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let isPortrait = size.height > size.width
        
        if let photoLayout = collectionView.collectionViewLayout as? AssetsPhotoLayout {
            if let offset = photoLayout.translateOffset(forChangingSize: size, currentOffset: collectionView.contentOffset) {
                photoLayout.translatedOffset = offset
            }
            coordinator.animate(alongsideTransition: { (_) in
                
            }) { (_) in
                photoLayout.translatedOffset = nil
            }
        }
        updateLayout(layout: collectionView.collectionViewLayout, isPortrait: isPortrait)
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
        title = String(key: "Title_Assets")
        view.backgroundColor = .white
    }
    
    open func setupBarButtonItems() {
        navigationItem.leftBarButtonItem = cancelButtonItem
        navigationItem.rightBarButtonItem = doneButtonItem
    }
    
    open func setupGestureRecognizer() {
        if let _ = self.tapGesture {
            
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

// MARK: - Internal Utility
extension AssetsPhotoViewController {
    func updateLayout(layout: UICollectionViewLayout?, isPortrait: Bool) {
        if let flowLayout = layout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = isPortrait ? PhotoAttributes.portraitCellSize : PhotoAttributes.landscapeCellSize
            flowLayout.minimumLineSpacing = isPortrait ? PhotoAttributes.portraitLineSpace : PhotoAttributes.landscapeLineSpace
            flowLayout.minimumInteritemSpacing = isPortrait ? PhotoAttributes.portraitInteritemSpace : PhotoAttributes.landscapeInteritemSpace
        }
    }
}

// MARK: - UI Event Handlers
extension AssetsPhotoViewController {
    
    func pressedCancel(button: UIBarButtonItem) {
        splitViewController?.dismiss(animated: true, completion: nil)
    }
    
    func pressedDone(button: UIBarButtonItem) {
        splitViewController?.dismiss(animated: true, completion: nil)
    }
    
    func pressedTitle(gesture: UITapGestureRecognizer) {
        let navigationController = UINavigationController()
        let controller = AssetsAlbumViewController()
        controller.delegate = self
        navigationController.viewControllers = [controller]
        present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - UIScrollViewDelegate
extension AssetsPhotoViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds != .zero else { return }
        let ratio = (collectionView.contentOffset.y) / (collectionView.contentSize.height - collectionView.bounds.height)
        log("\(scrollView.contentOffset)/\(scrollView.contentSize) : \(ratio)")
        if ratio >= 1 {
            logw("")
        }
    }
}

// MARK: - UICollectionViewDelegate
extension AssetsPhotoViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        log("[\(indexPath.section)][\(indexPath.row)]")
    }
}

// MARK: - UICollectionViewDataSource
extension AssetsPhotoViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AssetsManager.shared.photoArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        guard let _ = cell as? AssetsPhotoCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return cell
        }
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: footerReuseIdentifier, for: indexPath) as? AssetsPhotoFooterView else {
            logw("Failed to cast AssetsPhotoFooterView.")
            return AssetsPhotoFooterView()
        }
        footerView.setNeedsUpdateConstraints()
        footerView.updateConstraintsIfNeeded()
        return footerView
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        //log("[\(indexPath.section)][\(indexPath.row)]")
        guard let photoCell = cell as? AssetsPhotoCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return
        }
        AssetsManager.shared.image(at: indexPath.row, size: PhotoAttributes.thumbnailCacheSize, completion: { (image) in
            photoCell.imageView.image = image
        })
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AssetsPhotoViewController: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if AssetsManager.shared.numberOfSections - 1 == section {
            return CGSize(width: collectionView.frame.size.width, height: 60)
        } else {
            return .zero
        }
    }
}

// MARK: - UICollectionViewDataSourcePrefetching
extension AssetsPhotoViewController: UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        
    }
}

// MARK: - AssetsAlbumViewControllerDelegate
extension AssetsPhotoViewController: AssetsAlbumViewControllerDelegate {
    
    public func assetsAlbumViewControllerCancelled(controller: AssetsAlbumViewController) {
        log("")
    }
    
    public func assetsAlbumViewController(controller: AssetsAlbumViewController, selected album: PHAssetCollection) {
        selectedAlbum = album
    }
}

// MARK: - AssetsManagerDelegate
extension AssetsPhotoViewController: AssetsManagerDelegate {
    
    public func assetsManager(manager: AssetsManager, removedSection section: Int) {
        
    }
    public func assetsManager(manager: AssetsManager, removedAlbums: [PHAssetCollection], at indexPaths: [IndexPath]) {
        
    }
    public func assetsManager(manager: AssetsManager, addedAlbums: [PHAssetCollection], at indexPaths: [IndexPath]) {
        
    }
}
