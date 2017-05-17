//
//  AssetsFetchManager.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import Foundation

public protocol AssetsAlbumChangedDelegate {
    
}

public protocol AssetsChangedDelegate {
    
}

open class AssetsFetchManager {
    open static var `default`: AssetsFetchManager = { return AssetsFetchManager() }()
    private init() {}
    
    open var assetsAlbumChangedDelegate: AssetsAlbumChangedDelegate?
    open var assetsChangedDelegate: AssetsChangedDelegate?
    
    
}
