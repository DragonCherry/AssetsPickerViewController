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
    open var albumDefaultType: PHAssetCollectionSubtype = .smartAlbumUserLibrary
    open var albumIsShowEmptyAlbum: Bool = true
    open var albumIsShowHiddenAlbum: Bool = true
    /// Not yet fully implemeted, do not set this true until it's completed.
    open var albumIsShowMomentAlbums: Bool = false
    
    // MARK: Fetch
    open var albumFetchOptions: [PHAssetCollectionType: PHFetchOptions]?
    
    // MARK: Order
    /// by giving this comparator, albumFetchOptions going to be useless
    open var albumComparator: [
        PHAssetCollectionType: ((PHAssetCollectionType, (PHAssetCollection, PHFetchResult<PHAsset>), (PHAssetCollection, PHFetchResult<PHAsset>)) -> Bool)
    ]?
    
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
    open var albumPortraitColumnCount: Int = 2
    open var albumPortraitForcedCellHeight: CGFloat?
    open var albumPortraitCellSize: CGSize = .zero
    
    open var albumLandscapeColumnCount: Int = 3
    open var albumLandscapeForcedCellHeight: CGFloat?
    open var albumLandscapeCellSize: CGSize = .zero
    
    func albumItemSpace(isPortrait: Bool) -> CGFloat {
        let size = isPortrait ? UIScreen.main.portraitSize : UIScreen.main.landscapeSize
        let count = CGFloat(isPortrait ? albumPortraitColumnCount : albumLandscapeColumnCount)
        let albumCellSize = isPortrait ? albumPortraitCellSize : albumLandscapeCellSize
        let space = (size.width - count * albumCellSize.width) / (count + 1)
        return space
    }
    
    // MARK: - Asset Config
    open var assetIsShowSelectedSequence: Bool = true
    
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
    open var assetPortraitColumnCount: Int = 4
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
        let albumPortraitCount = CGFloat(self.albumPortraitColumnCount)
        let albumPortraitWidth = (UIScreen.main.portraitSize.width - self.albumDefaultSpace * (albumPortraitCount + 1)) / albumPortraitCount
        albumPortraitCellSize = CGSize(width: albumPortraitWidth, height: albumPortraitForcedCellHeight ?? albumPortraitWidth * 1.25)
        
        let albumLandscapeCount = CGFloat(self.albumLandscapeColumnCount)
        let albumLandscapeWidth = (UIScreen.main.landscapeSize.width - self.albumDefaultSpace * (albumLandscapeCount + 1)) / albumLandscapeCount
        albumLandscapeCellSize = CGSize(width: albumLandscapeWidth, height: albumLandscapeForcedCellHeight ?? albumLandscapeWidth * 1.25)
        
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
            options.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: true),
                NSSortDescriptor(key: "modificationDate", ascending: true)
            ]
            assetFetchOptions = [
                .smartAlbum: options,
                .album: options,
                .moment: options
            ]
        }
        
        return self
    }
}