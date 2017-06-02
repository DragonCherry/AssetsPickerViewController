//
//  AlbumFilterBlockController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 6/2/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AssetsPickerViewController
import Photos

class AlbumFilterBlockController: CommonExampleController {
    
    override func pressedPick(_ sender: Any) {
        
        let pickerConfig = AssetsPickerConfig()
        
        let smartAlbumFilter: ((PHAssetCollection, PHFetchResult<PHAsset>) -> Bool) = { (album, fetchResult) in
            
            // filter by album object
            if album.assetCollectionSubtype == .smartAlbumBursts { return false }
            if album.assetCollectionSubtype == .smartAlbumTimelapses { return false }
            if album.assetCollectionSubtype == .smartAlbumFavorites { return false }
            
            // filter by fetch result
            if fetchResult.count > 50 {
                return true     // only shows albums that contains more than 50 assets
            } else {
                return false
            }
        }
        pickerConfig.albumFilter = [
            .smartAlbum: smartAlbumFilter
        ]
        
        let picker = AssetsPickerViewController(pickerConfig: pickerConfig)
        picker.pickerDelegate = self
        present(picker, animated: true, completion: nil)
    }
}

