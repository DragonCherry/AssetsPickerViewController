//
//  AssetsPhotoCell.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import Photos

public protocol AssetsPhotoCellProtocol {
    var asset: PHAsset? { get set }
    var isSelected: Bool { get set }
    var isVideo: Bool { get set }
    var imageView: UIImageView { get }
    var count: Int { set get }
    var duration: TimeInterval { set get }
}

open class AssetsPhotoCell: UICollectionViewCell, AssetsPhotoCellProtocol {
    
    // MARK: - AssetsPhotoCellProtocol
    open var asset: PHAsset? {
        didSet {
            // customizable
            if let asset = asset {
                panoramaIconView.isHidden = asset.mediaSubtypes != .photoPanorama
            }
        }
    }
    
    open var isVideo: Bool = false {
        didSet {
            durationLabel.isHidden = !isVideo
            if !isVideo {
                imageView.removeGradient()
            }
        }
    }
    
    open override var isSelected: Bool {
        didSet { overlay.isHidden = !isSelected }
    }
    
    public let imageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UIColor(rgbHex: 0xF0F0F0)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    open var count: Int = 0 {
        didSet { overlay.countLabel.text = "\(count)" }
    }
    
    open var duration: TimeInterval = 0 {
        didSet {
            durationLabel.text = String(duration: duration)
        }
    }
    
    // MARK: - Views
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .right
        label.font = UIFont.systemFont(forStyle: .caption1)
        return label
    }()
    
    private let panoramaIconView: PanoramaIconView = {
        let view = PanoramaIconView()
        view.isHidden = true
        return view
    }()
    
    private let overlay: AssetsPhotoCellOverlay = {
        let overlay = AssetsPhotoCellOverlay()
        overlay.isHidden = true
        overlay.isUserInteractionEnabled = false
        return overlay
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
        contentView.addSubview(durationLabel)
        contentView.addSubview(panoramaIconView)
        contentView.addSubview(overlay)
        
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        durationLabel.snp.makeConstraints { (make) in
            make.height.equalTo(durationLabel.font.pointSize + 10)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview()
        }
        
        panoramaIconView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 14, height: 7))
            make.trailing.equalToSuperview().inset(6.5)
            make.bottom.equalToSuperview().inset(10)
        }
        
        overlay.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard isVideo else { return }
        imageView.setGradient(.fromBottom, start: 0, end: 0.2, startAlpha: 0.75, color: .black)
    }
}
