//
//  AssetsManager.swift
//  Pods
//
//  Created by DragonCherry on 5/19/17.
//
//

import UIKit
import Photos

// MARK: - AssetsManagerDelegate
public protocol AssetsManagerDelegate: class {
    
    func assetsManager(manager: AssetsManager, authorizationStatusChanged oldStatus: PHAuthorizationStatus, newStatus: PHAuthorizationStatus)
    func assetsManager(manager: AssetsManager, reloadedAlbumsInSection section: Int)
    func assetsManagerFetched(manager: AssetsManager)
    
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
    
    public static let shared = AssetsManager()
    
    open var pickerConfig = AssetsPickerConfig() {
        didSet {
            isFetchedAlbums = false
        }
    }
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var authorizationStatus = PHPhotoLibrary.authorizationStatus()
    var subscribers = [AssetsManagerDelegate]()
    
    fileprivate var albumMap = [String: PHAssetCollection]()
    
    var albumsFetchArray = [PHFetchResult<PHAssetCollection>]()
    var fetchMap = [String: PHFetchResult<PHAsset>]()
    
    /// stores originally fetched array
    var fetchedAlbumsArray = [[PHAssetCollection]]()
    /// stores sorted array by applying user defined comparator, it's in decreasing order by count by default, and it might same as fetchedAlbumsArray if AssetsPickerConfig has  albumFetchOptions without albumComparator
    var sortedAlbumsArray = [[PHAssetCollection]]()
    internal(set) open var assetArray = [PHAsset]()
    
    fileprivate(set) open var defaultAlbum: PHAssetCollection?
    fileprivate(set) open var cameraRollAlbum: PHAssetCollection!
    fileprivate(set) open var selectedAlbum: PHAssetCollection?
    
    fileprivate var isFetchedAlbums: Bool = false
    fileprivate var resourceLoadingQueue: DispatchQueue = DispatchQueue(label: "com.assetspicker.loader", qos: .userInitiated)
    
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

// MARK: - Subscriber
extension AssetsManager {
    
    open func subscribe(subscriber: AssetsManagerDelegate) {
        subscribers.append(subscriber)
    }
    
    open func unsubscribe(subscriber: AssetsManagerDelegate) {
        if let index = subscribers.firstIndex(where: { subscriber === $0 }) {
            subscribers.remove(at: index)
        }
    }

    open func unsubscribeAll() {
        subscribers.removeAll()
    }
    
