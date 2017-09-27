//
//  AssetsPickerConfig.swift
//  Pods
//
//  Created by DragonCherry on 5/22/17.
//
//

import UIKit
import Photos

open class AssetsPickerConfig {
    
    // MARK: - Album Config

    /// Set selected album at initial load.
    open var albumDefaultType: PHAssetCollectionSubtype = .smartAlbumUserLibrary
    /// true: shows empty albums, false: hides empty albums
    open var albumIsShowEmptyAlbum: Bool = true
    /// true: shows "Hidden" album, false: hides "Hidden" album
    open var albumIsShowHiddenAlbum: Bool = false
    /// Customize your own album list by providing filter block below.
    open var albumFilter: [
        PHAssetCollectionType: ((PHAssetCollection, PHFetchResult<PHAsset>) -> Bool)
    ]?
    
    /// Not yet fully implemeted, do not set this true until it's completed.
    open var albumIsShowMomentAlbums: Bool = false
    
    // MARK: Fetch
    open var albumFetchOptions: [PHAssetCollectionType: PHFetchOptions]?
    
    // MARK: Order
    /// by giving this comparator, albumFetchOptions going to be useless
    open var albumComparator: ((PHAssetCollectionType, (album: PHAssetCollection, result: PHFetchResult<PHAsset>), (album: PHAssetCollection, result: PHFetchResult<PHAsset>)) -> Bool)?
    
    // MARK: Cache
    private var _albumCacheSize: CGSize = .zero
    open var albumForcedCacheSize: CGSize?
    open var albumCacheSize: CGSize {
        if let forcedCacheSize = self.albumForcedCacheSize {
            return forcedCacheSize
        } else {
            return _albumCacheSize
        }
    }
    
    // MARK: Custom Layout
    open var albumCellType: AnyClass = AssetsAlbumCell.classForCoder()
    open var albumDefaultSpace: CGFloat = 20
    open var albumLineSpace: CGFloat = -1
    open let albumPortraitDefaultColumnCount: Int = UI_USER_INTERFACE_IDIOM() == .pad ? 3 : 2
    open var albumPortraitColumnCount: Int?
    open var albumPortraitForcedCellWidth: CGFloat?
    open var albumPortraitForcedCellHeight: CGFloat?
    open var albumPortraitCellSize: CGSize = .zero
    
    open let albumLandscapeDefaultColumnCount: Int = UI_USER_INTERFACE_IDIOM() == .pad ? 4 : 3
    open var albumLandscapeColumnCount: Int?
    open var albumLandscapeForcedCellWidth: CGFloat?
    open var albumLandscapeForcedCellHeight: CGFloat?
    open var albumLandscapeCellSize: CGSize = .zero
    
    func albumItemSpace(isPortrait: Bool) -> CGFloat {
        let size = isPortrait ? UIScreen.main.portraitSize : UIScreen.main.landscapeSize
        let count = CGFloat(isPortrait ? (albumPortraitColumnCount ?? albumPortraitDefaultColumnCount) : albumLandscapeColumnCount ?? albumLandscapeDefaultColumnCount)
        let albumCellSize = isPortrait ? albumPortraitCellSize : albumLandscapeCellSize
        let space = (size.width - count * albumCellSize.width) / (count + 1)
        return space
    }
    
    // MARK: - Asset Config
    
    // MARK: Asset
    open var selectedAssets: [PHAsset]?
    
    // MARK: Fetch
    open var assetFetchOptions: [PHAssetCollectionType: PHFetchOptions]?
    
    // MARK: Custom Layout
    open var assetCellType: AnyClass = AssetsPhotoCell.classForCoder()
    private var _assetCacheSize: CGSize = .zero
    open var assetForcedCacheSize: CGSize?
    open var assetCacheSize: CGSize {
        if let forcedCacheSize = self.assetForcedCacheSize {
            return forcedCacheSize
        } else {
            return _assetCacheSize
        }
    }
    open var assetPortraitColumnCount: Int = UI_USER_INTERFACE_IDIOM() == .pad ? 5 : 4
    open var assetPortraitInteritemSpace: CGFloat = 1
    open var assetPortraitLineSpace: CGFloat = 1
    lazy var assetPortraitCellSize: CGSize = {
        let count = CGFloat(self.assetPortraitColumnCount)
        let edge = (UIScreen.main.portraitSize.width - (count - 1) * self.assetPortraitInteritemSpace) / count
        return CGSize(width: edge, height: edge)
    }()
    open var assetLandscapeColumnCount: Int = 7
    open var assetLandscapeInteritemSpace: CGFloat = 1.5
    open var assetLandscapeLineSpace: CGFloat = 1.5
    lazy var assetLandscapeCellSize: CGSize = {
        let count = CGFloat(self.assetLandscapeColumnCount)
        let edge = (UIScreen.main.landscapeSize.width - (count - 1) * self.assetLandscapeInteritemSpace) / count
        return CGSize(width: edge, height: edge)
    }()
    
    public init() {}
    
    @discardableResult
    open func prepare() -> Self {
        
        let scale = UIScreen.main.scale
        
        /* initialize album attributes */
        
        // album line space
        if albumLineSpace < 0 {
            albumLineSpace = albumDefaultSpace
        }
        
        // initialize album cell size
        let albumPortraitCount = CGFloat(albumPortraitColumnCount ?? albumPortraitDefaultColumnCount)
        let albumPortraitWidth = (UIScreen.main.portraitSize.width - albumDefaultSpace * (albumPortraitCount + 1)) / albumPortraitCount
        albumPortraitCellSize = CGSize(
            width: albumPortraitForcedCellWidth ?? albumPortraitWidth,
            height: albumPortraitForcedCellHeight ?? albumPortraitWidth * 1.25
        )
        
        let albumLandscapeCount = CGFloat(albumLandscapeColumnCount ?? albumLandscapeDefaultColumnCount)
        var albumLandscapeWidth: CGFloat = 0
        if let _ = albumPortraitColumnCount {
            albumLandscapeWidth = (UIScreen.main.landscapeSize.width - albumDefaultSpace * (albumLandscapeCount + 1)) / albumLandscapeCount
        } else {
            albumLandscapeWidth = albumPortraitWidth
        }
        albumLandscapeCellSize = CGSize(
            width: albumLandscapeForcedCellWidth ?? albumLandscapeWidth,
            height: albumLandscapeForcedCellHeight ?? albumLandscapeWidth * 1.25
        )
        
        // initialize cache size for album thumbnail
        _albumCacheSize = CGSize(width: albumPortraitWidth * scale, height: albumPortraitWidth * scale)
        
        
        /* initialize asset attributes */
        
        // initialize cache size for asset thumbnail
        let assetPivotCount = CGFloat(assetPortraitColumnCount)
        let assetWidth = (UIScreen.main.portraitSize.width - (assetPivotCount - 1) * assetPortraitInteritemSpace) / assetPivotCount
        
        _assetCacheSize = CGSize(width: assetWidth * scale, height: assetWidth * scale)
        
        // asset fetch options by default
        if assetFetchOptions == nil {
            let options = PHFetchOptions()
            options.includeHiddenAssets = albumIsShowHiddenAlbum
            options.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: true),
                NSSortDescriptor(key: "modificationDate", ascending: true)
            ]
            options.predicate = NSPredicate(format: "mediaType = %d OR mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
            assetFetchOptions = [
                .smartAlbum: options,
                .album: options,
                .moment: options
            ]
        }
        
        return self
    }
}
