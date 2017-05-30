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
    
    func assetsManager(manager: AssetsManager, authorizationStatusChanged oldStatus: PHAuthorizationStatus, newStatus: PHAuthorizationStatus)
    func assetsManager(manager: AssetsManager, reloadedAlbumsInSection section: Int)
    
    func assetsManager(manager: AssetsManager, insertedAlbums albums: [PHAssetCollection], at indexPaths: [IndexPath])
    func assetsManager(manager: AssetsManager, removedAlbums albums: [PHAssetCollection], at indexPaths: [IndexPath])
    func assetsManager(manager: AssetsManager, updatedAlbums albums: [PHAssetCollection], at indexPaths: [IndexPath])
    
    func assetsManager(manager: AssetsManager, reloadedAlbum album: PHAssetCollection, at indexPath: IndexPath)
    func assetsManager(manager: AssetsManager, insertedAssets assets: [PHAsset], at indexPaths: [IndexPath])
    func assetsManager(manager: AssetsManager, removedAssets assets: [PHAsset], at indexPaths: [IndexPath])
    func assetsManager(manager: AssetsManager, updatedAssets assets: [PHAsset], at indexPaths: [IndexPath])
}

// MARK: - AssetsManager
open class AssetsManager: NSObject {
    
    open static let shared = AssetsManager()
    
    open var pickerConfig = AssetsPickerConfig()
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var authorizationStatus = PHPhotoLibrary.authorizationStatus()
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
    
    fileprivate var fetchedAlbumsArray = [[PHAssetCollection]]()
    fileprivate var sortedAlbumsArray = [[PHAssetCollection]]()
    fileprivate(set) open var assetArray = [PHAsset]()
    
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

    open func unsubscribeAll() {
        subscribers.removeAll()
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

// MARK: - Permission
extension AssetsManager {
    open func authorize(completion: @escaping ((Bool) -> Void)) {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            completion(true)
        } else {
            PHPhotoLibrary.requestAuthorization({ (status) in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        completion(true)
                    default:
                        completion(false)
                    }
                }
            })
        }
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
            for albums in sortedAlbumsArray {
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
        
        // clear observer & subscriber
        unregisterObserver()
        unsubscribeAll()
        
        // clear cache
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            imageManager.stopCachingImagesForAllAssets()
        }
        
        // clear albums
        albumMap.removeAll()
        fetchedAlbumsArray.removeAll()
        sortedAlbumsArray.removeAll()
        
        // clear assets
        assetArray.removeAll()
        
        // clear fetch results
        albumsFetchArray.removeAll()
        fetchMap.removeAll()
        
