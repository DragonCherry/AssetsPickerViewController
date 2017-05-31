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
    
    open var pickerConfig = AssetsPickerConfig() {
        didSet {
            isFetchedAlbums = false
        }
    }
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var authorizationStatus = PHPhotoLibrary.authorizationStatus()
    fileprivate var subscribers = [AssetsManagerDelegate]()
    
    fileprivate var albumMap = [String: PHAssetCollection]()
    
    fileprivate var albumsFetchArray = [PHFetchResult<PHAssetCollection>]()
    fileprivate var fetchMap = [String: PHFetchResult<PHAsset>]()
    
    /// stores originally fetched array
    fileprivate var fetchedAlbumsArray = [[PHAssetCollection]]()
    /// stores sorted array by applying user defined comparator, it's in decreasing order by count by default, and it might same as fetchedAlbumsArray if AssetsPickerConfig has  albumFetchOptions without albumComparator
    fileprivate var sortedAlbumsArray = [[PHAssetCollection]]()
    fileprivate(set) open var assetArray = [PHAsset]()
    
    fileprivate(set) open var defaultAlbum: PHAssetCollection?
    fileprivate(set) open var cameraRollAlbum: PHAssetCollection!
    fileprivate(set) open var selectedAlbum: PHAssetCollection?
    
    fileprivate var isFetchedAlbums: Bool = false
    
    private override init() {
        super.init()
    }
    
    deinit { logd("Released \(type(of: self))") }
    
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
        
        logd("cleared AssetsManager object.")
    }
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
                    break
                }
            }
        }
        if typeIndex > -1 && subtypeIndex > -1 {
            return IndexPath(row: subtypeIndex, section: typeIndex)
        } else {
            logw("Failed to find indexPath for album: \(target.localizedTitle ?? "")")
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

// MARK: - Model Manipulation
extension AssetsManager {
    
    fileprivate func isQualified(album: PHAssetCollection) -> Bool {
        guard self.pickerConfig.albumIsShowHiddenAlbum || album.assetCollectionSubtype != .smartAlbumAllHidden else {
            return false
        }
        guard let fetchResult = self.fetchMap[album.localIdentifier], self.pickerConfig.albumIsShowEmptyAlbum || fetchResult.count > 0 else {
            return false
        }
        return true
    }
    
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
        guard let albumType = albums.first?.assetCollectionType else {
            logw("sortedAlbums has empty albums.")
            return albums
        }
        let filtered = albums.filter { self.isQualified(album: $0) }
        if let comparator = pickerConfig.albumComparator?[albumType] {
            return filtered.sorted(by: { (leftAlbum, rightAlbum) -> Bool in
                if let leftResult = self.fetchMap[leftAlbum.localIdentifier], let rightResult = self.fetchMap[rightAlbum.localIdentifier] {
                    return comparator(leftAlbum.assetCollectionType, (leftAlbum, leftResult), (rightAlbum, rightResult))
                } else {
                    logw("Failed to get fetch result from fetchMap. Please raise an issue if you've met this message.")
                    return true
                }
            })
        } else {
            if let _ = pickerConfig.albumFetchOptions?[albumType] {
                // return fetched album as it is
                return filtered
            } else {
                // default: by count
                return filtered.sorted(by: { Int(self.fetchMap[$0.localIdentifier]?.count) > Int(self.fetchMap[$1.localIdentifier]?.count) })
            }
        }
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
        select(album: defaultAlbum ?? cameraRollAlbum)
        
        completion?(assetArray)
    }
    
    fileprivate func fetchAlbums(forAlbumType type: PHAssetCollectionType) -> (fetchedAlbums: [PHAssetCollection], sortedAlbums: [PHAssetCollection], fetchResult: PHFetchResult<PHAssetCollection>) {
        
        let fetchOption = pickerConfig.albumFetchOptions?[type]
        let albumFetchResult = PHAssetCollection.fetchAssetCollections(with: type, subtype: .any, options: fetchOption)
        var fetchedAlbums = [PHAssetCollection]()
        
        albumFetchResult.enumerateObjects({ (album, _, _) in
            // fetch assets
            self.fetchAlbum(album: album)
            
            // set default album
            if album.assetCollectionSubtype == self.pickerConfig.albumDefaultType {
                self.defaultAlbum = album
            }
            // save alternative album
            if album.assetCollectionSubtype == .smartAlbumUserLibrary {
                self.cameraRollAlbum = album
            }
            fetchedAlbums.append(album)
        })
        
        // get sorted albums
        let sortedAlbums = self.sortedAlbums(fromAlbums: fetchedAlbums)
        
        // set default album
        if let defaultAlbum = self.defaultAlbum {
            logi("Default album is \"\(defaultAlbum.localizedTitle ?? "")\"")
        } else {
            if let defaultAlbum = self.defaultAlbum {
                logi("Set default album \"\(defaultAlbum.localizedTitle ?? "")\"")
            } else {
                if let cameraRollAlbum = self.cameraRollAlbum {
                    self.defaultAlbum = cameraRollAlbum
                    logw("Set default album with fallback default album \"\(cameraRollAlbum.localizedTitle ?? "")\"")
                } else {
                    if let firstAlbum = sortedAlbums.first, type == .smartAlbum {
                        self.defaultAlbum = firstAlbum
                        loge("Set default album with first item \"\(firstAlbum.localizedTitle ?? "")\"")
                    } else {
                        logc("Is this case could happen? Please raise an issue if you've met this message.")
                    }
                }
            }
        }
        
        // append album fetch result
        return (fetchedAlbums, sortedAlbums, albumFetchResult)
    }
    
    @discardableResult
    fileprivate func fetchAlbum(album: PHAssetCollection) -> PHFetchResult<PHAsset> {
        
        let fetchResult = PHAsset.fetchAssets(in: album, options: self.pickerConfig.assetFetchOptions?[album.assetCollectionType])
        
        // cache fetch result
        self.fetchMap[album.localIdentifier] = fetchResult
        
        // cache album
        self.albumMap[album.localIdentifier] = album
        
        return fetchResult
    }
    
}

