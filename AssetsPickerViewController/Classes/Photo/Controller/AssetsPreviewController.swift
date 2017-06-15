//
//  AssetsPreviewController.swift
//  Pods
//
//  Created by AssetsPreviewController on 6/15/17.
//
//

import UIKit
import Photos

open class AssetsPreviewController: UIViewController {
    
    private var didSetupConstraints = false
    open var asset: PHAsset? {
        didSet {
            if let asset = self.asset {
                PHCachingImageManager.default().requestImage(
                    for: asset,
                    targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                    contentMode: .aspectFill,
                    options: nil,
                    resultHandler: { (image, _) in
                        self.imageView.image = image
                })
            } else {
                imageView.image = nil
            }
        }
    }
    
    let imageView: UIImageView = {
        let view = UIImageView.newAutoLayout()
        view.clipsToBounds = false
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    override open func loadView() {
        super.loadView()
        view = UIView()
        view.backgroundColor = .white
        view.addSubview(imageView)
        view.setNeedsUpdateConstraints()
    }
    
    override open func updateViewConstraints() {
        if !didSetupConstraints {
            imageView.autoPinEdgesToSuperviewEdges()
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }
}
