//
//  AssetsCameraManager.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 2020/07/02.
//

import Foundation
import AVFoundation

class AssetsPickerManager: NSObject {
    
    fileprivate var successCallback: ((UIImage?) -> Void)?
    fileprivate var cancelCallback: (() -> Void)?
    private let allowsEditing: Bool = false
    
    func requestTakePhoto(parent: UIViewController, success: ((UIImage?) -> Void)? = nil, cancel: (() -> Void)? = nil) {
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.sourceType = .camera
        controller.allowsEditing = allowsEditing
        self.successCallback = success
        self.cancelCallback = cancel
        parent.present(controller, animated: true, completion: nil)
    }
    
    func requestImage(parent: UIViewController, success: ((UIImage?) -> Void)? = nil, cancel: (() -> Void)? = nil) {
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
            self?.successCallback?((info[convertFromUIImagePickerControllerInfoKey(.originalImage)] as? UIImage) ?? (info[convertFromUIImagePickerControllerInfoKey(.editedImage)] as? UIImage))
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
