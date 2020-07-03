//
//  SwiftAlert.swift
//  Pods
//
//  Created by DragonCherry on 1/10/17.
//
//

import UIKit

@available(iOS 8.0, *)
@objcMembers public class SwiftAlert: NSObject {
    
    fileprivate weak var parent: UIViewController?
    fileprivate var alertController: UIAlertController?
    fileprivate var forceDismiss: Bool = false
    public var isShowing: Bool = false
    
    fileprivate var dismissHandler: ((Int) -> Void)?
    fileprivate var cancelHandler: (() -> Void)?
    fileprivate var destructHandler: (() -> Void)?
    
    fileprivate var promptHandler: ((Int, String?) -> Void)?
    fileprivate var promptTextField: UITextField?
    
    public required override init() {
        super.init()
    }
    
    public func show(
        _ parent: UIViewController,
        style: UIAlertController.Style = .alert,
        title: String? = nil,
        message: String?,
        dismissTitle: String) {
        
        self.show(
            parent,
            style: style,
            title: title,
            message: message,
            cancelTitle: nil,
            cancel: nil,
            otherTitles: [dismissTitle],
            dismiss: nil)
    }
    
    public func show(
        _ parent: UIViewController,
        style: UIAlertController.Style = .alert,
        title: String? = nil,
        message: String?,
        dismissTitle: String,
        dismiss: (() -> Void)?) {
        
        self.show(
            parent,
            style: style,
            title: title,
            message: message,
            cancelTitle: dismissTitle,
            cancel: { dismiss?() },
            otherTitles: nil,
            dismiss: nil)
    }
    
    public func show(
        _ parent: UIViewController,
        style: UIAlertController.Style = .alert,
        title: String? = nil,
        message: String? = nil,
        cancelTitle: String? = nil,
        cancel: (() -> Void)? = nil,
        otherTitles: [String]? = nil,
        dismiss: ((Int) -> Void)? = nil,
        destructTitle: String? = nil,
        destruct: (() -> Void)? = nil) {
        
        close(false)
        
        self.parent = parent
        self.dismissHandler = dismiss
        self.cancelHandler = cancel
        self.destructHandler = destruct
        
        self.alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        guard let alertController = self.alertController else {
            return
        }
        
        if let otherTitles = otherTitles {
            for (index, otherTitle) in otherTitles.enumerated() {
                let dismissAction: UIAlertAction = UIAlertAction(title: otherTitle, style: .default, handler: { action in
                    self.dismissHandler?(index)
                    self.clear()
                })
                alertController.addAction(dismissAction)
            }
        }
        
        if let cancelTitle = cancelTitle {
            let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: { action in
                self.cancelHandler?()
                self.clear()
            })
            alertController.addAction(cancelAction)
        }
        
        if let destructTitle = destructTitle {
            let destructAction: UIAlertAction = UIAlertAction(title: destructTitle, style: .destructive, handler: { action in
                self.destructHandler?()
                self.clear()
            })
            alertController.addAction(destructAction)
        }
        
        if let parent = self.parent {
            parent.present(alertController, animated: true, completion: nil)
        } else {
            print("Cannot find parent while presenting alert.")
        }
        
        self.isShowing = true
    }
    
    public func prompt(
        
        _ parent: UIViewController,
        title: String? = nil,
        message: String?,
        placeholder: String? = nil,
        defaultText: String? = nil,
        isNumberOnly: Bool = false,
        isSecure: Bool = true,
        cancelTitle: String? = nil,
        cancel: (() -> Void)? = nil,
        otherTitles: [String]? = nil,
        prompt: ((Int, String?) -> Void)? = nil) {
        
        close(false)
        
        self.parent = parent
        self.promptHandler = prompt
        self.cancelHandler = cancel
        
        self.alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        guard let alertController = self.alertController else {
            return
        }
        
        alertController.addTextField(configurationHandler: { textField in
            if isNumberOnly {
                textField.keyboardType = .numberPad
            }
            textField.text = defaultText
            textField.isSecureTextEntry = isSecure
            if let placeholder = placeholder {
                textField.placeholder = placeholder
            }
            self.promptTextField = textField
        })
        
        if let otherTitles = otherTitles {
            for (index, otherTitle) in otherTitles.enumerated() {
                let dismissAction: UIAlertAction = UIAlertAction(title: otherTitle, style: .default, handler: { action in
                    self.promptTextField?.resignFirstResponder()
                    self.promptHandler?(index, self.promptTextField!.text)
                    self.clear()
                })
                alertController.addAction(dismissAction)
            }
        }
        
        if let cancelTitle = cancelTitle {
            let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: { action in
                self.promptTextField?.resignFirstResponder()
                self.cancelHandler?()
                self.clear()
            })
            alertController.addAction(cancelAction)
        }
        
        if let parent = self.parent {
            parent.present(alertController, animated: true, completion: nil)
        } else {
            print("Cannot find parent while presenting alert.")
        }
        
        isShowing = true
    }
    
    fileprivate func autoDismiss() {
        close()
    }
    
    public func close(_ animated: Bool = true, completion: (() -> Void)? = nil) {
        if isShowing {
            alertController?.dismiss(animated: animated, completion: {
                completion?()
            })
        }
        clear()
        isShowing = false
    }
    
    private func clear() {
        self.parent = nil
        self.alertController = nil
        self.promptTextField = nil
        self.cancelHandler = nil
        self.dismissHandler = nil
        self.destructHandler = nil
    }
}