        // clear flags
        selectedAlbum = nil
        isFetchedAlbums = false
    }
    
    open var numberOfSections: Int {
        return sortedAlbumsArray.count
    }
    
    open func numberOfAlbums(inSection: Int) -> Int {
        return sortedAlbumsArray[inSection].count
    }
    
    open func numberOfAssets(at indexPath: IndexPath) -> Int {
        return Int(fetchMap[sortedAlbumsArray[indexPath.section][indexPath.row].localIdentifier]?.count)
    }
    
    open func indexPath(forAlbum target: PHAssetCollection) -> IndexPath? {
        var typeIndex: Int = -1
        var subtypeIndex: Int = -1
        for (i, albums) in sortedAlbumsArray.enumerated() {
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
    
    open func title(at indexPath: IndexPath) -> String? {
        let album = sortedAlbumsArray[indexPath.section][indexPath.row]
        return album.localizedTitle
    }
    
    open func imageOfAlbum(at indexPath: IndexPath, size: CGSize, isNeedDegraded: Bool = true, completion: @escaping ((UIImage?) -> Void)) {
        if let fetchResult = fetchMap[sortedAlbumsArray[indexPath.section][indexPath.row].localIdentifier] {
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
            for: assetArray[index],
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
        return sortedAlbumsArray[indexPath.section][indexPath.row]
    }
    
    open func count(ofType type: PHAssetMediaType) -> Int {
        if let album = self.selectedAlbum, let fetchResult = fetchMap[album.localIdentifier] {
            return fetchResult.countOfAssets(with: type)
        } else {
            var count = 0
            for albums in sortedAlbumsArray {
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
            assetArray = photos
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
            selectedAlbum = nil
            isFetchedAlbums = false
            sortedAlbumsArray.removeAll()
            albumsFetchArray.removeAll()
            fetchMap.removeAll()
            albumMap.removeAll()
        }
        
        if !isFetchedAlbums {
            
            let smartAlbumEntry = fetchAlbums(forAlbumType: .smartAlbum)
            fetchedAlbumsArray.append(smartAlbumEntry.fetchedAlbums)
            sortedAlbumsArray.append(smartAlbumEntry.sortedAlbums)
            albumsFetchArray.append(smartAlbumEntry.fetchResult)
            
            let albumEntry = fetchAlbums(forAlbumType: .album)
            fetchedAlbumsArray.append(albumEntry.fetchedAlbums)
            sortedAlbumsArray.append(albumEntry.sortedAlbums)
            albumsFetchArray.append(albumEntry.fetchResult)
            
            if pickerConfig.albumIsShowMomentAlbums {
                let momentEntry = fetchAlbums(forAlbumType: .moment)
                fetchedAlbumsArray.append(momentEntry.fetchedAlbums)
                sortedAlbumsArray.append(momentEntry.sortedAlbums)
                albumsFetchArray.append(momentEntry.fetchResult)
            }
            isFetchedAlbums = true
        }
        // notify
        completion?(sortedAlbumsArray)
    }
    
    open func fetchPhotos(isRefetch: Bool = false, completion: (([PHAsset]) -> Void)? = nil) {
        
        fetchAlbums(isRefetch: isRefetch)
        
        if isRefetch {
            assetArray.removeAll()
        }
        
        // set default album
        select(album: defaultAlbum)
        
        completion?(assetArray)
    }
    
    fileprivate func fetchAlbums(forAlbumType type: PHAssetCollectionType) -> (fetchedAlbums: [PHAssetCollection], sortedAlbums: [PHAssetCollection], fetchResult: PHFetchResult<PHAssetCollection>) {
        
        let albumFetchResult = PHAssetCollection.fetchAssetCollections(with: type, subtype: .any, options: nil)
        var fetchedAlbums = [PHAssetCollection]()
        var fallbackDefaultAlbum: PHAssetCollection?
        var defaultAlbum: PHAssetCollection?

        albumFetchResult.enumerateObjects({ (album, _, _) in
            // fetch assets
            guard let _ = self.fetchAlbum(album: album) else {
                return
            }
            
            // set default album
            if album.assetCollectionSubtype == self.pickerConfig.albumDefaultType {
                defaultAlbum = album
            }
            // save alternative album
            if album.assetCollectionSubtype == .smartAlbumUserLibrary {
                fallbackDefaultAlbum = album
            }
            fetchedAlbums.append(album)
        })
        
        // get sorted albums
        let sortedAlbums = self.sortedAlbums(fromAlbums: fetchedAlbums)
        
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
                    if let firstAlbum = sortedAlbums.first {
                        defaultAlbum = firstAlbum
                        loge("Set default album with first item \"\(firstAlbum.localizedTitle ?? "")\"")
                    } else {
                        logc("Is this case could happen? Please raise an issue if you've met this message.")
                    }
                }
            }
            self.defaultAlbum = defaultAlbum
        }
        
        // append album fetch result
        return (fetchedAlbums, sortedAlbums, albumFetchResult)
    }
    
    @discardableResult
    fileprivate func fetchAlbum(album: PHAssetCollection) -> PHFetchResult<PHAsset>? {
        
        let fetchResult = PHAsset.fetchAssets(in: album, options: self.pickerConfig.assetFetchOptions)
        
        guard self.pickerConfig.albumIsShowHiddenAlbum || album.assetCollectionSubtype != .smartAlbumAllHidden else {
            return nil
        }
        
        guard self.pickerConfig.albumIsShowEmptyAlbum || fetchResult.count > 0 else {
            return nil
        }
        
        // cache fetch result
        self.fetchMap[album.localIdentifier] = fetchResult
        
        // cache album
        self.albumMap[album.localIdentifier] = album
        
        return fetchResult
    }
    
}

