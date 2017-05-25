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
    func assetsManager(manager: AssetsManager, reloadedAlbum album: PHAssetCollection, at indexPath: IndexPath)
    func assetsManager(manager: AssetsManager, insertedAlbum album: PHAssetCollection, at indexPath: IndexPath)
    func assetsManager(manager: AssetsManager, removedAlbum album: PHAssetCollection, at indexPath: IndexPath)
    func assetsManager(manager: AssetsManager, updatedAlbum album: PHAssetCollection, at indexPath: IndexPath)
    func assetsManager(manager: AssetsManager, insertedAssets assets: [PHAsset], at indexPaths: [IndexPath])
    func assetsManager(manager: AssetsManager, removedAssets assets: [PHAsset], at indexPaths: [IndexPath])
    func assetsManager(manager: AssetsManager, updatedAssets assets: [PHAsset], at indexPaths: [IndexPath])
}

// MARK: - AssetsManager
open class AssetsManager: NSObject {
    
    open static let shared = AssetsManager()
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var subscribers = [AssetsManagerDelegate]()
    
    fileprivate var albumFetchArray = [PHFetchResult<PHAssetCollection>]()
    fileprivate var albumMap = [String: PHAssetCollection]()
    fileprivate var fetchMap = [String: PHFetchResult<PHAsset>]()
    fileprivate var photoMap = [String: PHAsset]()
    
    fileprivate var isFetchedAlbums: Bool = false
    
    private override init() {
        super.init()
    }
    
    deinit { logd("Released \(type(of: self))") }
    
    fileprivate var albumsArray = [[PHAssetCollection]]()
    fileprivate(set) open var photoArray = [PHAsset]()
    
    fileprivate var defaultAlbum: PHAssetCollection!
    fileprivate(set) open var selectedAlbum: PHAssetCollection?
}

// MARK: - Subscribe
extension AssetsManager {
    
    open func subscribe(subscriber: AssetsManagerDelegate) {
        subscribers.append(subscriber)
    }
    
    open func unsubscribe(subscriber: AssetsManagerDelegate) {
        if let index = subscribers.index(where: { subscriber === $0 }) {
            subscribers.remove(at: index)
        }
    }

}

// MARK: - Observer
extension AssetsManager {
    open func registerObserver() {
        PHPhotoLibrary.shared().register(self)
    }
    
