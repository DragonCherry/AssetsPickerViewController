//
//  AssetsAlbumCell.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import PureLayout

public protocol AssetsAlbumCellProtocol {
    var isSelected: Bool { get set }
    var imageView: UIImageView { get }
    var titleLabel: UILabel { get }
    var countLabel: UILabel { get }
}

open class AssetsAlbumCell: UICollectionViewCell, AssetsAlbumCellProtocol {
    
    private var didSetupConstraints: Bool = false
    
    open override var isSelected: Bool {
        didSet {
            
        }
    }
    
    open var imageView: UIImageView {
        let view = UIImageView.newAutoLayout()
        
        return view
    }
    
    open var titleLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        
        return label
    }()
    
    open var countLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        
        return label
    }()
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .cyan
        addSubview(imageView)
    }
    
    open override func updateConstraints() {
        if !didSetupConstraints {
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
}
