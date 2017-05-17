//
//  AssetsAlbumViewModel.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit

// MARK: - AssetsAlbumViewModelProtocol
public protocol AssetsAlbumViewModelProtocol {
    var count: Int { get }
}

// MARK: - AssetsAlbumViewModelDelegate
public protocol AssetsAlbumViewModelDelegate {
    
    
}

// MARK: - AssetsAlbumViewModel
open class AssetsAlbumViewModel: AssetsAlbumViewModelProtocol {
    var delegate: AssetsAlbumViewModelDelegate?
    public var count: Int {
        return 0
    }
}
