//
//  AssetFilterOptionController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 6/2/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AssetsPickerViewController
import Photos

class AssetFilterOptionController: CommonExampleController {
    
    override func pressedPick(_ sender: Any) {
        
        let pickerConfig = AssetsPickerConfig()
        
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "duration", ascending: true)]
        
        pickerConfig.assetFetchOptions = [
            .smartAlbum: options,
            .album: options
        ]
        
        let picker = AssetsPickerViewController(pickerConfig: pickerConfig)
        picker.pickerDelegate = self
        present(picker, animated: true, completion: nil)
    }
}