// MARK: - Model Manipulation
extension AssetsManager {
    
    fileprivate func remove(albumsWithType type: PHAssetCollectionType) {
        var albumsIndex: Int = -1
        switch type {
        case .smartAlbum:
            albumsIndex = 0
        case .album:
            albumsIndex = 1
        case .moment:
            albumsIndex = 2
        }
        guard sortedAlbumsArray.count > albumsIndex else {
            logc("Cannot remove albums with type - \(type.rawValue)")
            return
        }
        
        let albums = sortedAlbumsArray[albumsIndex]
        
        fetchedAlbumsArray[albumsIndex].removeAll()
        sortedAlbumsArray[albumsIndex].removeAll()
        
        for album in albums {
            remove(album: album)
        }
    }
    
    @discardableResult
    fileprivate func remove(album: PHAssetCollection, indexPath: IndexPath? = nil, isFetchedIndex: Bool = true) -> PHAssetCollection {
        if let indexPath = indexPath {
            if isFetchedIndex {
                let removedAlbum = fetchedAlbumsArray[indexPath.section].remove(at: indexPath.row)
                if let indexInSortedArray = sortedAlbumsArray[indexPath.section].index(of: removedAlbum) {
                    sortedAlbumsArray[indexPath.section].remove(at: indexInSortedArray)
                } else {
                    logc("Error on model manipulation logic.")
                }
            } else {
                let removedAlbum = sortedAlbumsArray[indexPath.section].remove(at: indexPath.row)
                if let indexInFetchedArray = fetchedAlbumsArray[indexPath.section].index(of: removedAlbum) {
                    fetchedAlbumsArray[indexPath.section].remove(at: indexInFetchedArray)
                } else {
                    logc("Error on model manipulation logic.")
                }
            }
        }
        albumMap.removeValue(forKey: album.localIdentifier)
        fetchMap.removeValue(forKey: album.localIdentifier)
        return album
    }
    
    fileprivate func append(album: PHAssetCollection, inSection: Int) {
        if let album = albumMap[album.localIdentifier] {
            log("Album already exists: \(album.localizedTitle ?? album.localIdentifier)")
        } else {
            albumMap[album.localIdentifier] = album
            sortedAlbumsArray[inSection].append(album)
        }
    }
    
    fileprivate func insert(album: PHAssetCollection, at indexPath: IndexPath) {
        albumMap[album.localIdentifier] = album
        sortedAlbumsArray[indexPath.section].insert(album, at: indexPath.row)
    }
    
    fileprivate func sortedAlbums(fromAlbums albums: [PHAssetCollection]) -> [PHAssetCollection] {
        guard let comparator = pickerConfig.albumOrderComparator else {
            return albums.sorted(by: { Int(self.fetchMap[$0.localIdentifier]?.count) > Int(self.fetchMap[$1.localIdentifier]?.count) })
        }
        return albums.sorted(by: { (leftAlbum, rightAlbum) -> Bool in
            if let leftResult = self.fetchMap[leftAlbum.localIdentifier], let rightResult = self.fetchMap[rightAlbum.localIdentifier] {
                return comparator((leftAlbum, leftResult), (rightAlbum, rightResult))
            } else {
                logw("Failed to get fetch result from fetchMap. Please raise an issue if you've met this message.")
                return true
            }
        })
    }
}

// MARK: - Check
extension AssetsManager {
    
    @discardableResult
    func notifyIfAuthorizationStatusChanged() -> Bool {
        let newStatus = PHPhotoLibrary.authorizationStatus()
        if authorizationStatus != newStatus {
            let oldStatus = authorizationStatus
            authorizationStatus = newStatus
            DispatchQueue.main.async {
                for subscriber in self.subscribers {
                    subscriber.assetsManager(manager: self, authorizationStatusChanged: oldStatus, newStatus: newStatus)
                }
            }
        }
        return authorizationStatus == .authorized
    }
    