    open func unregisterObserver() {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

// MARK: - Cache
extension AssetsManager {
    open func cacheAlbums(cacheSize: CGSize) {
        if isFetchedAlbums {
            for albums in albumsArray {
                for album in albums {
                    if let fetchResult = fetchMap[album.localIdentifier] {
                        if let asset = fetchResult.firstObject {
                            imageManager.startCachingImages(for: [asset], targetSize: cacheSize, contentMode: .aspectFill, options: nil)
                        }
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
}

// MARK: - Sources
extension AssetsManager {

    open func clear() {
        
        unregisterObserver()
        subscribers.removeAll()
        
        imageManager.stopCachingImagesForAllAssets()
        
        albumFetchArray.removeAll()
        fetchMap.removeAll()
        albumMap.removeAll()
        albumsArray.removeAll()
        photoMap.removeAll()
        photoArray.removeAll()
        
        selectedAlbum = nil
        
        isFetchedAlbums = false
    }
    
    open var numberOfSections: Int {
        return albumsArray.count
    }
    
    open func numberOfAlbums(inSection: Int) -> Int {
        return albumsArray[inSection].count
    }
    
    open func numberOfAssets(at indexPath: IndexPath) -> Int {
        return Int(fetchMap[albumsArray[indexPath.section][indexPath.row].localIdentifier]?.count)
    }
    
    open func title(at indexPath: IndexPath) -> String? {
        let album = albumsArray[indexPath.section][indexPath.row]
        return album.localizedTitle
    }
    
    open func imageOfAlbum(at indexPath: IndexPath, size: CGSize, completion: @escaping ((UIImage?) -> Void)) {
        if let fetchResult = fetchMap[albumsArray[indexPath.section][indexPath.row].localIdentifier] {
            if let asset = fetchResult.lastObject {
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
    
    open func count(ofType type: PHAssetMediaType) -> Int {
        if let album = self.selectedAlbum, let fetchResult = fetchMap[album.localIdentifier] {
            return fetchResult.countOfAssets(with: type)
        } else {
            var count = 0
            for albums in albumsArray {
                for album in albums {
                    if let fetchResult = fetchMap[album.localIdentifier], album.assetCollectionSubtype != .smartAlbumRecentlyAdded {
                        count += fetchResult.countOfAssets(with: type)
                    }
                }
            }
            return count
        }
    }
    
    open func isExist(asset: PHAsset) -> Bool {
        return photoMap[asset.localIdentifier] != nil
    }
    
    @discardableResult
    open func select(album newAlbum: PHAssetCollection) -> Bool {
        if let oldAlbumIdentifier = self.selectedAlbum?.localIdentifier, oldAlbumIdentifier == newAlbum.localIdentifier {
            log("Selected same album.")
            return false
        }
        self.selectedAlbum = newAlbum
        var photos = [PHAsset]()
        if let fetchResult = fetchMap[newAlbum.localIdentifier] {
            for i in 0..<fetchResult.count {
                let asset = fetchResult.object(at: i)
                photos.append(asset)
            }
            photoArray = photos
            return true
        } else {
            return false
        }
    }
}

// MARK: - Fetch
extension AssetsManager {
    
    open func fetchAlbums(completion: (([[PHAssetCollection]]) -> Void)? = nil) {
        if !isFetchedAlbums {
            fetchAlbum(albumType: .smartAlbum)
            fetchAlbum(albumType: .album)
            isFetchedAlbums = true
        }
        // notify
        completion?(albumsArray)
    }
    
    open func fetchPhotos(completion: (([PHAsset]) -> Void)? = nil) {
        
        fetchAlbums()
        
        // set default album
        select(album: defaultAlbum)
        
        completion?(photoArray)
    }
    
    fileprivate func fetchAlbum(albumType: PHAssetCollectionType) {

        let albumFetchResult = PHAssetCollection.fetchAssetCollections(with: albumType, subtype: .any, options: nil)
        var albums = [PHAssetCollection]()
        var albumFetches = [PHFetchResult<PHAsset>]()
        var fallbackDefaultAlbum: PHAssetCollection?
        var defaultAlbum: PHAssetCollection?
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
            
            // set default album
            if album.assetCollectionSubtype == AlbumAttributes.defaultAlbumType {
                defaultAlbum = album
            }
            // save alternative album
            if album.assetCollectionSubtype == .smartAlbumUserLibrary {
                fallbackDefaultAlbum = album
            }
            albums.append(album)
        })
        albums.sort(by: { Int(self.fetchMap[$0.localIdentifier]?.count) > Int(self.fetchMap[$1.localIdentifier]?.count) })
        
        // set default album
        if let defaultAlbum = self.defaultAlbum {
            logi("Default album is \(defaultAlbum.localizedTitle ?? "")")
        } else {
            if let defaultAlbum = defaultAlbum {
                logi("Set default album: \(defaultAlbum.localizedTitle ?? "")")
            } else {
                if let fallbackDefaultAlbum = fallbackDefaultAlbum {
                    defaultAlbum = fallbackDefaultAlbum
                    logw("Set default album with fallback default album: \(fallbackDefaultAlbum.localizedTitle ?? "")")
                } else {
                    if let firstAlbum = albums.first {
                        defaultAlbum = firstAlbum
                        loge("Set default album with first item: \(firstAlbum.localizedTitle ?? "")")
                    } else {
                        logc("Is this case could happen? Raise an issue if you see this message.")
                    }
                }
            }
            self.defaultAlbum = defaultAlbum
        }
        
        for album in albums {
            if let fetchResult = fetchMap[album.localIdentifier] {
                albumFetches.append(fetchResult)
            } else {
                logw("Failed to get fetch result from fetchesMap.")
            }
        }
        
        // append album fetch result
        albumFetchArray.append(albumFetchResult)
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
    
    fileprivate func indexPath(forAlbum target: PHAssetCollection) -> IndexPath {
        var typeIndex: Int = 0
        var subtypeIndex: Int = 0
        for (i, albums) in albumsArray.enumerated() {
            typeIndex = i
            for (j, album) in albums.enumerated() {
                subtypeIndex = j
                if target.localIdentifier == album.localIdentifier {
                    logi("Found indexPath for album.")
                    break
                }
            }
        }
        return IndexPath(row: subtypeIndex, section: typeIndex)
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension AssetsManager: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        for albums in albumsArray {
            for album in albums {
                guard let fetchResult = fetchMap[album.localIdentifier], let albumChangeDetail = changeInstance.changeDetails(for: fetchResult) else {
                    continue
                }
                guard albumChangeDetail.hasIncrementalChanges else {
                    for subscriber in subscribers {
                        subscriber.assetsManager(manager: self, reloadedAlbum: album, at: indexPath(forAlbum: album))
                    }
                    continue
                }
                guard let selectedAlbum = self.selectedAlbum, album.localIdentifier == selectedAlbum.localIdentifier else {
                    continue
                }
                // sync removed assets
                if let removedIndexesSet = albumChangeDetail.removedIndexes {
                    let fetchResultAfterRemove = albumChangeDetail.fetchResultAfterChanges
                    let removedIndexes = removedIndexesSet.asArray().sorted(by: { $0.row > $1.row })
                    var removedAssets = [PHAsset]()
                    for removedIndex in removedIndexes {
                        removedAssets.append(photoArray.remove(at: removedIndex.row))
                    }
                    
                    fetchMap[selectedAlbum.localIdentifier] = fetchResultAfterRemove
                    // stop caching for removed assets
                    stopCache(assets: removedAssets, size: PhotoAttributes.thumbnailCacheSize)
                    DispatchQueue.main.async {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, removedAssets: removedAssets, at: removedIndexes)
                        }
                    }
                }
                // sync inserted assets
                if let insertedIndexesSet = albumChangeDetail.insertedIndexes {
                    let fetchResultAfterInsert = albumChangeDetail.fetchResultAfterChanges
                    let insertedIndexes = insertedIndexesSet.asArray().sorted(by: { $0.row < $1.row })
                    var insertedAssets = [PHAsset]()
                    for insertedIndex in insertedIndexes {
                        let insertedAsset = fetchResultAfterInsert.object(at: insertedIndex.row)
                        insertedAssets.append(insertedAsset)
                        photoArray.insert(insertedAsset, at: insertedIndex.row)
                    }
                    fetchMap[selectedAlbum.localIdentifier] = fetchResultAfterInsert
                    // start caching for inserted assets
                    cache(assets: insertedAssets, size: PhotoAttributes.thumbnailCacheSize)
                    DispatchQueue.main.async {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, insertedAssets: insertedAssets, at: insertedIndexes)
                        }
                    }
                }
                // sync updated assets
                if let updatedIndexesSet = albumChangeDetail.changedIndexes {
                    let fetchResultAfterUpdate = albumChangeDetail.fetchResultAfterChanges
                    let updatedIndexes = updatedIndexesSet.asArray()
                    var updatedAssets = [PHAsset]()
                    for updatedIndex in updatedIndexes {
                        let updatedAsset = fetchResultAfterUpdate.object(at: updatedIndex.row)
                        updatedAssets.append(updatedAsset)
                    }
                    fetchMap[selectedAlbum.localIdentifier] = fetchResultAfterUpdate
                    // stop caching for updated assets
                    stopCache(assets: updatedAssets, size: PhotoAttributes.thumbnailCacheSize)
                    cache(assets: updatedAssets, size: PhotoAttributes.thumbnailCacheSize)
                    DispatchQueue.main.async {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, updatedAssets: updatedAssets, at: updatedIndexes)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - IndexSet Utility
extension IndexSet {
    fileprivate func asArray() -> [IndexPath] {
        var indexPaths = [IndexPath]()
        for entry in enumerated() {
            indexPaths.append(IndexPath(row: entry.element, section: 0))
        }
        return indexPaths
    }
}