    open func notifySubscribers(_ action: @escaping ((AssetsManagerDelegate) -> Void), condition: Bool = true) {
        if condition {
            DispatchQueue.main.sync {
                for subscriber in self.subscribers {
                    action(subscriber)
                }
            }
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
        return Int(fetchMap[sortedAlbumsArray[indexPath.section][indexPath.row].localIdentifier]?.count ?? 0)
    }
    
    open func indexPath(forAlbum target: PHAssetCollection, inAlbumsArray albumsArray: [[PHAssetCollection]]) -> IndexPath? {
        let section = albumSection(forType: target.assetCollectionType)
        if let row = albumsArray[section].firstIndex(of: target) {
            return IndexPath(row: row, section: section)
        } else {
            return nil
        }
    }
    
    open func title(at indexPath: IndexPath) -> String? {
        return sortedAlbumsArray[indexPath.section][indexPath.row].localizedTitle
    }
    
    open func imageOfAlbum(at indexPath: IndexPath, size: CGSize, isNeedDegraded: Bool = true, completion: @escaping ((UIImage?) -> Void)) -> PHImageRequestID? {
        let album = sortedAlbumsArray[indexPath.section][indexPath.row]
        if let fetchResult = fetchMap[album.localIdentifier] {
            if let asset = pickerConfig.assetsIsScrollToBottom ? fetchResult.lastObject : fetchResult.firstObject {
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                return imageManager.requestImage(
                    for: asset,
                    targetSize: size,
                    contentMode: .aspectFill,
                    options: options,
                    resultHandler: { (image, info) in
                        let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                        if !isNeedDegraded && isDegraded {
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
        return nil
    }
    
    @discardableResult
    open func image(at index: Int, size: CGSize, isNeedDegraded: Bool = true, completion: @escaping ((UIImage?, Bool) -> Void)) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        return imageManager.requestImage(
            for: assetArray[index],
            targetSize: size,
            contentMode: .aspectFill,
            options: options,
            resultHandler: { (image, info) in
                let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                if !isNeedDegraded && isDegraded {
                    return
                }
                DispatchQueue.main.async {
                    completion(image, isDegraded)
                }
        })
    }
    
    open func cancelRequest(requestId: PHImageRequestID) {
        imageManager.cancelImageRequest(requestId)
    }
    
    open func fetchResult(forAlbum album: PHAssetCollection) -> PHFetchResult<PHAsset>? {
        return fetchMap[album.localIdentifier]
    }
    
    open func album(at indexPath: IndexPath) -> PHAssetCollection {
        return sortedAlbumsArray[indexPath.section][indexPath.row]
    }
    
    open func albumSection(forType type: PHAssetCollectionType) -> Int {
        switch type {
        case .smartAlbum:
            return 0
        case .album:
            return 1
        case .moment:
            return 2
        @unknown default:
            fatalError()
        }
    }
    
    open func albumType(forSection section: Int) -> PHAssetCollectionType {
        switch section {
        case 0:
            return .smartAlbum
        case 1:
            return .album
        case 2:
            return .moment
        default:
            loge("Section number error: \(section)")
            return .album
        }
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
            logi("Selected same album.")
            return false
        }
        self.selectedAlbum = newAlbum
        if let fetchResult = fetchMap[newAlbum.localIdentifier] {
            let indexSet = IndexSet(0..<fetchResult.count)
            assetArray = fetchResult.objects(at: indexSet)
            return true
        } else {
            return false
        }
    }
    
    open func selectDefaultAlbum() {
        self.selectedAlbum = nil
        let allAlbums = sortedAlbumsArray.flatMap { $0 }.map { $0 }
        if let defaultAlbum = self.defaultAlbum, allAlbums.contains(defaultAlbum) {
            select(album: defaultAlbum)
        } else if let cameraRollAlbum = self.cameraRollAlbum, allAlbums.contains(cameraRollAlbum) {
            select(album: cameraRollAlbum)
        } else if let firstAlbum = allAlbums.first {
            select(album: firstAlbum)
        } else {
            logw("Cannot find fallback album!")
        }
    }
    
    open func selectAsync(album newAlbum: PHAssetCollection, completion: @escaping (Bool, [PHAsset]) -> Void) {
        if let oldAlbumIdentifier = self.selectedAlbum?.localIdentifier, oldAlbumIdentifier == newAlbum.localIdentifier {
            logi("Selected same album.")
            completion(false, [])
        }
        self.selectedAlbum = newAlbum
        if let fetchResult = fetchMap[newAlbum.localIdentifier] {
            resourceLoadingQueue.async { [weak self] in
                let indexSet = IndexSet(0..<fetchResult.count)
                let photos = fetchResult.objects(at: indexSet)
                self?.assetArray = photos
                DispatchQueue.main.async {
                    completion(true, photos)
                }
            }
        } else {
            completion(false, [])
        }
    }
}

// MARK: - Model Manipulation
extension AssetsManager {
    
    func isQualified(album: PHAssetCollection) -> Bool {
        if let albumFilter = pickerConfig.albumFilter?[album.assetCollectionType], let fetchResult = fetchMap[album.localIdentifier] {
            return albumFilter(album, fetchResult)
        }
        guard self.pickerConfig.albumIsShowHiddenAlbum || album.assetCollectionSubtype != .smartAlbumAllHidden else {
            return false
        }
        guard let fetchResult = self.fetchMap[album.localIdentifier], self.pickerConfig.albumIsShowEmptyAlbum || fetchResult.count > 0 else {
            return false
        }
        return true
    }
    
    func remove(album: PHAssetCollection? = nil, indexPath: IndexPath? = nil) {
        if let indexPath = indexPath {
            fetchedAlbumsArray[indexPath.section].remove(at: indexPath.row)
        } else if let albumToRemove = album {
            for (section, fetchedAlbums) in fetchedAlbumsArray.enumerated() {
                if let row = fetchedAlbums.firstIndex(of: albumToRemove) {
                    fetchedAlbumsArray[section].remove(at: row)
                }
            }
        } else {
            logw("Empty parameters.")
        }
    }
    
    func sortedAlbums(fromAlbums albums: [PHAssetCollection]) -> [PHAssetCollection] {
        guard let albumType = albums.first?.assetCollectionType else {
            return albums
        }
        let filtered = albums.filter { self.isQualified(album: $0) }
        if let comparator = pickerConfig.albumComparator {
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
                return filtered.sorted(by: { Int((self.fetchMap[$0.localIdentifier]?.count) ?? 0) > Int((self.fetchMap[$1.localIdentifier]?.count) ?? 0) })
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
    
    func isCountChanged(changeDetails: PHFetchResultChangeDetails<PHAsset>) -> Bool {
        return changeDetails.fetchResultBeforeChanges.count != changeDetails.fetchResultAfterChanges.count
    }
    
    func isThumbnailChanged(changeDetails: PHFetchResultChangeDetails<PHAsset>) -> Bool {
        
        var isChanged: Bool = false
        
        if let lastBeforeChange = changeDetails.fetchResultBeforeChanges.lastObject {
            if let lastAfterChange = changeDetails.fetchResultAfterChanges.lastObject {
                if lastBeforeChange.localIdentifier == lastAfterChange.localIdentifier {
                    if let _ = changeDetails.changedObjects.firstIndex(of: lastAfterChange) {
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
    
    open func fetchAlbums(isRefetch: Bool = false, completion: @escaping (([[PHAssetCollection]]) -> Void)) {
        
        if isRefetch {
            selectedAlbum = nil
            isFetchedAlbums = false
            fetchedAlbumsArray.removeAll()
            sortedAlbumsArray.removeAll()
            albumsFetchArray.removeAll()
            fetchMap.removeAll()
            albumMap.removeAll()
        }
        
        resourceLoadingQueue.async { [weak self] in
            guard let `self` = self else { return }
            if !self.isFetchedAlbums {
                
                let smartAlbumEntry = self.fetchAlbums(forAlbumType: .smartAlbum)
                self.fetchedAlbumsArray.append(smartAlbumEntry.fetchedAlbums)
                self.sortedAlbumsArray.append(smartAlbumEntry.sortedAlbums)
                self.albumsFetchArray.append(smartAlbumEntry.fetchResult)
                
                let albumEntry = self.fetchAlbums(forAlbumType: .album)
                self.fetchedAlbumsArray.append(albumEntry.fetchedAlbums)
                self.sortedAlbumsArray.append(albumEntry.sortedAlbums)
                self.albumsFetchArray.append(albumEntry.fetchResult)
                
                if self.pickerConfig.albumIsShowMomentAlbums {
                    let momentEntry = self.fetchAlbums(forAlbumType: .moment)
                    self.fetchedAlbumsArray.append(momentEntry.fetchedAlbums)
                    self.sortedAlbumsArray.append(momentEntry.sortedAlbums)
                    self.albumsFetchArray.append(momentEntry.fetchResult)
                }
                self.subscribers.forEach { [weak self] (delegate) in
                    guard let `self` = self else { return }
                    DispatchQueue.main.async {
                        delegate.assetsManagerFetched(manager: self)
                    }
                }
                self.isFetchedAlbums = true
            }
            // notify
            DispatchQueue.main.async {
                completion(self.sortedAlbumsArray)
            }
        }
    }
    
    open func fetchAssets(isRefetch: Bool = false, completion: (([PHAsset]) -> Void)? = nil) {
        
        fetchAlbums(isRefetch: isRefetch, completion: { [weak self] _ in
            
            guard let `self` = self else { return }
            if isRefetch {
                self.assetArray.removeAll()
            }
            
            // set default album
            self.selectAsync(album: self.defaultAlbum ?? self.cameraRollAlbum) { result, photos in
                completion?(photos)
            }
        })
        
    }
    
    func fetchAlbums(forAlbumType type: PHAssetCollectionType) -> (fetchedAlbums: [PHAssetCollection], sortedAlbums: [PHAssetCollection], fetchResult: PHFetchResult<PHAssetCollection>) {
        
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
    func fetchAlbum(album: PHAssetCollection) -> PHFetchResult<PHAsset> {
        
        let fetchResult = PHAsset.fetchAssets(in: album, options: self.pickerConfig.assetFetchOptions?[album.assetCollectionType])
        
        // cache fetch result
        self.fetchMap[album.localIdentifier] = fetchResult
        
        // cache album
        self.albumMap[album.localIdentifier] = album
        
        return fetchResult
    }
    
}

// MARK: - IndexSet Utility
extension IndexSet {
    func asArray(section: Int? = nil) -> [IndexPath] {
        var indexPaths = [IndexPath]()
        if count > 0 {
            for entry in enumerated() {
                indexPaths.append(IndexPath(row: entry.element, section: section ?? 0))
            }
        }
        return indexPaths
    }
}
