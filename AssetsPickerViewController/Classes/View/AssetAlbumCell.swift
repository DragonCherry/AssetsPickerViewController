//
//  AssetAlbumCell.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit

public protocol AssetAlbumCellProtocol {
    var isSelected: Bool { get set }
    var imageView: UIImageView { get }
    var titleLabel: UILabel { get }
    var countLabel: UILabel { get }
}

open class AssetAlbumCell: UICollectionViewCell, AssetAlbumCellProtocol {
    
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
}
