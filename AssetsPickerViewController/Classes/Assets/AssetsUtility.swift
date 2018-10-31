//
//  AssetsUtility.swift
//  Pods
//
//  Created by DragonCherry on 5/19/17.
//
//

import Foundation
import Photos

open class AssetsUtility {
    
    public static func fetchOption(isIncludeImage: Bool = true, isIncludeVideo: Bool = true) -> PHFetchOptions {
        let options = PHFetchOptions()
        if isIncludeImage && isIncludeVideo {
            options.predicate = NSPredicate(format: "mediaType = %d OR mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        } else if isIncludeImage && !isIncludeVideo {
            options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        } else if !isIncludeImage && isIncludeVideo {
            options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        }
        return options
    }
    
    public static func sortedAssets(_ assets: [PHAsset], recentFirst: Bool = true) -> [PHAsset] {
        
        let sortedAssets = assets.sorted { (asset0, asset1) -> Bool in
            let order: ComparisonResult = recentFirst ? .orderedDescending : .orderedAscending
            
            var date0: Date?
            var date1: Date?
            
            if let modDate0 = asset0.modificationDate {
                date0 = modDate0
            }
            if let crDate0 = asset0.creationDate {
                if let modDate0 = asset0.modificationDate {
                    if crDate0.compare(modDate0) == order {
                        date0 = crDate0
                    } else {
                        date0 = modDate0
                    }
                }
            }
            
            if let modDate1 = asset1.modificationDate {
                date1 = modDate1
            }
            if let crDate1 = asset1.creationDate {
                if let modDate1 = asset1.modificationDate {
                    if crDate1.compare(modDate1) == order {
                        date1 = crDate1
                    } else {
                        date1 = modDate1
                    }
                }
            }
            
            if let date0 = date0, let date1 = date1 {
                return date0.compare(date1) == order
            } else {
                return false
            }
        }
        return sortedAssets
    }
}
