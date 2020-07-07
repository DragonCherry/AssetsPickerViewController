//
//  AssetsAlbumCell.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import Photos

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
    
    public let imageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .ap_cellBackground
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
        let label = UILabel()
        label.textColor = .ap_label
        label.font = UIFont.systemFont(forStyle: .subheadline)
        return label
    }()
    
    fileprivate let countLabel: UILabel = {
        let label = UILabel()
		label.textColor = .ap_secondaryLabel
        label.font = UIFont.systemFont(forStyle: .subheadline)
        return label
    }()

    
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
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)
        
        imageView.snp.makeConstraints { (make) in
            make.height.equalTo(imageView.snp.width)
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(titleLabel.font.pointSize + 2)
        }

        countLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(countLabel.font.pointSize + 2)
            //make.bottom.equalTo(snp.bottom).offset(8)
        }
    }
}
