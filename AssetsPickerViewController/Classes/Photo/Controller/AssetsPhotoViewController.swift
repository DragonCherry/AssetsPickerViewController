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
    
    var didSetupConstraints = false
    
    lazy var cellWidth: CGFloat = {
        let count = CGFloat(self.numberOfCell(isPortrait: true))
        return (UIScreen.main.portraitSize.width - (count - 1)) / count
    }()
    var imageSize: CGSize {
        let width = cellWidth * 2
        return CGSize(width: width, height: width)
    }
    
    lazy var collectionView: UICollectionView = {
        
        let layout = AssetsPhotoLayout()
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
        AssetsManager.shared.fetchPhotos(album: nil, cacheSize: imageSize) { _ in
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
        let space = itemSpace(size: size, columnCount: numberOfCell(isPortrait: isPortrait))
        var insets = collectionView.contentInset
        if isPortrait {
            insets.left = 0
            insets.right = 0
        } else {
            insets.left = space / 2
            insets.right = space / 2
        }
        collectionView.contentInset = insets
        collectionView.collectionViewLayout.invalidateLayout()
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
    
    func numberOfCell(isPortrait: Bool) -> Int { return isPortrait ? 4 : 7 }
    
    func itemSpace(size: CGSize, columnCount count: Int) -> CGFloat {
        let space = (size.width - CGFloat(count) * cellWidth) / CGFloat(count)
        return space
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
        log("[\(indexPath.section)][\(indexPath.row)]")
        guard let photoCell = cell as? AssetsPhotoCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return
        }
        AssetsManager.shared.image(at: indexPath.row, size: imageSize, completion: { (image) in
            photoCell.imageView.image = image
        })
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AssetsPhotoViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = cellWidth
        return CGSize(width: width, height: width)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
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
