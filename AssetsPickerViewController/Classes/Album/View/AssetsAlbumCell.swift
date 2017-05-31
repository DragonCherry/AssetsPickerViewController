//
//  AssetsAlbumCell.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import Photos
import Dimmer
import PureLayout

public protocol AssetsAlbumCellProtocol {
    var album: PHAssetCollection? { get set }
    var isSelected: Bool { get set }
    var imageView: UIImageView { get }
    var titleText: String? { get set }
    var count: Int { get set }
}

open class AssetsAlbumCell: UICollectionViewCell, AssetsAlbumCellProtocol {
    
    // MARK: - AssetsAlbumCellProtocol
    open var album: PHAssetCollection? {
        didSet {
            // customizable
        }
    }
    
    open override var isSelected: Bool {
        didSet {
            if isSelected {
                imageView.dim(animated: false)
            } else {
                imageView.undim(animated: false)
            }
        }
    }
    
    open let imageView: UIImageView = {
        let view = UIImageView.newAutoLayout()
        view.backgroundColor = UIColor(rgbHex: 0xF0F0F0)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 5
        return view
    }()
    
    open var titleText: String? {
        didSet {
            titleLabel.text = titleText
        }
    }
    
    open var count: Int = 0 {
        didSet {
            countLabel.text = "\(NumberFormatter.decimalString(value: count))"
        }
    }
    
    // MARK: - Views
    fileprivate let titleLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textColor = .black
        label.font = UIFont.systemFont(forStyle: .subheadline)
        return label
    }()
    
    fileprivate let countLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textColor = UIColor(rgbHex: 0x8C8C91)
        label.font = UIFont.systemFont(forStyle: .subheadline)
        return label
    }()
    
    private var didSetupConstraints: Bool = false
    
    // MARK: - Lifecycle
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        contentView.configureForAutoLayout()
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)
    }
    
    open override func updateConstraints() {
        if !didSetupConstraints {
            
            contentView.autoPinEdgesToSuperviewEdges()
            
            imageView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
            imageView.autoMatch(.height, to: .width, of: contentView)
            
            titleLabel.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: 8)
            titleLabel.autoPinEdge(toSuperviewEdge: .leading)
            titleLabel.autoPinEdge(toSuperviewEdge: .trailing)
            titleLabel.autoSetDimension(.height, toSize: titleLabel.font.pointSize + 2)
            
            countLabel.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 2)
            countLabel.autoPinEdge(toSuperviewEdge: .leading)
            countLabel.autoPinEdge(toSuperviewEdge: .trailing)
            countLabel.autoSetDimension(.height, toSize: countLabel.font.pointSize + 2)
            
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
}
