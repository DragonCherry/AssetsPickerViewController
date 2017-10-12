//
//  AssetsManager+Sync.swift
//  Pods
//
//  Created by DragonCherry on 6/2/17.
//
//

import Photos
import TinyLog

// MARK: - PHPhotoLibraryChangeObserver & Sync
extension AssetsManager: PHPhotoLibraryChangeObserver {
    
    func synchronizeAlbums(changeInstance: PHChange) -> [IndexSet] {
        
        // updated index set
        var updatedIndexSets = [IndexSet]()
        
        // notify changes of albums
        for (section, albumsFetchResult) in albumsFetchArray.enumerated() {
            
            var updatedIndexSet = IndexSet()
            defer { updatedIndexSets.append(updatedIndexSet) }
            
            guard let albumsChangeDetail = changeInstance.changeDetails(for: albumsFetchResult) else { continue }
            
            // update albumsFetchArray
            albumsFetchArray[section] = albumsChangeDetail.fetchResultAfterChanges
            
            guard albumsChangeDetail.hasIncrementalChanges else {
                notifySubscribers({ $0.assetsManager(manager: self, reloadedAlbumsInSection: section) })
                continue
            }
            // sync removed albums
            if let removedIndexes = albumsChangeDetail.removedIndexes?.reversed() {
                for removedIndex in removedIndexes.enumerated() {
                    remove(indexPath: IndexPath(row: removedIndex.element, section: section))
                }
            }
            // sync inserted albums
            if let insertedIndexes = albumsChangeDetail.insertedIndexes {
                for insertedIndex in insertedIndexes.enumerated() {
                    let insertedAlbum = albumsChangeDetail.fetchResultAfterChanges.object(at: insertedIndex.element)
                    fetchAlbum(album: insertedAlbum)
                    fetchedAlbumsArray[section].insert(insertedAlbum, at: insertedIndex.element)
                    updatedIndexSet.insert(insertedIndex.element)
                }
            }
            // sync updated albums
            if let updatedIndexes = albumsChangeDetail.changedIndexes {
                for updatedIndex in updatedIndexes.enumerated() {
                    let updatedAlbum = albumsChangeDetail.fetchResultAfterChanges.object(at: updatedIndex.element)
                    fetchAlbum(album: updatedAlbum)
                    updatedIndexSet.insert(updatedIndex.element)
                }
            }
        }
        return updatedIndexSets
    }
    
