//
//  CustomAssetCellController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 5/31/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Photos
import AssetsPickerViewController

class CustomAssetCellOverlay: UIView {
    
    private let countSize = CGSize(width: 40, height: 40)
    
    lazy var circleView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = self.countSize.width / 2
        view.alpha = 0.4
        return view
    }()
    let countLabel: UILabel = {
        let label = UILabel()
        let font = UIFont.preferredFont(forTextStyle: .headline)
        label.font = UIFont.systemFont(ofSize: font.pointSize, weight: UIFont.Weight.bold)
        label.textAlignment = .center
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
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
        dmr_dim(animated: false, color: .white, alpha: 0.25)
        addSubview(circleView)
        addSubview(countLabel)
        
        circleView.snp.makeConstraints { (make) in
            make.size.equalTo(countSize)
            make.center.equalToSuperview()
        }
        
        countLabel.snp.makeConstraints { (make) in
            make.size.equalTo(countSize)
            make.center.equalToSuperview()
        }
    }
}

class CustomAssetCell: UICollectionViewCell, AssetsPhotoCellProtocol {
    
    // MARK: - AssetsAlbumCellProtocol
    var asset: PHAsset? {
        didSet {}
    }
    
    var isVideo: Bool = false {
        didSet {
            durationLabel.isHidden = !isVideo
        }
    }
    
    override var isSelected: Bool {
        didSet { overlay.isHidden = !isSelected }
    }
    
    var imageView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.backgroundColor = UIColor(rgbHex: 0xF0F0F0)
        return view
    }()
    
    var count: Int = 0 {
        didSet { overlay.countLabel.text = "\(count)" }
    }
    
    var duration: TimeInterval = 0 {
        didSet {
            let hour = Int(duration / 3600)
            let min = Int((duration / 60).truncatingRemainder(dividingBy: 60))
            let sec = Int(duration.truncatingRemainder(dividingBy: 60))
            var durationString = hour > 0 ? "\(hour)" : ""
            durationString.append(min > 0 ? "\(min):" : "0:")
            durationString.append(String(format: "%02d", sec))
            durationLabel.text = durationString
        }
    }
    
    // MARK: - At your service
    
    let overlay: CustomAssetCellOverlay = {
        let view = CustomAssetCellOverlay()
        view.isHidden = true
        return view
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .right
        label.font = UIFont.boldSystemFont(ofSize: 20)
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
        contentView.addSubview(overlay)
        contentView.addSubview(durationLabel)
        
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        overlay.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        durationLabel.snp.makeConstraints { (make) in
            make.height.equalTo(durationLabel.font.pointSize + 10)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview()
        }
    }
}

class CustomAssetCellController: CommonExampleController {
    
    override func pressedPick(_ sender: Any) {
        
        let pickerConfig = AssetsPickerConfig()
        pickerConfig.assetCellType = CustomAssetCell.classForCoder()
        pickerConfig.assetPortraitColumnCount = 3
        pickerConfig.assetLandscapeColumnCount = 5
        pickerConfig.assetsMaximumSelectionCount = 10
        let picker = AssetsPickerViewController()
        picker.pickerConfig = pickerConfig
        picker.pickerDelegate = self
        
        present(picker, animated: true, completion: nil)
    }
}

