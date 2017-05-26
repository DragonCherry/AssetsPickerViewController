//
//  AssetsNoPermissionView.swift
//  Pods
//
//  Created by DragonCherry on 5/26/17.
//
//

import UIKit
import SwiftARGB

open class AssetsNoPermissionView: AssetsGuideView {
   
    override func commonInit() {
        set(title: String(key: "Title_No_Permission"), message: String(key: "Message_No_Permission"))
        super.commonInit()
    }
}
