//
//  AssetsEmptyView.swift
//  Pods
//
//  Created by DragonCherry on 5/26/17.
//
//

import UIKit
import SwiftARGB

open class AssetsEmptyView: AssetsGuideView {
    
    override func commonInit() {
        var messageKey = "Message_No_Items"
        if !UIImagePickerController.isCameraDeviceAvailable(.rear) {
            messageKey = "Message_No_Items_Camera"
        }
        set(title: String(key: "Title_No_Items"), message: String(format: String(key: messageKey), UIDevice.current.model))
        titleStyle = .title2
        super.commonInit()
    }
}
