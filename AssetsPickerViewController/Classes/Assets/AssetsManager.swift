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
    func assetsManagerReloaded(manager: AssetsManager)
    func assetsManager(manager: AssetsManager, reloadedAlbum album: PHAssetCollection, at indexPath: IndexPath)
    func assetsManager(manager: AssetsManager, insertedAssets assets: [PHAsset], at indexPaths: [IndexPath])
    func assetsManager(manager: AssetsManager, removedAssets assets: [PHAsset], at indexPaths: [IndexPath])
    func assetsManager(manager: AssetsManager, updatedAssets assets: [PHAsset], at indexPaths: [IndexPath])
}

// MARK: - AssetsManager
open class AssetsManager: NSObject {
    
    open static let shared = AssetsManager()
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var subscribers = [AssetsManagerDelegate]()
    
    fileprivate var albumsFetchArray = [PHFetchResult<PHAssetCollection>]()
    fileprivate var albumMap = [String: PHAssetCollection]()
    fileprivate var albumThumbnails = [[PHAsset]]()
    fileprivate var fetchMap = [String: PHFetchResult<PHAsset>]()
    
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
            if albumThumbnails.count > 0 {
                imageManager.stopCachingImages(for: albumThumbnails.reduce([], +), targetSize: cacheSize, contentMode: .aspectFill, options: nil)
            }
            var newThumbnails = [[PHAsset]]()
            for albums in albumsArray {
                var thumbnails = [PHAsset]()
                for album in albums {
                    if let fetchResult = fetchMap[album.localIdentifier] {
                        if let asset = fetchResult.lastObject {
                            thumbnails.append(asset)
                        }
                    }
                }
                newThumbnails.append(thumbnails)
            }
            imageManager.startCachingImages(for: newThumbnails.reduce([], +), targetSize: cacheSize, contentMode: .aspectFill, options: nil)
            self.albumThumbnails = newThumbnails
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
        
        albumsFetchArray.removeAll()
        fetchMap.removeAll()
        albumMap.removeAll()
        albumsArray.removeAll()
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
    
