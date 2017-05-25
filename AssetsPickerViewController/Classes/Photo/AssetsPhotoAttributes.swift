//
//  AssetsPhotoAttributes.swift
//  Pods
//
//  Created by DragonCherry on 5/22/17.
//
//

import UIKit
import Photos

open class AssetsPhotoAttributes {
    
    open static var thumbnailCacheSize: CGSize = .zero
    open static var isShowSelectedSequence: Bool = true
    
    open static var fetchOptions: PHFetchOptions {
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true),
            NSSortDescriptor(key: "modificationDate", ascending: true)
        ]
        return assetFetchOptions
    }
    
    open static var portraitColumnCount: Int = 4
    open static var portraitInteritemSpace: CGFloat = 1
    open static var portraitLineSpace: CGFloat = 1
    open static var portraitCellSize: CGSize = {
        let count = CGFloat(AssetsPhotoAttributes.portraitColumnCount)
        let edge = (UIScreen.main.portraitSize.width - (count - 1) * portraitInteritemSpace) / count
        return CGSize(width: edge, height: edge)
    }()
    
    open static var landscapeColumnCount: Int = 7
    open static var landscapeInteritemSpace: CGFloat = 1.5
    open static var landscapeLineSpace: CGFloat = 1.5
    open static var landscapeCellSize: CGSize = {
        let count = CGFloat(AssetsPhotoAttributes.landscapeColumnCount)
        let edge = (UIScreen.main.landscapeSize.width - (count - 1) * landscapeInteritemSpace) / count
        return CGSize(width: edge, height: edge)
    }()
    
    open static func prepare() {
        
        // prepare common attributes
        let count = CGFloat(portraitColumnCount)
        let edge = (UIScreen.main.portraitSize.width - (count - 1) * portraitInteritemSpace) / count
        let scale = UIScreen.main.scale
        thumbnailCacheSize = CGSize(width: edge * scale, height: edge * scale)
        
        
        // prepare portrait attributes
        
        
        
        // prepare landscape attributes
        
        
    }
}
