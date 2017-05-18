//
//  AssetsAlbumViewModel.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import Photos
import TinyLog

// MARK: - AssetsAlbumViewModelProtocol
public protocol AssetsAlbumViewModelProtocol {
    
    var smartAlbumArray: [PHAssetCollection] { get }
    var albumArray: [PHAssetCollection] { get }
    var numberOfSections: Int { get }
    
    func start()
    func count(ofType type: PHAssetCollectionType) -> Int
    func section(ofType type: PHAssetCollectionType) -> Int
}

// MARK: - AssetsAlbumViewModelDelegate
public protocol AssetsAlbumViewModelDelegate: class {
    func assetsAlbumViewModel(viewModel: AssetsAlbumViewModel, loadedAlbums: [PHAssetCollection], ofType type: PHAssetCollectionType)
    func assetsAlbumViewModel(viewModel: AssetsAlbumViewModel, removedAlbums: [PHAssetCollection], at indexPaths: [IndexPath])
    func assetsAlbumViewModel(viewModel: AssetsAlbumViewModel, removedAlbumsOfType type: PHAssetCollectionType)
    func assetsAlbumViewModel(viewModel: AssetsAlbumViewModel, addedAlbums: [PHAssetCollection], at indexPaths: [IndexPath])
}

// MARK: - AssetsAlbumViewModel
open class AssetsAlbumViewModel: NSObject, AssetsAlbumViewModelProtocol {
    
    weak var delegate: AssetsAlbumViewModelDelegate?
    
    
    
    // MARK: Albums
    fileprivate var smartAlbumMap = [String: PHAssetCollection]()
    fileprivate(set) open var smartAlbumArray = [PHAssetCollection]()
    fileprivate var albumMap = [String: PHAssetCollection]()
    fileprivate(set) open var albumArray = [PHAssetCollection]()
    
    open var numberOfSections: Int {
        var sectionCount: Int = 0
        if smartAlbumArray.count > 0 { sectionCount += 1 }
        if albumArray.count > 0 { sectionCount += 1 }
        return sectionCount
    }
    
    public override init() {
        super.init()
        registerObserver()
    }
    
    deinit {
        logd("Released \(type(of: self))")
        unregisterObserver()
    }
    
    open func start() {
        logi("Start fetching...")
        let smartAlbumFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        for i in 0..<smartAlbumFetchResult.count {
            let album = smartAlbumFetchResult.object(at: i)
            append(album: album, ofType: .smartAlbum)
        }
        delegate?.assetsAlbumViewModel(viewModel: self, loadedAlbums: smartAlbumArray, ofType: .smartAlbum)
        
        let albumFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        for i in 0..<albumFetchResult.count {
            let album = albumFetchResult.object(at: i)
            append(album: album, ofType: .album)
        }
        if albumArray.count > 0 {
            delegate?.assetsAlbumViewModel(viewModel: self, loadedAlbums: albumArray, ofType: .album)
        }
        logi("Finish fetching...")
    }
    
    open func count(ofType type: PHAssetCollectionType) -> Int {
        switch type {
        case .smartAlbum:
            return smartAlbumArray.count
        case .album:
            return albumArray.count
        default:
            return 0
        }
    }
    
    open func section(ofType type: PHAssetCollectionType) -> Int {
        switch type {
        case .smartAlbum:
            return smartAlbumArray.count == 0 ? -1 : 0
        case .album:
            return smartAlbumArray.count == 0 ? 0 : 1
        default:
            return -1
        }
    }
    
    // MARK: Observers
    open func registerObserver() { PHPhotoLibrary.shared().register(self) }
    open func unregisterObserver() { PHPhotoLibrary.shared().unregisterChangeObserver(self) }
}

// MARK: - Album Model Control
extension AssetsAlbumViewModel {
    
    func clearAlbums() {
        albumMap.removeAll()
        albumArray.removeAll()
    }
    
    func append(album: PHAssetCollection, ofType type: PHAssetCollectionType) {
        
        switch type {
        case .smartAlbum:
            if let album = smartAlbumMap[album.localIdentifier] {
                log("Album already exists: \(album.localizedTitle ?? album.localIdentifier)")
            } else {
                smartAlbumMap[album.localIdentifier] = album
                smartAlbumArray.append(album)
            }
        case .album:
            if let album = albumMap[album.localIdentifier] {
                log("Album already exists: \(album.localizedTitle ?? album.localIdentifier)")
            } else {
                albumMap[album.localIdentifier] = album
                albumArray.append(album)
            }
        default:
            logw("Album type \(type) is not supported.")
        }
    }
    
    func remove(album: PHAssetCollection, ofType type: PHAssetCollectionType) {
        
        switch type {
        case .smartAlbum:
            if let album = smartAlbumMap[album.localIdentifier], let albumIndex = smartAlbumArray.index(where: { $0.localIdentifier == album.localIdentifier }) {
                smartAlbumMap.removeValue(forKey: album.localIdentifier)
                smartAlbumArray.remove(at: albumIndex)
            }
        case .album:
            if let album = albumMap[album.localIdentifier], let albumIndex = albumArray.index(where: { $0.localIdentifier == album.localIdentifier }) {
                albumMap.removeValue(forKey: album.localIdentifier)
                albumArray.remove(at: albumIndex)
            }
        default:
            logw("Album type \(type) is not supported.")
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension AssetsAlbumViewModel: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        //        changeInstance.changeDetails(for: <#T##PHFetchResult<T>#>)
    }
}
