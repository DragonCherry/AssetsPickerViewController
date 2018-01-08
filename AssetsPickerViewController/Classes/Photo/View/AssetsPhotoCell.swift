//
//  AssetsPhotoCell.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import Photos
import Dimmer
import PureLayout

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
    
    open let imageView: UIImageView = {
        let view = UIImageView.newAutoLayout()
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
    private var didSetupConstraints: Bool = false
    
    private let durationLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textColor = .white
        label.textAlignment = .right
        label.font = UIFont.systemFont(forStyle: .caption1)
        return label
    }()
    
    private let panoramaIconView: PanoramaIconView = {
        let view = PanoramaIconView.newAutoLayout()
        view.isHidden = true
        return view
    }()
    
    private let overlay: AssetsPhotoCellOverlay = {
        let overlay = AssetsPhotoCellOverlay.newAutoLayout()
        overlay.isHidden = true
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
        contentView.configureForAutoLayout()
        contentView.addSubview(imageView)
        contentView.addSubview(durationLabel)
        contentView.addSubview(panoramaIconView)
        contentView.addSubview(overlay)
    }
    
    open override func updateConstraints() {
        if !didSetupConstraints {
            
            contentView.autoPinEdgesToSuperviewEdges()
            
            imageView.autoPinEdgesToSuperviewEdges()
            
            durationLabel.autoSetDimension(.height, toSize: durationLabel.font.pointSize + 10)
            durationLabel.autoPinEdge(.leading, to: .leading, of: contentView, withOffset: 8)
            durationLabel.autoPinEdge(.trailing, to: .trailing, of: contentView, withOffset: -8)
            durationLabel.autoPinEdge(.bottom, to: .bottom, of: contentView)
            
            panoramaIconView.autoSetDimensions(to: CGSize(width: 14, height: 7))
            panoramaIconView.autoPinEdge(.trailing, to: .trailing, of: contentView, withOffset: -6.5)
            panoramaIconView.autoPinEdge(.bottom, to: .bottom, of: contentView, withOffset: -10)
            
            overlay.autoPinEdgesToSuperviewEdges()
            
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if isVideo {
            imageView.setGradient(.fromBottom, start: 0, end: 0.2, startAlpha: 0.75, color: .black)
        }
    }
}
