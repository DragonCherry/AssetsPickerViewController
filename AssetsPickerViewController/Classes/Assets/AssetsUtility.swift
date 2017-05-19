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
    
//    open static func assetWithLocalIdentifier(_ localIdentifier: String) -> PHAsset? {
//        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
//        return fetchResult.firstObject as PHAsset?
//    }
//    
//    open static func allAssets(_ recentFirst: Bool = true, includeImage: Bool = true, includeVideo: Bool = true) -> [PHAsset] {
//        
//        var assets = [PHAsset]()
//        var results = [PHFetchResult<PHAsset>]()
//        var existanceTable = [String: Bool]()
//        
//        let options = AssetsUtility.optionForMediaTypes(includeImage, includeVideo: includeVideo)
//        
//        let smartAlbumResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
//        let smartAlbumCollectionCount = smartAlbumResult.count
//        for i in 0..<smartAlbumCollectionCount {
//            let smartAlbumCollection = smartAlbumResult.object(at: i)
//            results.append(PHAsset.fetchAssets(in: smartAlbumCollection, options: options))
//        }
//        
//        let albumResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
//        let albumCollectionCount = albumResult.count
//        for i in 0..<albumCollectionCount {
//            let albumCollection = albumResult.object(at: i)
//            results.append(PHAsset.fetchAssets(in: albumCollection, options: options))
//        }
//        
//        for result in results {
//            let count = result.count
//            for i in 0..<count {
//                let asset = result.object(at: i)
//                if let exists = existanceTable[asset.localIdentifier], exists {
//                    // pass
//                } else {
//                    existanceTable[asset.localIdentifier] = true
//                    assets.append(asset)
//                }
//            }
//        }
//        
//        return AssetsUtility.sortedAssets(assets, recentFirst: recentFirst)
//    }
//    
//    open static func assetsWithCollection(_ collection: PHAssetCollection?, recentFirst: Bool = true, includeImage: Bool = true, includeVideo: Bool = true) -> [PHAsset] {
//        
//        guard let collection = collection else {
//            return AssetsUtility.allAssets(recentFirst, includeImage: includeImage, includeVideo: includeVideo)
//        }
//        
//        let options = AssetsUtility.optionForMediaTypes(includeImage, includeVideo: includeVideo)
//        
//        var assets = [PHAsset]()
//        let result = PHAsset.fetchAssets(in: collection, options: options)
//        
//        for i in 0..<result.count {
//            let asset = result.object(at: i)
//            assets.append(asset)
//        }
//        return AssetsUtility.sortedAssets(assets)
//    }
    
    open static func fetchOption(isIncludeImage: Bool = true, isIncludeVideo: Bool = true) -> PHFetchOptions {
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
    
    open static func sortedAssets(_ assets: [PHAsset], recentFirst: Bool = true) -> [PHAsset] {
        
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
