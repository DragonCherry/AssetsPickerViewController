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

open class AssetsPreviewController: UIViewController {
    
    private var didSetupConstraints = false
    
    fileprivate var player: AVPlayer?
    fileprivate var playerLayer: AVPlayerLayer?
    
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
            updatePreferredContentSize(forAsset: asset, isPortrait: UIApplication.shared.statusBarOrientation.isPortrait)
            if asset.mediaType == .image {
                if #available(iOS 9.1, *) {
                    imageView.isHidden = true
                    livePhotoView.isHidden = false
                    
                    let options = PHLivePhotoRequestOptions()
                    options.isNetworkAccessAllowed = true
                    options.deliveryMode = .opportunistic
                    
                    if asset.mediaSubtypes == .photoLive {
                        PHCachingImageManager.default().requestLivePhoto(
                            for: asset,
                            targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                            contentMode: .aspectFill,
                            options: options,
                            resultHandler: { (livePhoto, info) in
                                if let livePhoto = livePhoto, info?[PHImageErrorKey] == nil {
                                    self.livePhotoView.livePhoto = livePhoto
                                    self.livePhotoView.startPlayback(with: .full)
                                } else {
                                    self.imageView.isHidden = false
                                    self.image(forAsset: asset, isNeedDegraded: false, completion: { self.imageView.image = $0 })
                                }
                        })
                    } else {
                        self.imageView.isHidden = false
                        self.image(forAsset: asset, isNeedDegraded: false, completion: { self.imageView.image = $0 })
                    }
                    
                } else {
                    imageView.isHidden = false
                    self.image(forAsset: asset, isNeedDegraded: false, completion: { (image) in
                        self.imageView.image = image
                    })
                }
            } else {
                if #available(iOS 9.1, *) {
                    livePhotoView.isHidden = true
                }
                PHCachingImageManager.default().requestAVAsset(
                    forVideo: asset,
                    options: nil,
                    resultHandler: { (avasset, audio, info) in
                        DispatchQueue.main.async {
                            self.imageView.isHidden = false
                            if let avasset = avasset {
                                let playerItem = AVPlayerItem(asset: avasset)
                                let player = AVPlayer(playerItem: playerItem)
                                let playerLayer = AVPlayerLayer(player: player)
                                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
                                playerLayer.masksToBounds = true
                                playerLayer.frame = self.imageView.bounds
                                
                                self.imageView.layer.addSublayer(playerLayer)
                                self.playerLayer = playerLayer
                                self.player = player
                                
                                player.play()
                                
                            } else {
                                self.image(forAsset: asset, completion: { (image) in
                                    self.imageView.image = image
                                })
                            }
                        }
                        
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
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let asset = self.asset {
            updatePreferredContentSize(forAsset: asset, isPortrait: size.height > size.width)
        }
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
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = imageView.bounds
    }
    
    deinit {
        player?.pause()
        logd("Released \(type(of: self))")
    }
}

extension AssetsPreviewController {
    open func image(forAsset asset: PHAsset, isNeedDegraded: Bool = true, completion: @escaping ((UIImage?) -> Void)) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        PHCachingImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
            contentMode: .aspectFit,
            options: options,
            resultHandler: { (image, info) in
                if !isNeedDegraded {
                    if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                        return
                    }
                }
                completion(image)
        })
    }
    
    open func updatePreferredContentSize(forAsset asset: PHAsset, isPortrait: Bool) {
        guard asset.pixelWidth != 0 && asset.pixelHeight != 0 else { return }
        
        let contentScale: CGFloat = 1
        let assetWidth = CGFloat(asset.pixelWidth)
        let assetHeight = CGFloat(asset.pixelHeight)
        let assetRatio = assetHeight / assetWidth
        let screenWidth = isPortrait ? UIScreen.main.bounds.width : UIScreen.main.bounds.height
        let screenHeight = isPortrait ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        let screenRatio = screenHeight / screenWidth
        
        if assetRatio > screenRatio {
            // fit to height
            let scale = screenHeight / assetHeight
            preferredContentSize = CGSize(width: assetWidth * scale * contentScale, height: assetHeight * scale * contentScale)
        } else {
            // fit to width
            let scale = screenWidth / assetWidth
            preferredContentSize = CGSize(width: assetWidth * scale * contentScale, height: assetHeight * scale * contentScale)
        }
        
        logi("preferredContentSize: \(preferredContentSize)")
    }
}

extension AssetsPreviewController: PHLivePhotoViewDelegate {
    @available(iOS 9.1, *)
    public func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {}
    
    @available(iOS 9.1, *)
    public func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {}
}

