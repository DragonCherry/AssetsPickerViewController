//
//  AssetsFetchManager.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import Foundation
import Photos

public protocol AssetsAlbumChangedDelegate {
    
}

public protocol AssetsChangedDelegate {
    
}

open class AssetsFetchManager: NSObject {
    
    open static var `default`: AssetsFetchManager = { return AssetsFetchManager() }()
    
    
    private override init() {}
    
    open var assetsAlbumChangedDelegate: AssetsAlbumChangedDelegate?
    open var assetsChangedDelegate: AssetsChangedDelegate?
    
    // MARK: Albums
    fileprivate var albumResult: PHFetchResult<PHAssetCollection>?
    fileprivate var smartAlbumResult: PHFetchResult<PHAssetCollection>?
    
    // MARK: Assets
    fileprivate var resultOfAlbum = [String: PHFetchResult<PHAsset>]()
    
    open func watchAlbums(isReload: Bool = false) {
        if isReload {
            albumResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            smartAlbumResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        }
        
    }
    
    open func registerObserver() {
        PHPhotoLibrary.shared().register(self)
    }
    
    open func unregisterObserver() {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

extension AssetsFetchManager: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
//        changeInstance.changeDetails(for: <#T##PHFetchResult<T>#>)
    }
}
