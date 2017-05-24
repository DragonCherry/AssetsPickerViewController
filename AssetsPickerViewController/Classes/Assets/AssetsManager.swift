//
//  AssetsManager.swift
//  Pods
//
//  Created by DragonCherry on 5/19/17.
//
//

import UIKit
import Photos
import TinyLog
import OptionalTypes

// MARK: - AssetsManagerDelegate
public protocol AssetsManagerDelegate: class {
    func assetsManager(manager: AssetsManager, removedSection section: Int)
    func assetsManager(manager: AssetsManager, removedAlbums: [PHAssetCollection], at indexPaths: [IndexPath])
    func assetsManager(manager: AssetsManager, addedAlbums: [PHAssetCollection], at indexPaths: [IndexPath])
}

// MARK: - AssetsManager
open class AssetsManager: NSObject {
    
    open static let shared = AssetsManager()
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var subscribers = [AssetsManagerDelegate]()
    
    fileprivate var albumMap = [String: PHAssetCollection]()
    fileprivate var fetchMap = [String: PHFetchResult<PHAsset>]()
    fileprivate var photoMap = [String: PHAsset]()
    
    fileprivate var isFetchedAlbums: Bool = false
    
    private override init() {
        super.init()
        registerObserver()
    }
    
    deinit { logd("Released \(type(of: self))") }
    
    fileprivate var fetchesArray = [[PHFetchResult<PHAsset>]]()
    fileprivate var albumsArray = [[PHAssetCollection]]()
    fileprivate(set) open var photoArray = [PHAsset]()
    
    open var selectedAlbum: PHAssetCollection? {
        didSet {
            
            if let oldAlbum = oldValue, let newAlbum = selectedAlbum, oldAlbum.localIdentifier == newAlbum.localIdentifier {
                log("Selected same album.")
                return
            }
            
            var photos = [PHAsset]()
            
            if let album = selectedAlbum, let fetchResult = fetchMap[album.localIdentifier] {
                for i in 0..<fetchResult.count {
                    let asset = fetchResult.object(at: i)
                    photos.append(asset)
                }
            } else {
                for fetchResults in fetchesArray {
                    for fetchResult in fetchResults {
                        for i in 0..<fetchResult.count {
                            let asset = fetchResult.object(at: i)
                            if let _ = photoMap[asset.localIdentifier] {
                                // duplicated
                            } else {
                                photoMap[asset.localIdentifier] = asset
                                photos.append(asset)
                            }
                        }
                    }
                }
            }
            photoArray = AssetsUtility.sortedAssets(photos, recentFirst: false)
        }
    }
}

// MARK: - APIs
extension AssetsManager {
    
    // MARK: APIs
    open func subscribe(subscriber: AssetsManagerDelegate) {
        subscribers.append(subscriber)
    }
    
    open func unsubscribe(subscriber: AssetsManagerDelegate) {
        if let index = subscribers.index(where: { subscriber === $0 }) {
            subscribers.remove(at: index)
        }
    }
    
    open func clear() {
        
        unregisterObserver()
        imageManager.stopCachingImagesForAllAssets()
        subscribers.removeAll()
        
        fetchMap.removeAll()
        fetchesArray.removeAll()
        albumMap.removeAll()
        albumsArray.removeAll()
        photoMap.removeAll()
        photoArray.removeAll()
        
        isFetchedAlbums = false
    }
    
    open var numberOfSections: Int {
        return albumsArray.count
    }
    
    open func fetchAlbums(completion: (([[PHAssetCollection]]) -> Void)? = nil) {
        logi("Before")
        if !isFetchedAlbums {
            fetchAlbum(albumType: .smartAlbum)
            fetchAlbum(albumType: .album)
            isFetchedAlbums = true
        }
        // notify
        completion?(albumsArray)
        logi("After")
    }
    
    open func cacheAlbums(cacheSize: CGSize) {
        if isFetchedAlbums {
            for fetchResults in fetchesArray {
                for fetchResult in fetchResults {
                    if let asset = fetchResult.firstObject {
                        imageManager.startCachingImages(for: [asset], targetSize: cacheSize, contentMode: .aspectFill, options: nil)
                    }
                }
            }
        }
    }
    
    open func cache(asset: PHAsset, size: CGSize) {
        cache(assets: [asset], size: size)
    }
    
