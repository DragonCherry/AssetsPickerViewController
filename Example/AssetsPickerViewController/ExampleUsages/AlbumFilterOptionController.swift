//
//  AlbumFilterOptionController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 6/2/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AssetsPickerViewController
import Photos

class AlbumFilterOptionController: CommonExampleController {
    
    override func pressedPick(_ sender: Any) {
        
        let pickerConfig = AssetsPickerConfig()
        
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "estimatedAssetCount = 0")
        
        pickerConfig.albumFetchOptions = [
            .smartAlbum: options                                                                    // apply to smart albums only
        ]
        
        let picker = AssetsPickerViewController(pickerConfig: pickerConfig)
        picker.pickerDelegate = self
        present(picker, animated: true, completion: nil)
    }
}