    func synchronizeAssets(updatedAlbumIndexSets: [IndexSet], fetchMapBeforeChanges: [String: PHFetchResult<PHAsset>], changeInstance: PHChange) {
        
        var updatedIndexSets = updatedAlbumIndexSets
        
        // notify changes of assets
        for (section, albums) in fetchedAlbumsArray.enumerated() {
            
            // remove unqualified albums
            var updatedIndexSet = updatedIndexSets[section]
            
            for (_, album) in albums.enumerated() {
                log("Looping album: \(album.localizedTitle ?? "")")
                guard let fetchResult = fetchMapBeforeChanges[album.localIdentifier], let assetsChangeDetails = changeInstance.changeDetails(for: fetchResult) else {
                    continue
                }
                
                // check thumbnail
                if isThumbnailChanged(changeDetails: assetsChangeDetails) || isCountChanged(changeDetails: assetsChangeDetails) {
                    if let updatedRow = fetchedAlbumsArray[section].index(of: album) {
                        updatedIndexSet.insert(updatedRow)
                    }
                }
                
                // update fetch result for each album
                fetchMap[album.localIdentifier] = assetsChangeDetails.fetchResultAfterChanges
                
                // reload if hasIncrementalChanges is false
                guard assetsChangeDetails.hasIncrementalChanges else {
                    notifySubscribers({ subscriber in
                        if let indexPathForAlbum = self.indexPath(forAlbum: album, inAlbumsArray: self.sortedAlbumsArray) {
                            subscriber.assetsManager(manager: self, reloadedAlbum: album, at: indexPathForAlbum)
                        }
                    })
                    continue
                }
                guard let selectedAlbum = self.selectedAlbum, selectedAlbum.localIdentifier == album.localIdentifier else { continue }
                
                // sync removed assets
                if let removedIndexesSet = assetsChangeDetails.removedIndexes {
                    let removedIndexes = removedIndexesSet.asArray().sorted(by: { $0.row < $1.row })
                    var removedAssets = [PHAsset]()
                    for removedIndex in removedIndexes.reversed() {
                        removedAssets.insert(assetArray.remove(at: removedIndex.row), at: 0)
                    }
                    // stop caching for removed assets
                    stopCache(assets: removedAssets, size: pickerConfig.assetCacheSize)
                    notifySubscribers({ $0.assetsManager(manager: self, removedAssets: removedAssets, at: removedIndexes) }, condition: removedAssets.count > 0)
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
                    notifySubscribers({ $0.assetsManager(manager: self, insertedAssets: insertedAssets, at: insertedIndexes) }, condition: insertedAssets.count > 0)
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
                    notifySubscribers({ $0.assetsManager(manager: self, updatedAssets: updatedAssets, at: updatedIndexes) }, condition: updatedAssets.count > 0)
                }
            }
            
            // update final changes in albums
            var oldSortedAlbums = sortedAlbumsArray[section]
            let newSortedAlbums = sortedAlbums(fromAlbums: fetchedAlbumsArray[section])

            /* 1. find & notify removed albums. */
            let removedInfo = removedIndexPaths(from: newSortedAlbums, oldAlbums: oldSortedAlbums, section: section)
            for (i, removedIndexPath) in removedInfo.indexPaths.enumerated() {
                oldSortedAlbums.remove(at: removedIndexPath.row)
                if let fetchedIndexPath = indexPath(forAlbum: removedInfo.albums[i], inAlbumsArray: fetchedAlbumsArray) {
                    updatedIndexSet.remove(fetchedIndexPath.row)
                }
            }
            sortedAlbumsArray[section] = oldSortedAlbums
            notifySubscribers({ $0.assetsManager(manager: self, removedAlbums: removedInfo.albums, at: removedInfo.indexPaths) }, condition: removedInfo.indexPaths.count > 0)
            
            /* 2. find & notify inserted albums. */
            let insertedInfo = insertedIndexPaths(from: newSortedAlbums, oldAlbums: oldSortedAlbums, section: section)
            for (i, insertedIndexPath) in insertedInfo.indexPaths.enumerated() {
                oldSortedAlbums.insert(insertedInfo.albums[i], at: insertedIndexPath.row)
                if let fetchedIndexPath = indexPath(forAlbum: insertedInfo.albums[i], inAlbumsArray: fetchedAlbumsArray) {
                    updatedIndexSet.insert(fetchedIndexPath.row)
                }
            }
            sortedAlbumsArray[section] = newSortedAlbums
            notifySubscribers({ $0.assetsManager(manager: self, insertedAlbums: insertedInfo.albums, at: insertedInfo.indexPaths) }, condition: insertedInfo.indexPaths.count > 0)
            
            // check logic
            if oldSortedAlbums.count == newSortedAlbums.count {
                for i in 0..<oldSortedAlbums.count {
                    if oldSortedAlbums[i].localIdentifier != newSortedAlbums[i].localIdentifier {
                        updatedIndexSet.insert(i)
                    }
                }
            } else {
                logc("oldSortedAlbums and newSortedAlbums is not same!")
            }
            
            /* 3. notify updated albums. */
            let updatedIndexes = updatedIndexSet.asArray(section: section).sorted(by: { $0.row < $1.row })
            var sortedUpdatedIndexPaths = [IndexPath]()
            var sortedUpdatedAlbums = [PHAssetCollection]()
            
            for updatedIndex in updatedIndexes {
                let updatedAlbum = fetchedAlbumsArray[section][updatedIndex.row]
                if let sortedIndexPath = indexPath(forAlbum: updatedAlbum, inAlbumsArray: sortedAlbumsArray) {
                    sortedUpdatedIndexPaths.append(sortedIndexPath)
                    sortedUpdatedAlbums.append(updatedAlbum)
                }
            }
            notifySubscribers({ $0.assetsManager(manager: self, updatedAlbums: sortedUpdatedAlbums, at: sortedUpdatedIndexPaths) }, condition: sortedUpdatedAlbums.count > 0)
        }
    }

    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard notifyIfAuthorizationStatusChanged() else {
            logw("Does not have access to photo library.")
            return
        }
        let fetchMapBeforeChanges = fetchMap
        let updatedAlbumIndexSets = synchronizeAlbums(changeInstance: changeInstance)
        synchronizeAssets(
            updatedAlbumIndexSets: updatedAlbumIndexSets,
            fetchMapBeforeChanges: fetchMapBeforeChanges,
            changeInstance: changeInstance
        )
    }
    
    public func removedIndexPaths(from newAlbums: [PHAssetCollection], oldAlbums: [PHAssetCollection], section: Int) -> (indexPaths: [IndexPath], albums: [PHAssetCollection]) {
        // find removed indexPaths
        var removedIndexPaths = [IndexPath]()
        var removedAlbums = [PHAssetCollection]()
        for (i, oldSortedAlbum) in oldAlbums.enumerated().reversed() {
            guard newAlbums.contains(oldSortedAlbum) else {
                removedAlbums.append(oldSortedAlbum)
                removedIndexPaths.append(IndexPath(row: i, section: section))
                continue
            }
        }
        return (removedIndexPaths, removedAlbums)
    }
    
    public func insertedIndexPaths(from newAlbums: [PHAssetCollection], oldAlbums: [PHAssetCollection], section: Int) -> (indexPaths: [IndexPath], albums: [PHAssetCollection]) {
        // find inserted indexPaths
        var insertedIndexPaths = [IndexPath]()
        var insertedAlbums = [PHAssetCollection]()
        for (i, sortedAlbum) in newAlbums.enumerated() {
            guard oldAlbums.contains(sortedAlbum) else {
                insertedAlbums.append(sortedAlbum)
                insertedIndexPaths.append(IndexPath(row: i, section: section))
                continue
            }
        }
        return (insertedIndexPaths, insertedAlbums)
    }
}
