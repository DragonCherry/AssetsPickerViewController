//
//  BasicUsageController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 5/17/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import AssetsPickerViewController

class BasicUsageController: CommonExampleController {
    
    override func pressedPick(_ sender: Any) {
        let picker = AssetsPickerViewController()
        picker.pickerDelegate = self
        present(picker, animated: true, completion: nil)
    }
}