    open func imageOfAlbum(at indexPath: IndexPath, size: CGSize, isNeedDegraded: Bool = true, completion: @escaping ((UIImage?) -> Void)) {
        if let fetchResult = fetchMap[albumsArray[indexPath.section][indexPath.row].localIdentifier] {
            if let asset = fetchResult.lastObject {
                imageManager.requestImage(
                    for: asset,
                    targetSize: size,
                    contentMode: .aspectFill,
                    options: nil,
                    resultHandler: { (image, info) in
                        if !isNeedDegraded && Bool(info?[PHImageResultIsDegradedKey]) {
                            return
                        }
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
        return PHAsset.fetchAssets(withLocalIdentifiers: [asset.localIdentifier], options: nil).count > 0
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
    
    open func fetchAlbums(isRefetch: Bool = false, completion: (([[PHAssetCollection]]) -> Void)? = nil) {
        
        if isRefetch {
            isFetchedAlbums = false
            fetchMap.removeAll()
            albumsArray.removeAll()
        }
        
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

        albumFetchResult.enumerateObjects({ (album, _, _) in
            // fetch assets
            let fetchResult = PHAsset.fetchAssets(in: album, options: AssetsPhotoAttributes.fetchOptions)
            
            // cache fetch result
            self.fetchMap[album.localIdentifier] = fetchResult
            
            // cache album
            self.albumMap[album.localIdentifier] = album
            
            // set default album
            if album.assetCollectionSubtype == AssetsAlbumAttributes.defaultAlbumType {
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
            logi("Default album is \"\(defaultAlbum.localizedTitle ?? "")\"")
        } else {
            if let defaultAlbum = defaultAlbum {
                logi("Set default album \"\(defaultAlbum.localizedTitle ?? "")\"")
            } else {
                if let fallbackDefaultAlbum = fallbackDefaultAlbum {
                    defaultAlbum = fallbackDefaultAlbum
                    logw("Set default album with fallback default album \"\(fallbackDefaultAlbum.localizedTitle ?? "")\"")
                } else {
                    if let firstAlbum = albums.first {
                        defaultAlbum = firstAlbum
                        loge("Set default album with first item \"\(firstAlbum.localizedTitle ?? "")\"")
                    } else {
                        logc("Is this case could happen? Please raise an issue if you've met this message.")
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
        albumsFetchArray.append(albumFetchResult)
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
    
    open func indexPath(forAlbum target: PHAssetCollection) -> IndexPath? {
        var typeIndex: Int = -1
        var subtypeIndex: Int = -1
        for (i, albums) in albumsArray.enumerated() {
            if let collectionType = albums.first?.assetCollectionType, collectionType == target.assetCollectionType {
                typeIndex = i
            } else {
                continue
            }
            for (j, album) in albums.enumerated() {
                subtypeIndex = j
                if target.localIdentifier == album.localIdentifier {
                    logi("Found indexPath for album.")
                    break
                }
            }
        }
        if typeIndex > -1 && subtypeIndex > -1 {
            return IndexPath(row: subtypeIndex, section: typeIndex)
        } else {
            return nil
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension AssetsManager: PHPhotoLibraryChangeObserver {
    
    private func isThumbnailChanged(changeDetails: PHFetchResultChangeDetails<PHAsset>) -> Bool {
        
        var isChanged: Bool = false
        
        if let lastBeforeChange = changeDetails.fetchResultBeforeChanges.lastObject {
            if let lastAfterChange = changeDetails.fetchResultAfterChanges.lastObject {
                if lastBeforeChange.localIdentifier == lastAfterChange.localIdentifier {
                    if let _ = changeDetails.changedObjects.index(of: lastAfterChange) {
                        isChanged = true
                    }
                } else {
                    isChanged = true
                }
            } else {
                isChanged = true
            }
        } else {
            if let _ = changeDetails.fetchResultAfterChanges.lastObject {
                isChanged = true
            }
        }
        return isChanged
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        var isNeedReloadAlbums: Bool = false
        
        // notify changes of albums
        for albumsFetchResult in albumsFetchArray {
            guard let albumsChangeDetail = changeInstance.changeDetails(for: albumsFetchResult) else {
                continue
            }
            guard albumsChangeDetail.hasIncrementalChanges else {
                isNeedReloadAlbums = true
                continue
            }
            // sync removed albums
            if let _ = albumsChangeDetail.removedIndexes { isNeedReloadAlbums = true }
            if let _ = albumsChangeDetail.insertedIndexes { isNeedReloadAlbums = true }
            if let _ = albumsChangeDetail.changedIndexes { isNeedReloadAlbums = true }
        }
        
        // reload albums if needed
        if isNeedReloadAlbums {
            fetchAlbums(isRefetch: true, completion: { (_) in
                DispatchQueue.main.async {
                    for subscriber in self.subscribers {
                        subscriber.assetsManagerReloaded(manager: self)
                    }
                }
            })
        }
        
        // notify changes of assets
        for albums in albumsArray {
            for album in albums {
                guard let fetchResult = fetchMap[album.localIdentifier], let assetsChangeDetails = changeInstance.changeDetails(for: fetchResult) else {
                    continue
                }
                guard assetsChangeDetails.hasIncrementalChanges else {
                    for subscriber in subscribers {
                        if let indexPathForAlbum = indexPath(forAlbum: album) {
                            subscriber.assetsManager(manager: self, reloadedAlbum: album, at: indexPathForAlbum)
                        } else {
                            logw("Failed to find indexPath for album: \(album.localizedTitle ?? "")")
                        }
                    }
                    continue
                }
                
                if let albumIndexPath = self.indexPath(forAlbum: album), isThumbnailChanged(changeDetails: assetsChangeDetails) {
                    DispatchQueue.main.async {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, reloadedAlbum: album, at: albumIndexPath)
                        }
                    }
                }
                
                guard let selectedAlbum = self.selectedAlbum, selectedAlbum.localIdentifier == album.localIdentifier else {
                    continue
                }
                
                // sync removed assets
                if let removedIndexesSet = assetsChangeDetails.removedIndexes {
                    let fetchResultAfterRemove = assetsChangeDetails.fetchResultAfterChanges
                    let removedIndexes = removedIndexesSet.asArray().sorted(by: { $0.row > $1.row })
                    var removedAssets = [PHAsset]()
                    for removedIndex in removedIndexes {
                        removedAssets.append(photoArray.remove(at: removedIndex.row))
                    }
                    fetchMap[album.localIdentifier] = fetchResultAfterRemove
                    // stop caching for removed assets
                    stopCache(assets: removedAssets, size: AssetsPhotoAttributes.thumbnailCacheSize)
                    DispatchQueue.main.async {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, removedAssets: removedAssets, at: removedIndexes)
                        }
                    }
                }
                // sync inserted assets
                if let insertedIndexesSet = assetsChangeDetails.insertedIndexes {
                    let fetchResultAfterInsert = assetsChangeDetails.fetchResultAfterChanges
                    let insertedIndexes = insertedIndexesSet.asArray().sorted(by: { $0.row < $1.row })
                    var insertedAssets = [PHAsset]()
                    for insertedIndex in insertedIndexes {
                        let insertedAsset = fetchResultAfterInsert.object(at: insertedIndex.row)
                        insertedAssets.append(insertedAsset)
                        photoArray.insert(insertedAsset, at: insertedIndex.row)
                    }
                    fetchMap[album.localIdentifier] = fetchResultAfterInsert
                    // start caching for inserted assets
                    cache(assets: insertedAssets, size: AssetsPhotoAttributes.thumbnailCacheSize)
                    DispatchQueue.main.async {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, insertedAssets: insertedAssets, at: insertedIndexes)
                        }
                    }
                }
                // sync updated assets
                if let updatedIndexesSet = assetsChangeDetails.changedIndexes {
                    let fetchResultAfterUpdate = assetsChangeDetails.fetchResultAfterChanges
                    let updatedIndexes = updatedIndexesSet.asArray()
                    var updatedAssets = [PHAsset]()
                    for updatedIndex in updatedIndexes {
                        let updatedAsset = fetchResultAfterUpdate.object(at: updatedIndex.row)
                        updatedAssets.append(updatedAsset)
                    }
                    fetchMap[album.localIdentifier] = fetchResultAfterUpdate
                    // stop caching for updated assets
                    stopCache(assets: updatedAssets, size: AssetsPhotoAttributes.thumbnailCacheSize)
                    cache(assets: updatedAssets, size: AssetsPhotoAttributes.thumbnailCacheSize)
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