// MARK: - PHPhotoLibraryChangeObserver & Sync
extension AssetsManager: PHPhotoLibraryChangeObserver {
    
    func synchronizeAlbums(changeInstance: PHChange) -> [[Int: Bool]] {
        
        // updated indexes
        var updateMaps = [[Int: Bool]]()
        
        // notify changes of albums
        for (section, albumsFetchResult) in albumsFetchArray.enumerated() {
            
            var updateMap = [Int: Bool]()
            
            defer { updateMaps.append(updateMap) }
            
            guard let albumsChangeDetail = changeInstance.changeDetails(for: albumsFetchResult) else {
                continue
            }
            
            // update albumsFetchArray
            albumsFetchArray.remove(at: section)
            albumsFetchArray.insert(albumsChangeDetail.fetchResultAfterChanges, at: section)
            
            guard albumsChangeDetail.hasIncrementalChanges else {
                DispatchQueue.main.async {
                    for subscriber in self.subscribers {
                        subscriber.assetsManager(manager: self, reloadedAlbumsInSection: section)
                    }
                }
                continue
            }
            // sync removed albums
            if let removedIndexes = albumsChangeDetail.removedIndexes?.asArray().sorted(by: { $0.row > $1.row }) {
                var removedAlbums = [PHAssetCollection]()
                var removedIndexesInSortedAlbums = [IndexPath]()
                for removedIndex in removedIndexes {
                    let albumToRemove = fetchedAlbumsArray[section][removedIndex.row]
                    if let index = sortedAlbumsArray[section].index(of: albumToRemove) {
                        removedIndexesInSortedAlbums.append(IndexPath(row: index, section: section))
                    }
                }
                removedIndexesInSortedAlbums.sort(by: { $0.row > $1.row })
                for removedIndex in removedIndexesInSortedAlbums {
                    // update fetchedAlbumsArray & sortedAlbumsArray
                    logi("before remove [\(removedIndex.section)][\(removedIndex.row)]")
                    let albumToRemove = sortedAlbumsArray[section][removedIndex.row]
                    removedAlbums.append(albumToRemove)
                    remove(album: albumToRemove, indexPath: removedIndex, isFetchedIndex: false)
                }
                DispatchQueue.main.sync {
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
                    if isQualified(album: insertedAlbum) {
                        insertedAlbums.append(insertedAlbum)
                    }
                    fetchedAlbumsArray[section].insert(insertedAlbum, at: insertedIndex.row)
                }
                sortedAlbumsArray[section] = sortedAlbums(fromAlbums: fetchedAlbumsArray[section])
                for insertedAlbum in insertedAlbums {
                    if let index = sortedAlbumsArray[section].index(of: insertedAlbum) {
                        insertedIndexesInSortedAlbums.append(IndexPath(row: index, section: section))
                        updateMap[index] = true
                    }
                }
                DispatchQueue.main.sync {
                    for subscriber in self.subscribers {
                        subscriber.assetsManager(manager: self, insertedAlbums: insertedAlbums, at: insertedIndexesInSortedAlbums)
                    }
                }
            }
            // sync updated albums
            if let updatedIndexes = albumsChangeDetail.changedIndexes?.asArray() {
                
                var updatedAlbums = [PHAssetCollection]()
                var updatedIndexesSetInSortedAlbums = IndexSet()
                
                var oldSortedAlbums = sortedAlbumsArray[section]
                
                for updatedIndex in updatedIndexes {
                    let updatedAlbum = albumsChangeDetail.fetchResultAfterChanges.object(at: updatedIndex.row)
                    fetchAlbum(album: updatedAlbum)
                    updatedAlbums.append(updatedAlbum)
                    if let oldIndex = oldSortedAlbums.index(of: updatedAlbum) {
                        updatedIndexesSetInSortedAlbums.insert(oldIndex)
                    }
                }
                
                // get renewed array
                let newlySortedAlbums = sortedAlbums(fromAlbums: fetchedAlbumsArray[section])
             
                // find removed indexPaths
                var removedIndexPaths = [IndexPath]()
                var removedAlbums = [PHAssetCollection]()
                for (i, oldSortedAlbum) in oldSortedAlbums.enumerated().reversed() {
                    guard newlySortedAlbums.contains(oldSortedAlbum) else {
                        removedAlbums.append(oldSortedAlbum)
                        removedIndexPaths.append(IndexPath(row: i, section: section))
                        oldSortedAlbums.remove(at: i)
                        updatedIndexesSetInSortedAlbums.remove(i)
                        continue
                    }
                }
                // update albums before notify removed albums
                sortedAlbumsArray[section] = oldSortedAlbums
                
                // notify removed indexPaths
                if removedIndexPaths.count > 0 {
                    DispatchQueue.main.sync {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, removedAlbums: removedAlbums, at: removedIndexPaths)
                        }
                    }
                }
                
                // find inserted indexPaths
                var insertedIndexPaths = [IndexPath]()
                var insertedAlbums = [PHAssetCollection]()
                for (i, sortedAlbum) in newlySortedAlbums.enumerated() {
                    guard oldSortedAlbums.contains(sortedAlbum) else {
                        insertedAlbums.append(sortedAlbum)
                        insertedIndexPaths.append(IndexPath(row: i, section: section))
                        continue
                    }
                }
                // update albums before notify inserted albums
                sortedAlbumsArray[section] = newlySortedAlbums
                
                // notify inserted indexPaths
                if insertedIndexPaths.count > 0 {
                    DispatchQueue.main.sync {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, insertedAlbums: insertedAlbums, at: insertedIndexPaths)
                        }
                    }
                }
                
                for updatedAlbum in updatedAlbums {
                    if let newIndex = sortedAlbumsArray[section].index(of: updatedAlbum) {
                        updatedIndexesSetInSortedAlbums.insert(newIndex)
                    }
                }
                
                let sortedUpdatedIndexes = updatedIndexesSetInSortedAlbums.asArray(section: section).sorted(by: { $0.row < $1.row })
                updatedAlbums.removeAll()
                
                for sortedUpdatedIndex in sortedUpdatedIndexes {
                    updatedAlbums.append(sortedAlbumsArray[section][sortedUpdatedIndex.row])
                    updateMap[sortedUpdatedIndex.row] = true
                }
                
                DispatchQueue.main.sync {
                    for subscriber in self.subscribers {
                        subscriber.assetsManager(manager: self, updatedAlbums: updatedAlbums, at: sortedUpdatedIndexes)
                    }
                }
            }
        }
        
        return updateMaps
    }
    
    func synchronizeAssets(fetchMapBeforeChanges: [String: PHFetchResult<PHAsset>], changeInstance: PHChange) -> [IndexPath] {
        
        // thumbnail-updated indexes
        var thumbnailUpdatedIndexPaths = [IndexPath]()
        
        // notify changes of assets
        for (section, albums) in sortedAlbumsArray.enumerated() {
            for (row, album) in albums.enumerated() {
                log("Looping album: \(album.localizedTitle ?? "")")
                guard let fetchResult = fetchMapBeforeChanges[album.localIdentifier], let assetsChangeDetails = changeInstance.changeDetails(for: fetchResult) else {
                    continue
                }
                
                // check thumbnail
                if isThumbnailChanged(changeDetails: assetsChangeDetails) {
                    thumbnailUpdatedIndexPaths.append(IndexPath(row: row, section: section))
                }
                
                // update fetch result for each album
                fetchMap[album.localIdentifier] = assetsChangeDetails.fetchResultAfterChanges
                
                // reload if hasIncrementalChanges is false
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
                
                // update UI if current album is updated
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
                    DispatchQueue.main.sync {
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
                    DispatchQueue.main.sync {
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
                    DispatchQueue.main.sync {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, updatedAssets: updatedAssets, at: updatedIndexes)
                        }
                    }
                }
            }
        }
        
        return thumbnailUpdatedIndexPaths
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        logi("Called!")
        guard notifyIfAuthorizationStatusChanged() else {
            logw("Does not have access to photo library.")
            return
        }
        let fetchMapBeforeChanges = fetchMap
        let updateCheckMap = synchronizeAlbums(changeInstance: changeInstance)
        let indexPathsNeedUpdateThumbnail = synchronizeAssets(fetchMapBeforeChanges: fetchMapBeforeChanges, changeInstance: changeInstance)
        
        var indexPathsToUpdateThumbnail = [IndexPath]()
        var albumsToUpdateThumbnail = [PHAssetCollection]()
        
        for indexPath in indexPathsNeedUpdateThumbnail {
            if updateCheckMap[indexPath.section][indexPath.row] == nil {
                // avoid duplicated UI update for optimization
                indexPathsToUpdateThumbnail.append(indexPath)
                albumsToUpdateThumbnail.append(sortedAlbumsArray[indexPath.section][indexPath.row])
            }
        }
        if albumsToUpdateThumbnail.count > 0 {
            DispatchQueue.main.sync {
                for subscriber in self.subscribers {
                    subscriber.assetsManager(manager: self, updatedAlbums: albumsToUpdateThumbnail, at: indexPathsToUpdateThumbnail)
                }
            }
        }
    }
}

// MARK: - IndexSet Utility
extension IndexSet {
    fileprivate func asArray(section: Int? = nil) -> [IndexPath] {
        var indexPaths = [IndexPath]()
        if count > 0 {
            for entry in enumerated() {
                indexPaths.append(IndexPath(row: entry.element, section: section ?? 0))
            }
        }
        return indexPaths
    }
}
