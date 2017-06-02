//
//  AlbumOrderBlockController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 6/2/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AssetsPickerViewController

class AlbumOrderBlockController: CommonExampleController {
    
    override func pressedPick(_ sender: Any) {
        
        let pickerConfig = AssetsPickerConfig()
        
        // Priority of this option is higher than PHFetchOptions.
        pickerConfig.albumComparator = { (albumType, leftEntry, rightEntry) -> Bool in
            
            // return: Is leftEntry ordered before the rightEntry?
            switch albumType {
            case .smartAlbum:
                return leftEntry.album.assetCollectionSubtype.rawValue < rightEntry.album.assetCollectionSubtype.rawValue
            case .album:
                return leftEntry.result.count < rightEntry.result.count     // ascending order by asset count
            case .moment:
                return true
            }
        }
        
        let picker = AssetsPickerViewController(pickerConfig: pickerConfig)
        picker.pickerDelegate = self
        present(picker, animated: true, completion: nil)
    }
}

