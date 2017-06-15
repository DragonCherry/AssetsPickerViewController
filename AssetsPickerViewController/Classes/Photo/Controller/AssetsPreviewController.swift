//
//  AssetsPreviewController.swift
//  Pods
//
//  Created by AssetsPreviewController on 6/15/17.
//
//

import UIKit
import Photos
import PhotosUI
import TinyLog
import OptionalTypes

open class AssetsPreviewController: UIViewController {
    
    private var didSetupConstraints = false
    open var asset: PHAsset? {
        didSet {
            guard let asset = self.asset else {
                if #available(iOS 9.1, *) {
                    self.livePhotoView.livePhoto = nil
                }
                self.imageView.image = nil
                logw("Received empty asset. Setting preview with nil content.")
                return
            }
            if #available(iOS 9.1, *) {
                imageView.isHidden = true
                livePhotoView.isHidden = false
                if let asset = self.asset {
                    PHCachingImageManager.default().requestLivePhoto(
                        for: asset,
                        targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                        contentMode: .aspectFill,
                        options: nil,
                        resultHandler: { (livePhoto, info) in
                            if let livePhoto = livePhoto, !Bool(info?[PHImageResultIsDegradedKey]) && info?[PHImageErrorKey] == nil {
                                self.livePhotoView.livePhoto = livePhoto
                                self.livePhotoView.startPlayback(with: .full)
                            } else {
                                self.imageView.isHidden = false
                                self.image(forAsset: asset, completion: { (image) in
                                    self.imageView.image = image
                                })
                            }
                    })
                }
            } else {
                imageView.isHidden = false
                self.image(forAsset: asset, completion: { (image) in
                    self.imageView.image = image
                })
            }
        }
    }
    
    let imageView: UIImageView = {
        let view = UIImageView.newAutoLayout()
        view.clipsToBounds = false
        view.contentMode = .scaleAspectFill
        return view
    }()
    @available(iOS 9.1, *)
    lazy var livePhotoView: PHLivePhotoView = {
        let view = PHLivePhotoView.newAutoLayout()
        view.delegate = self
        return view
    }()
    
    override open func loadView() {
        super.loadView()
        view = UIView()
        view.backgroundColor = .white
        view.addSubview(imageView)
        if #available(iOS 9.1, *) {
            view.addSubview(livePhotoView)
        }
        view.setNeedsUpdateConstraints()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override open func updateViewConstraints() {
        if !didSetupConstraints {
            imageView.autoPinEdgesToSuperviewEdges()
            if #available(iOS 9.1, *) {
                livePhotoView.autoPinEdgesToSuperviewEdges()
            }
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }
}

extension AssetsPreviewController {
    open func image(forAsset asset: PHAsset, completion: @escaping ((UIImage?) -> Void)) {
        PHCachingImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
            contentMode: .aspectFill,
            options: nil,
            resultHandler: { (image, info) in
                completion(image)
        })
    }
}

extension AssetsPreviewController: PHLivePhotoViewDelegate {
    @available(iOS 9.1, *)
    public func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {}
    
    @available(iOS 9.1, *)
    public func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {}
}
