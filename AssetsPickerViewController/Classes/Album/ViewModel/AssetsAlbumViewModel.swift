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
    
    var albumsArray: [[PHAssetCollection]] { get }
    var numberOfSections: Int { get }
    
    func start()
    func numberOfItems(inSection: Int) -> Int
    func numberOfAssets(at indexPath: IndexPath) -> Int
    func title(at indexPath: IndexPath) -> String?
}

// MARK: - AssetsAlbumViewModelDelegate
public protocol AssetsAlbumViewModelDelegate: class {
    func assetsAlbumViewModel(viewModel: AssetsAlbumViewModel, createdSection section: Int)
    func assetsAlbumViewModel(viewModel: AssetsAlbumViewModel, removedSection section: Int)
    func assetsAlbumViewModel(viewModel: AssetsAlbumViewModel, removedAlbums: [PHAssetCollection], at indexPaths: [IndexPath])
    func assetsAlbumViewModel(viewModel: AssetsAlbumViewModel, addedAlbums: [PHAssetCollection], at indexPaths: [IndexPath])
}

// MARK: - AssetsAlbumViewModel
open class AssetsAlbumViewModel: NSObject, AssetsAlbumViewModelProtocol {
    
    weak var delegate: AssetsAlbumViewModelDelegate?
    
    fileprivate var albumMap = [String: PHAssetCollection]()
    fileprivate var fetchResults = [[PHFetchResult<PHAsset>]]()
    
    public override init() {
        super.init()
        registerObserver()
    }
    
    deinit {
        logd("Released \(type(of: self))")
        unregisterObserver()
    }
    
    // MARK: AssetsAlbumViewModelProtocol
    fileprivate(set) open var albumsArray = [[PHAssetCollection]]()
    
    open var numberOfSections: Int {
        return albumsArray.count
    }
    
    open func start() {
        logi("Start fetching...")
        let smartAlbumFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        var smartAlbums = [PHAssetCollection]()
        smartAlbumFetchResult.enumerateObjects({ (album, _, _) in
            smartAlbums.append(album)
            
            self.albumMap[album.localIdentifier] = album
        })
        albumsArray.append(smartAlbums)
        delegate?.assetsAlbumViewModel(viewModel: self, createdSection: 0)
    
        let albumFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        var albums = [PHAssetCollection]()
        albumFetchResult.enumerateObjects({ (album, _, _) in
            albums.append(album)
            self.albumMap[album.localIdentifier] = album
        })
        albumsArray.append(albums)
        delegate?.assetsAlbumViewModel(viewModel: self, createdSection: 1)
        
        logi("Finish fetching...")
    }
    
    open func numberOfItems(inSection: Int) -> Int {
        return albumsArray[inSection].count
    }
    
    open func numberOfAssets(at indexPath: IndexPath) -> Int {
//        let fetchResult = PHAsset.fetchAssets(in: <#T##PHAssetCollection#>, options: <#T##PHFetchOptions?#>)
        return 0
    }
    
    open func title(at indexPath: IndexPath) -> String? {
        let album = albumsArray[indexPath.section][indexPath.row]
        return album.localizedTitle
    }
    
    // MARK: Observers
    open func registerObserver() { PHPhotoLibrary.shared().register(self) }
    open func unregisterObserver() { PHPhotoLibrary.shared().unregisterChangeObserver(self) }
}

// MARK: - Album Model Control
extension AssetsAlbumViewModel {
    
    func clearAlbums() {
        albumMap.removeAll()
        albumsArray.removeAll()
    }
    
    func append(albums: [PHAssetCollection], inSection: Int) {
        
    }
    
    func append(album: PHAssetCollection, inSection: Int) {
        if let album = albumMap[album.localIdentifier] {
            log("Album already exists: \(album.localizedTitle ?? album.localIdentifier)")
        } else {
            albumMap[album.localIdentifier] = album
            albumsArray[inSection].append(album)
        }
    }
    
    func insert(album: PHAssetCollection, at indexPath: IndexPath) {
        albumMap[album.localIdentifier] = album
        albumsArray[indexPath.section].insert(album, at: indexPath.row)
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension AssetsAlbumViewModel: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        //        changeInstance.changeDetails(for: <#T##PHFetchResult<T>#>)
    }
}