    func isThumbnailChanged(changeDetails: PHFetchResultChangeDetails<PHAsset>) -> Bool {
        
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
}


// MARK: - PHPhotoLibraryChangeObserver & Sync
extension AssetsManager: PHPhotoLibraryChangeObserver {
    
    func synchronizeAlbums(changeInstance: PHChange) {
        
        // notify changes of albums
        for (i, albumsFetchResult) in albumsFetchArray.enumerated() {
            
            guard let albumsChangeDetail = changeInstance.changeDetails(for: albumsFetchResult) else {
                continue
            }
            
            albumsFetchArray.remove(at: i)
            albumsFetchArray.insert(albumsChangeDetail.fetchResultAfterChanges, at: i)
            
            guard albumsChangeDetail.hasIncrementalChanges else {
                DispatchQueue.main.async {
                    for subscriber in self.subscribers {
                        subscriber.assetsManager(manager: self, reloadedAlbumsInSection: i)
                    }
                }
                continue
            }
            // sync removed albums
            if let removedIndexes = albumsChangeDetail.removedIndexes?.asArray().sorted(by: { $0.row > $1.row }) {
                var removedAlbums = [PHAssetCollection]()
                var removedIndexesInSortedAlbums = [IndexPath]()
                for removedIndex in removedIndexes {
                    let albumToRemove = fetchedAlbumsArray[i][removedIndex.row]
                    if let index = sortedAlbumsArray[i].index(of: albumToRemove) {
                        remove(album: albumToRemove, indexPath: IndexPath(row: removedIndex.row, section: i), isFetchedIndex: true)
                        removedAlbums.append(albumToRemove)
                        removedIndexesInSortedAlbums.append(IndexPath(row: index, section: i))
                    } else {
                        logc("Error on model manipulation logic. Failed to find removed index in sortedAlbumsArray.")
                    }
                }
                DispatchQueue.main.async {
                    for subscriber in self.subscribers {
                        subscriber.assetsManager(manager: self, removedAlbums: removedAlbums, at: removedIndexesInSortedAlbums)
                    }
                }
            }
            // sync inserted albums
            if let insertedIndexes = albumsChangeDetail.insertedIndexes?.asArray().sorted(by: { $0.row < $1.row }) {
                var insertedAlbums = [PHAssetCollection]()
                var insertedIndexesInSortedAlbums = [IndexPath]()
                for insertedIndex in insertedIndexes {
                    let insertedAlbum = albumsChangeDetail.fetchResultAfterChanges.object(at: insertedIndex.row)
                    fetchAlbum(album: insertedAlbum)
                    insertedAlbums.append(insertedAlbum)
                    fetchedAlbumsArray[i].insert(insertedAlbum, at: insertedIndex.row)
                }
                sortedAlbumsArray[i] = sortedAlbums(fromAlbums: fetchedAlbumsArray[i])
                for insertedAlbum in insertedAlbums {
                    if let index = sortedAlbumsArray[i].index(of: insertedAlbum) {
                        insertedIndexesInSortedAlbums.append(IndexPath(row: index, section: i))
                    } else {
                        logc("Error on model manipulation logic. Failed to find insertes index in sortedAlbumsArray.")
                    }
                }
                DispatchQueue.main.async {
                    for subscriber in self.subscribers {
                        subscriber.assetsManager(manager: self, insertedAlbums: insertedAlbums, at: insertedIndexesInSortedAlbums)
                    }
                }
            }
            // sync updated albums
            if let updatedIndexes = albumsChangeDetail.changedIndexes?.asArray() {
                
                var updatedAlbums = [PHAssetCollection]()
                var updatedIndexesSetInSortedAlbums = IndexSet()
                
                let oldSortedAlbums = sortedAlbumsArray[i]
                
                for updatedIndex in updatedIndexes {
                    let updatedAlbum = albumsChangeDetail.fetchResultAfterChanges.object(at: updatedIndex.row)
                    fetchAlbum(album: updatedAlbum)
                    updatedAlbums.append(updatedAlbum)
                    if let oldIndex = oldSortedAlbums.index(of: updatedAlbum) {
                        updatedIndexesSetInSortedAlbums.insert(oldIndex)
                    }
                }
                
                sortedAlbumsArray[i] = sortedAlbums(fromAlbums: sortedAlbumsArray[i])
                
                for updatedAlbum in updatedAlbums {
                    if let newIndex = sortedAlbumsArray[i].index(of: updatedAlbum) {
                        updatedIndexesSetInSortedAlbums.insert(newIndex)
                    }
                }
                
                let sortedUpdatedIndexes = updatedIndexesSetInSortedAlbums.asArray().sorted(by: { $0.row < $1.row })
                updatedAlbums.removeAll()
                
                for sortedUpdatedIndex in sortedUpdatedIndexes {
                    updatedAlbums.append(sortedAlbumsArray[i][sortedUpdatedIndex.row])
                }
                
                DispatchQueue.main.async {
                    for subscriber in self.subscribers {
                        subscriber.assetsManager(manager: self, updatedAlbums: updatedAlbums, at: sortedUpdatedIndexes)
                    }
                }
            }
        }
    }
    
