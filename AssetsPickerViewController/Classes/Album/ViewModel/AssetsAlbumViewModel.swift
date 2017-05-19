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
import OptionalTypes

// MARK: - AssetsAlbumViewModelProtocol
public protocol AssetsAlbumViewModelProtocol {
    
    var albumsArray: [[PHAssetCollection]] { get }
    var fetchesArray: [[PHFetchResult<PHAsset>]] { get }
    var numberOfSections: Int { get }
    
    func fetchAlbums(cacheSize: CGSize)
    func numberOfItems(inSection: Int) -> Int
    func numberOfAssets(at indexPath: IndexPath) -> Int
    func title(at indexPath: IndexPath) -> String?
    func image(at indexPath: IndexPath, size: CGSize, completion: @escaping ((UIImage?) -> Void))
    func album(at indexPath: IndexPath) -> PHAssetCollection
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
    
    fileprivate var albumsMap = [String: PHAssetCollection]()
    fileprivate var fetchesMap = [String: PHFetchResult<PHAsset>]()
    fileprivate let imageManager = PHCachingImageManager()
    
    public override init() {
        super.init()
        registerObserver()
    }
    
    deinit {
        logd("Released \(type(of: self))")
        imageManager.stopCachingImagesForAllAssets()
        unregisterObserver()
    }
    
    // MARK: AssetsAlbumViewModelProtocol
    fileprivate(set) open var albumsArray = [[PHAssetCollection]]()
    fileprivate(set) open var fetchesArray = [[PHFetchResult<PHAsset>]]()
    
    open var numberOfSections: Int {
        return albumsArray.count
    }
    
    open func fetchAlbums(cacheSize: CGSize) {
        logi("Start fetching...")
        
        let smartAlbumFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        var smartAlbums = [PHAssetCollection]()
        var smartAlbumFetches = [PHFetchResult<PHAsset>]()
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        // smart album
        smartAlbumFetchResult.enumerateObjects({ (album, _, _) in
            // fetch assets
            let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
            
            // cache
            if let asset = fetchResult.firstObject {
                self.imageManager.startCachingImages(for: [asset], targetSize: cacheSize, contentMode: .aspectFill, options: nil)
            }
            
            // cache fetch result
            self.fetchesMap[album.localIdentifier] = fetchResult
            
            // cache album
            self.albumsMap[album.localIdentifier] = album
            smartAlbums.append(album)
        })
        smartAlbums.sort(by: { Int(self.fetchesMap[$0.localIdentifier]?.count) > Int(self.fetchesMap[$1.localIdentifier]?.count) })
        for smartAlbum in smartAlbums {
            if let fetchResult = fetchesMap[smartAlbum.localIdentifier] {
                smartAlbumFetches.append(fetchResult)
            } else {
                logw("Failed to get fetch result from fetchesMap.")
            }
        }
        
        // append smart album fetch results
        fetchesArray.append(smartAlbumFetches)
        albumsArray.append(smartAlbums)
        
        // notify
        delegate?.assetsAlbumViewModel(viewModel: self, createdSection: 0)
    
        // my album
        let albumFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        var albums = [PHAssetCollection]()
        var albumFetches = [PHFetchResult<PHAsset>]()
        
        albumFetchResult.enumerateObjects({ (album, _, _) in
            // fetch assets
            let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
            
            // cache
            if let asset = fetchResult.firstObject {
                self.imageManager.startCachingImages(for: [asset], targetSize: cacheSize, contentMode: .aspectFill, options: nil)
            }
            
            // cache fetch result
            self.fetchesMap[album.localIdentifier] = fetchResult
            
            // cache album
            self.albumsMap[album.localIdentifier] = album
            albums.append(album)
        })
        albums.sort(by: { Int(self.fetchesMap[$0.localIdentifier]?.count) > Int(self.fetchesMap[$1.localIdentifier]?.count) })
        for album in albums {
            if let fetchResult = fetchesMap[album.localIdentifier] {
                albumFetches.append(fetchResult)
            } else {
                logw("Failed to get fetch result from fetchesMap.")
            }
        }
        
        // append my album fetch result
        fetchesArray.append(albumFetches)
        albumsArray.append(albums)
        
        // notify
        delegate?.assetsAlbumViewModel(viewModel: self, createdSection: 1)
        
        logi("Finish fetching...")
    }
    
    open func numberOfItems(inSection: Int) -> Int {
        return albumsArray[inSection].count
    }
    
    open func numberOfAssets(at indexPath: IndexPath) -> Int {
        return fetchesArray[indexPath.section][indexPath.row].count
    }
    
    open func title(at indexPath: IndexPath) -> String? {
        let album = albumsArray[indexPath.section][indexPath.row]
        return album.localizedTitle
    }
    
    open func image(at indexPath: IndexPath, size: CGSize, completion: @escaping ((UIImage?) -> Void)) {
        let fetchResult = fetchesArray[indexPath.section][indexPath.row]
        if let asset = fetchResult.firstObject {
            imageManager.requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: nil,
                resultHandler: { (image, info) in
                    completion(image)
            })
        } else {
            completion(nil)
        }
    }
    
    open func album(at indexPath: IndexPath) -> PHAssetCollection {
        return albumsArray[indexPath.section][indexPath.row]
    }
    
    // MARK: Observers
    open func registerObserver() { PHPhotoLibrary.shared().register(self) }
    open func unregisterObserver() { PHPhotoLibrary.shared().unregisterChangeObserver(self) }
}

// MARK: - Album Model Control
extension AssetsAlbumViewModel {
    
    func clearAlbums() {
        albumsMap.removeAll()
        albumsArray.removeAll()
    }
    
    func append(album: PHAssetCollection, inSection: Int) {
        if let album = albumsMap[album.localIdentifier] {
            log("Album already exists: \(album.localizedTitle ?? album.localIdentifier)")
        } else {
            albumsMap[album.localIdentifier] = album
            albumsArray[inSection].append(album)
        }
    }
    
    func insert(album: PHAssetCollection, at indexPath: IndexPath) {
        albumsMap[album.localIdentifier] = album
        albumsArray[indexPath.section].insert(album, at: indexPath.row)
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension AssetsAlbumViewModel: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        //        changeInstance.changeDetails(for: <#T##PHFetchResult<T>#>)
    }
}
