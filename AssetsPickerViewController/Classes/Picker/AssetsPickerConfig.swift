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
    
    open var defaultAlbumType: PHAssetCollectionSubtype = .smartAlbumUserLibrary
    open var isShowEmptyAlbum: Bool = true
    open var thumbnailCacheSize: CGSize = .zero
    open var isShowSelectedSequence: Bool = true
    
    open var fetchOptions: PHFetchOptions
    
    open var portraitColumnCount: Int = 4
    open var portraitInteritemSpace: CGFloat = 1
    open var portraitLineSpace: CGFloat = 1
    lazy var portraitCellSize: CGSize = {
        let count = CGFloat(self.portraitColumnCount)
        let edge = (UIScreen.main.portraitSize.width - (count - 1) * self.portraitInteritemSpace) / count
        return CGSize(width: edge, height: edge)
    }()
    
    open var landscapeColumnCount: Int = 7
    open var landscapeInteritemSpace: CGFloat = 1.5
    open var landscapeLineSpace: CGFloat = 1.5
    lazy var landscapeCellSize: CGSize = {
        let count = CGFloat(self.landscapeColumnCount)
        let edge = (UIScreen.main.landscapeSize.width - (count - 1) * self.landscapeInteritemSpace) / count
        return CGSize(width: edge, height: edge)
    }()
    
    public init() {
        // prepare common attributes
        let count = CGFloat(portraitColumnCount)
        let edge = (UIScreen.main.portraitSize.width - (count - 1) * portraitInteritemSpace) / count
        let scale = UIScreen.main.scale
        thumbnailCacheSize = CGSize(width: edge * scale, height: edge * scale)
        
        // fetch options
        fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true),
            NSSortDescriptor(key: "modificationDate", ascending: true)
        ]
        
        // prepare portrait attributes
        
        
        
        // prepare landscape attributes
        
        
    }
}
