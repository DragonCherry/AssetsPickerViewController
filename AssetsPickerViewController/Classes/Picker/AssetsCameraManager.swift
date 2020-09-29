//
//  AssetsCameraManager.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 2020/07/02.
//

import Foundation
import AVFoundation
import Photos
import UIKit

protocol AssetsPickerManagerDelegate: NSObject {
    func assetsPickerManagerSavedAsset(identifier: String)
}

class AssetsPickerManager: NSObject {
    
    fileprivate var successCallback: ((Any?) -> Void)?
    fileprivate var cancelCallback: (() -> Void)?
    
    private let allowsEditing: Bool = true
    fileprivate var savedLocalIdentifier: String?
    
    var isAutoSave: Bool = true
    weak var delegate: AssetsPickerManagerDelegate?
    
    func requestTakePhoto(parent: UIViewController, success: ((Any?) -> Void)? = nil, cancel: (() -> Void)? = nil) {
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.sourceType = .camera
        controller.allowsEditing = allowsEditing
        self.successCallback = success
        self.cancelCallback = cancel
        parent.present(controller, animated: true, completion: nil)
    }
    
    func requestTake(parent: UIViewController, success: ((Any?) -> Void)? = nil, cancel: (() -> Void)? = nil) {
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.sourceType = .camera
        controller.allowsEditing = allowsEditing
        controller.mediaTypes = ["public.image", "public.movie"]
        self.successCallback = success
        self.cancelCallback = cancel
        parent.present(controller, animated: true, completion: nil)
    }
    
    func requestImage(parent: UIViewController, success: ((Any?) -> Void)? = nil, cancel: (() -> Void)? = nil) {
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.sourceType = .photoLibrary
        controller.allowsEditing = allowsEditing
        self.successCallback = success
        self.cancelCallback = cancel
        parent.present(controller, animated: true, completion: nil)
    }
}

extension AssetsPickerManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        picker.dismiss(animated: true, completion: { [weak self] in
            guard let `self` = self else { return }
            
            var mediaType: PHAssetMediaType = .unknown
            
            if let lowercasedMediaType = (info[convertFromUIImagePickerControllerInfoKey(.mediaType)] as? String)?.lowercased() {
                if lowercasedMediaType.contains("image") {
                    mediaType = .image
                } else if lowercasedMediaType.contains("movie") {
                    mediaType = .video
                }
            }
            
            switch mediaType {
            case .image:
                guard let image = (info[convertFromUIImagePickerControllerInfoKey(.editedImage)] as? UIImage) ?? (info[convertFromUIImagePickerControllerInfoKey(.originalImage)] as? UIImage) else {
                    self.successCallback?(nil)
                    return
                }
                if self.isAutoSave {
                    PHPhotoLibrary.shared().performChanges({
                        let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                        if let identifier = request.placeholderForCreatedAsset?.localIdentifier {
                            self.savedLocalIdentifier = identifier
                            self.successCallback?(image)
                        }
                    }) { [weak self] (isSuccess, _) in
                        if let localIdentifier = self?.savedLocalIdentifier, isSuccess {
                            self?.savedLocalIdentifier = nil
                            self?.delegate?.assetsPickerManagerSavedAsset(identifier: localIdentifier)
                        }
                        self?.successCallback?(image)
                    }
                } else {
                    self.successCallback?(image)
                }
            case .video:
                guard let videoFileURL = info[convertFromUIImagePickerControllerInfoKey(.mediaURL)] as? URL else {
                    self.successCallback?(nil)
                    return
                }
                if self.isAutoSave {
                    PHPhotoLibrary.shared().performChanges({
                        if let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoFileURL), let identifier = request.placeholderForCreatedAsset?.localIdentifier {
                            self.savedLocalIdentifier = identifier
                            self.successCallback?(videoFileURL)
                        } else {
                            self.successCallback?(videoFileURL)
                        }
                    }) { [weak self] (isSuccess, _) in
                        if let localIdentifier = self?.savedLocalIdentifier, isSuccess {
                            self?.savedLocalIdentifier = nil
                            self?.delegate?.assetsPickerManagerSavedAsset(identifier: localIdentifier)
                        }
                        self?.successCallback?(videoFileURL)
                    }
                } else {
                    self.successCallback?(videoFileURL)
                }
            default:
                self.successCallback?(nil)
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: { [weak self] in
            self?.cancelCallback?()
        })
    }
}

fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
