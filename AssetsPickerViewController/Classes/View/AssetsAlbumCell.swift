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
    
    open let imageView: UIImageView = {
        let view = UIImageView.newAutoLayout()
        view.backgroundColor = UIColor(rgbHex: 0xF0F0F0)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 5
        return view
    }()
    
    open let bottomView: UIView = {
        let view = UIView.newAutoLayout()
        view.backgroundColor = .clear
        return view
    }()
    
    open let titleLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textColor = .black
        label.font = UIFont.systemFont(forStyle: .caption1)
        return label
    }()
    
    open let countLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textColor = UIColor(rgbHex: 0x8C8C91)
        label.font = UIFont.systemFont(forStyle: .caption1)
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
        contentView.configureForAutoLayout()
        contentView.addSubview(imageView)
        contentView.addSubview(bottomView)
        bottomView.addSubview(titleLabel)
        bottomView.addSubview(countLabel)
    }
    
    open override func updateConstraints() {
        if !didSetupConstraints {
            
            contentView.autoPinEdgesToSuperviewEdges()
            
            imageView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
            imageView.autoMatch(.height, to: .width, of: contentView)
            
            bottomView.autoPinEdge(.top, to: .bottom, of: imageView)
            bottomView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            
            titleLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
            titleLabel.autoMatch(.height, to: .height, of: countLabel)
            titleLabel.autoPinEdge(.bottom, to: .top, of: countLabel)
            
            countLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            countLabel.autoMatch(.height, to: .height, of: titleLabel)
            countLabel.autoPinEdge(.top, to: .bottom, of: titleLabel)
            
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
}
