//
//  AlbumOrderOptionController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 6/2/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AssetsPickerViewController
import Photos

class AlbumOrderOptionController: CommonExampleController {
    
    override func pressedPick(_ sender: Any) {
        
        let pickerConfig = AssetsPickerConfig()
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "estimatedAssetCount", ascending: true)]
        
        pickerConfig.albumFetchOptions = [
            .smartAlbum: options
        ]
        
        let picker = AssetsPickerViewController(pickerConfig: pickerConfig)
        picker.pickerDelegate = self
        present(picker, animated: true, completion: nil)
    }
}
