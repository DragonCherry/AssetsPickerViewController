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
    
    open var cellType: AnyClass = AssetsAlbumCell.classForCoder()
    open var delegate: AssetsAlbumViewControllerDelegate?
    
    let cellReuseIdentifier: String = UUID().uuidString
    let headerReuseIdentifier: String = UUID().uuidString
    
    let defaultSpace: CGFloat = { return 20 }()
    lazy var cellWidth: CGFloat = {
        let count = CGFloat(self.numberOfCell(isPortrait: true))
        return (UIScreen.main.portraitSize.width - (count + 1) * self.defaultSpace) / count
    }()
    var imageSize: CGSize {
        let width = cellWidth * 2
        return CGSize(width: width, height: width)
    }
    
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
        let initialSize = isPortrait ? UIScreen.main.portraitSize : UIScreen.main.landscapeSize
        let space = self.itemSpace(size: initialSize, columnCount: self.numberOfCell(isPortrait: isPortrait))
    
        let layout = AssetsAlbumLayout()
        layout.scrollDirection = .vertical
        
        let view = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        view.configureForAutoLayout()
        view.register(self.cellType, forCellWithReuseIdentifier: self.cellReuseIdentifier)
        view.register(AssetsAlbumHeaderView.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: self.headerReuseIdentifier)
        view.contentInset = UIEdgeInsets(top: self.defaultSpace, left: space, bottom: self.defaultSpace, right: space)
        view.backgroundColor = UIColor.clear
        view.dataSource = self
        view.delegate = self
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = true
        
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
        
        AssetsManager.shared.subscribe(subscriber: self)
        AssetsManager.shared.fetchAlbums { (albumsArray) in
            self.collectionView.reloadData()
        }
        AssetsManager.shared.cacheAlbums(cacheSize: imageSize)
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
        let space = itemSpace(size: size, columnCount: numberOfCell(isPortrait: size.height > size.width))
        let insets = collectionView.contentInset
        collectionView.contentInset = UIEdgeInsets(top: insets.top, left: space, bottom: insets.bottom, right: space)
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - Internal
extension AssetsAlbumViewController {
    func setupCommon() {
        title = String(key: "Title_Albums")
        view.backgroundColor = .white
    }
    
    func setupBarButtonItems() {
        navigationItem.leftBarButtonItem = cancelButtonItem
        navigationItem.rightBarButtonItem = searchButtonItem
    }
    
    func numberOfCell(isPortrait: Bool) -> Int { return isPortrait ? 2 : 3 }
    
    func itemSpace(size: CGSize, columnCount count: Int) -> CGFloat {
        let space = (size.width - CGFloat(count) * cellWidth) / CGFloat(count + 1)
        return space
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
        logi("\(AssetsManager.shared.numberOfSections)")
        return AssetsManager.shared.numberOfSections
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        logi("\(section)")
        return AssetsManager.shared.numberOfAlbums(inSection: section)
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
        log("[\(indexPath.section)][\(indexPath.row)]")
        guard let albumCell = cell as? AssetsAlbumCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return
        }
        albumCell.titleLabel.text = AssetsManager.shared.title(at: indexPath)
        albumCell.countLabel.text = NumberFormatter.decimalString(value: AssetsManager.shared.numberOfAssets(at: indexPath))
        albumCell.imageView.image = nil
        AssetsManager.shared.imageOfAlbum(at: indexPath, size: imageSize, isNeedDegraded: false) { (image) in
            albumCell.imageView.image = image
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AssetsAlbumViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height: cellWidth * 1.25)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return defaultSpace
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return defaultSpace
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if collectionView.numberOfSections > 1 && section == 1 {
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
    
    public func assetsManagerReloaded(manager: AssetsManager) {
        AssetsManager.shared.cacheAlbums(cacheSize: imageSize)
        collectionView.reloadData()
    }
    public func assetsManager(manager: AssetsManager, reloadedAlbum album: PHAssetCollection, at indexPath: IndexPath) {
        collectionView.reloadItems(at: [indexPath])
    }
    public func assetsManager(manager: AssetsManager, insertedAssets assets: [PHAsset], at indexPaths: [IndexPath]) {}
    public func assetsManager(manager: AssetsManager, removedAssets assets: [PHAsset], at indexPaths: [IndexPath]) {}
    public func assetsManager(manager: AssetsManager, updatedAssets assets: [PHAsset], at indexPaths: [IndexPath]) {}
}
