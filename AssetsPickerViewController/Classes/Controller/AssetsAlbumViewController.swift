//
//  AssetsAlbumViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import TinyLog
import PureLayout

// MARK: - AssetsAlbumViewController
open class AssetsAlbumViewController: UIViewController {
    
    var cellType: AnyClass = AssetAlbumCell.classForCoder()
    let lineSpace: CGFloat = 10
    let interitemSpace: CGFloat = 10
    let reuseIdentifier: String = UUID().uuidString
    
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
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = self.lineSpace
        flowLayout.minimumInteritemSpacing = self.interitemSpace
        flowLayout.headerReferenceSize = CGSize.zero
        flowLayout.footerReferenceSize = CGSize.zero
        
        let view = UICollectionView(frame: self.view.bounds, collectionViewLayout: flowLayout)
        view.configureForAutoLayout()
        view.register(AssetAlbumCell.classForCoder(), forCellWithReuseIdentifier: self.reuseIdentifier)
        view.backgroundColor = UIColor.clear
        view.dataSource = self
        view.delegate = self
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = true
        view.decelerationRate = UIScrollViewDecelerationRateFast
        view.contentInset = .zero
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
    
    open override func loadView() {
        super.loadView()
        view = UIView()
        view.backgroundColor = .white
        
        view.addSubview(collectionView)
        view.setNeedsUpdateConstraints()
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
    
}

// MARK: - UICollectionViewDataSource
extension AssetsAlbumViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? AssetAlbumCell else {
            logw("Failed to cast UICollectionViewCell.")
            return UICollectionViewCell()
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
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
    
}