    func synchronizeAssets(changeInstance: PHChange) {
        // notify changes of assets
        for albums in sortedAlbumsArray {
            for album in albums {
                guard let fetchResult = fetchMap[album.localIdentifier], let assetsChangeDetails = changeInstance.changeDetails(for: fetchResult) else {
                    continue
                }
                fetchMap[album.localIdentifier] = assetsChangeDetails.fetchResultAfterChanges
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
                    let removedIndexes = removedIndexesSet.asArray().sorted(by: { $0.row < $1.row })
                    var removedAssets = [PHAsset]()
                    for removedIndex in removedIndexes.reversed() {
                        removedAssets.insert(assetArray.remove(at: removedIndex.row), at: 0)
                    }
                    // stop caching for removed assets
                    stopCache(assets: removedAssets, size: pickerConfig.assetCacheSize)
                    DispatchQueue.main.async {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, removedAssets: removedAssets, at: removedIndexes)
                        }
                    }
                }
                // sync inserted assets
                if let insertedIndexesSet = assetsChangeDetails.insertedIndexes {
                    let insertedIndexes = insertedIndexesSet.asArray().sorted(by: { $0.row < $1.row })
                    var insertedAssets = [PHAsset]()
                    for insertedIndex in insertedIndexes {
                        let insertedAsset = assetsChangeDetails.fetchResultAfterChanges.object(at: insertedIndex.row)
                        insertedAssets.append(insertedAsset)
                        assetArray.insert(insertedAsset, at: insertedIndex.row)
                    }
                    // start caching for inserted assets
                    cache(assets: insertedAssets, size: pickerConfig.assetCacheSize)
                    DispatchQueue.main.async {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, insertedAssets: insertedAssets, at: insertedIndexes)
                        }
                    }
                }
                // sync updated assets
                if let updatedIndexes = assetsChangeDetails.changedIndexes?.asArray() {
                    var updatedAssets = [PHAsset]()
                    for updatedIndex in updatedIndexes {
                        let updatedAsset = assetsChangeDetails.fetchResultAfterChanges.object(at: updatedIndex.row)
                        updatedAssets.append(updatedAsset)
                    }
                    // stop caching for updated assets
                    stopCache(assets: updatedAssets, size: pickerConfig.assetCacheSize)
                    cache(assets: updatedAssets, size: pickerConfig.assetCacheSize)
                    DispatchQueue.main.async {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, updatedAssets: updatedAssets, at: updatedIndexes)
                        }
                    }
                }
            }
        }
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard notifyIfAuthorizationStatusChanged() else {
            logw("Does not have access to photo library.")
            return
        }
        synchronizeAlbums(changeInstance: changeInstance)
        synchronizeAssets(changeInstance: changeInstance)
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
