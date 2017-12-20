//
//  ShowHiddenAlbumController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 6/1/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import AssetsPickerViewController

class ShowHiddenAlbumController: CommonExampleController {
    
    override func pressedPick(_ sender: Any) {
        
        let pickerConfig = AssetsPickerConfig()
        pickerConfig.albumIsShowHiddenAlbum = true
        
        let picker = AssetsPickerViewController(pickerConfig: pickerConfig)
        picker.pickerDelegate = self
        present(picker, animated: true, completion: nil)
    }
}
