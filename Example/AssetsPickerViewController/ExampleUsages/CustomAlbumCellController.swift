//
//  CustomAlbumCellController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 5/29/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Photos
import AssetsPickerViewController
import TinyLog
import PureLayout
import Dimmer

private let imageSize = CGSize(width: 80, height: 80)

class CustomAlbumCell: UICollectionViewCell, AssetsAlbumCellProtocol {
    
    // MARK: - AssetsAlbumCellProtocol
    var album: PHAssetCollection? {
        didSet {}
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                contentView.dim(animated: false, direction: .solid, color: .gray, alpha: 0.3)
            } else {
                contentView.undim()
            }
        }
    }
    
    var imageView: UIImageView = {
        let view = UIImageView.newAutoLayout()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.backgroundColor = UIColor(rgbHex: 0xF0F0F0)
        return view
    }()
    
    var titleText: String? {
        didSet {
            if let titleText = self.titleText {
                titleLabel.text = "\(titleText) (\(count))"
            } else {
                titleLabel.text = nil
            }
        }
    }
    
    var count: Int = 0 {
        didSet {
            if let titleText = self.titleText {
                titleLabel.text = "\(titleText) (\(count))"
            } else {
                titleLabel.text = nil
            }
        }
    }
    
    // MARK: - At your service
    private var didSetupConstraints: Bool = false
    
    var titleLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.clipsToBounds = true
        return label
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
    }
    
    override func updateConstraints() {
        if !didSetupConstraints {
            imageView.autoSetDimensions(to: imageSize)
            imageView.autoPinEdge(.leading, to: .leading, of: contentView)
            titleLabel.autoPinEdge(.leading, to: .trailing, of: imageView, withOffset: 10)
            titleLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .leading)
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
}

class CustomAlbumCellController: CommonExampleController {
    
    override func pressedPick(_ sender: Any) {
        
        let pickerConfig = AssetsPickerConfig()
        pickerConfig.albumCellType = CustomAlbumCell.classForCoder()
        pickerConfig.albumPortraitForcedCellHeight = imageSize.height
        pickerConfig.albumLandscapeForcedCellHeight = imageSize.height
        pickerConfig.albumForcedCacheSize = imageSize
        pickerConfig.albumDefaultSpace = 0
        pickerConfig.albumLineSpace = 1
        pickerConfig.albumPortraitColumnCount = 1
        pickerConfig.albumLandscapeColumnCount = 1
        
        let picker = AssetsPickerViewController(pickerConfig: pickerConfig)
        picker.pickerDelegate = self
        
        present(picker, animated: true, completion: nil)
    }
}
