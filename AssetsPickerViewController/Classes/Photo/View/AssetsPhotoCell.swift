//
//  AssetsPhotoCell.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import Dimmer
import PureLayout

public protocol AssetsPhotoCellProtocol {
    var isSelected: Bool { get set }
    var imageView: UIImageView { get }
//    var timeLabel: UILabel { get }
//    var countLabel: UILabel { get }
}

open class AssetsPhotoCell: UICollectionViewCell, AssetsPhotoCellProtocol {
    
    private var didSetupConstraints: Bool = false
    
    open override var isSelected: Bool {
        didSet {
            if isSelected {
                imageView.dim()
            } else {
                imageView.undim()
            }
        }
    }
    
    open let imageView: UIImageView = {
        let view = UIImageView.newAutoLayout()
        view.backgroundColor = UIColor(rgbHex: 0xF0F0F0)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
//    open let timeLabel: UILabel = {
//        let label = UILabel.newAutoLayout()
//        label.textColor = .black
//        label.font = UIFont.systemFont(forStyle: .subheadline)
//        return label
//    }()
//    
//    open let countLabel: UILabel = {
//        let label = UILabel.newAutoLayout()
//        label.textColor = UIColor(rgbHex: 0x8C8C91)
//        label.font = UIFont.systemFont(forStyle: .subheadline)
//        return label
//    }()
    
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
//        contentView.addSubview(titleLabel)
//        contentView.addSubview(countLabel)
    }
    
    open override func updateConstraints() {
        if !didSetupConstraints {
            contentView.autoPinEdgesToSuperviewEdges()
            imageView.autoPinEdgesToSuperviewEdges()
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
}