    open func cache(assets: [PHAsset], size: CGSize) {
        imageManager.startCachingImages(for: assets, targetSize: size, contentMode: .aspectFill, options: nil)
    }
    
    open func stopCache(asset: PHAsset, size: CGSize) {
        stopCache(assets: [asset], size: size)
    }
    
    open func stopCache(assets: [PHAsset], size: CGSize) {
        imageManager.stopCachingImages(for: assets, targetSize: size, contentMode: .aspectFill, options: nil)
    }
    
    open func fetchPhotos(album: PHAssetCollection? = nil, completion: (([PHAsset]) -> Void)? = nil) {
        logi("Before")
        
        fetchAlbums()
        selectedAlbum = album
        
        completion?(photoArray)
        logi("After")
    }
    
    open func numberOfAlbums(inSection: Int) -> Int {
        return albumsArray[inSection].count
    }
    
    open func numberOfAssets(at indexPath: IndexPath) -> Int {
        return fetchesArray[indexPath.section][indexPath.row].count
    }
    
    open func title(at indexPath: IndexPath) -> String? {
        let album = albumsArray[indexPath.section][indexPath.row]
        return album.localizedTitle
    }
    
    open func imageOfAlbum(at indexPath: IndexPath, size: CGSize, completion: @escaping ((UIImage?) -> Void)) {
        let fetchResult = fetchesArray[indexPath.section][indexPath.row]
        if let asset = fetchResult.firstObject {
            imageManager.requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: nil,
                resultHandler: { (image, info) in
                    DispatchQueue.main.async {
                        completion(image)
                    }
            })
        } else {
            completion(nil)
        }
    }
    
    open func image(at index: Int, size: CGSize, completion: @escaping ((UIImage?) -> Void)) {
        imageManager.requestImage(
            for: photoArray[index],
            targetSize: size,
            contentMode: .aspectFill,
            options: nil,
            resultHandler: { (image, info) in
                DispatchQueue.main.async {
                    completion(image)
                }
        })
    }
    
    open func album(at indexPath: IndexPath) -> PHAssetCollection {
        return albumsArray[indexPath.section][indexPath.row]
    }
    
    // MARK: Observers
    open func registerObserver() { PHPhotoLibrary.shared().register(self) }
    open func unregisterObserver() { PHPhotoLibrary.shared().unregisterChangeObserver(self) }
}

// MARK: - Album Model Control
extension AssetsManager {
    
    fileprivate func fetchAlbum(albumType: PHAssetCollectionType) {
        // my album
        let albumFetchResult = PHAssetCollection.fetchAssetCollections(with: albumType, subtype: .any, options: nil)
        var albums = [PHAssetCollection]()
        var albumFetches = [PHFetchResult<PHAsset>]()
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true),
            NSSortDescriptor(key: "modificationDate", ascending: true)
        ]
        
        albumFetchResult.enumerateObjects({ (album, _, _) in
            // fetch assets
            let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
            
            // cache fetch result
            self.fetchMap[album.localIdentifier] = fetchResult
            
            // cache album
            self.albumMap[album.localIdentifier] = album
            albums.append(album)
        })
        albums.sort(by: { Int(self.fetchMap[$0.localIdentifier]?.count) > Int(self.fetchMap[$1.localIdentifier]?.count) })
        for album in albums {
            if let fetchResult = fetchMap[album.localIdentifier] {
                albumFetches.append(fetchResult)
            } else {
                logw("Failed to get fetch result from fetchesMap.")
            }
        }
        
        // append album fetch result
        fetchesArray.append(albumFetches)
        albumsArray.append(albums)
    }
    
    fileprivate func append(album: PHAssetCollection, inSection: Int) {
        if let album = albumMap[album.localIdentifier] {
            log("Album already exists: \(album.localizedTitle ?? album.localIdentifier)")
        } else {
            albumMap[album.localIdentifier] = album
            albumsArray[inSection].append(album)
        }
    }
    
    fileprivate func insert(album: PHAssetCollection, at indexPath: IndexPath) {
        albumMap[album.localIdentifier] = album
        albumsArray[indexPath.section].insert(album, at: indexPath.row)
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension AssetsManager: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        //        changeInstance.changeDetails(for: <#T##PHFetchResult<T>#>)
    }
}
