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
                    let albumToRemove = fetchedAlbumsArray[section].remove(at: removedIndex.row)
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
                    remove(album: albumToRemove, indexPath: removedIndex)
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
                let newSortedAlbums = sortedAlbums(fromAlbums: fetchedAlbumsArray[section])
                
                // find removed indexPaths
                let removedInfo = removedIndexPaths(from: newSortedAlbums, oldAlbums: oldSortedAlbums, section: section)
                for removedIndex in removedInfo.indexPaths {
                    oldSortedAlbums.remove(at: removedIndex.row)
                    updatedIndexesSetInSortedAlbums.remove(removedIndex.row)
                }
                // update albums before notify removed albums
                sortedAlbumsArray[section] = oldSortedAlbums
                
                // notify removed indexPaths
                if removedInfo.indexPaths.count > 0 {
                    DispatchQueue.main.sync {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, removedAlbums: removedInfo.albums, at: removedInfo.indexPaths)
                        }
                    }
                }
                
                // find inserted indexPaths
                let insertedInfo = insertedIndexPaths(from: oldSortedAlbums, oldAlbums: newSortedAlbums, section: section)
                
                // update albums before notify inserted albums
                sortedAlbumsArray[section] = newSortedAlbums
                
                // notify inserted indexPaths
                if insertedInfo.indexPaths.count > 0 {
                    DispatchQueue.main.sync {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, insertedAlbums: insertedInfo.albums, at: insertedInfo.indexPaths)
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
                
                if updatedAlbums.count > 0 {
                    DispatchQueue.main.sync {
                        for subscriber in self.subscribers {
                            subscriber.assetsManager(manager: self, updatedAlbums: updatedAlbums, at: sortedUpdatedIndexes)
                        }
                    }
                }
            }
        }
        
        return updateMaps
    }
    
    func synchronizeAssets(sortedAlbumsArrayBeforeChanges: [[PHAssetCollection]], fetchMapBeforeChanges: [String: PHFetchResult<PHAsset>], changeInstance: PHChange) -> [IndexPath] {
        
        // thumbnail-updated indexes
        var updatedAlbumIndexPaths = [IndexPath]()
        
        // notify changes of assets
        for (section, albums) in fetchedAlbumsArray.enumerated() {
            
            // remove unqualified albums
            var indexPathsToRemove = [IndexPath]()
            var albumsToRemove = [PHAssetCollection]()
            
            for (_, album) in albums.enumerated() {
                log("Looping album: \(album.localizedTitle ?? "")")
                guard let fetchResult = fetchMapBeforeChanges[album.localIdentifier], let assetsChangeDetails = changeInstance.changeDetails(for: fetchResult) else {
                    continue
                }
                
                // check thumbnail
                if isThumbnailChanged(changeDetails: assetsChangeDetails) || isCountChanged(changeDetails: assetsChangeDetails) {
                    if let sortedIndex = sortedAlbumsArray[section].index(of: album) {
                        updatedAlbumIndexPaths.append(IndexPath(row: sortedIndex, section: section))
                    }
                }
                
                // update fetch result for each album
                fetchMap[album.localIdentifier] = assetsChangeDetails.fetchResultAfterChanges
                
                // remove newly unqualified albums
                if let indexPathToRemove = indexPath(forAlbum: album) {
                    if !isQualified(album: album) {
                        indexPathsToRemove.append(indexPathToRemove)
                        albumsToRemove.append(album)
                        remove(album: album, indexPath: indexPathToRemove)
                        if let index = updatedAlbumIndexPaths.index(of: indexPathToRemove) {
                            updatedAlbumIndexPaths.remove(at: index)
                        }
                    }
                }
                
                // reload if hasIncrementalChanges is false
                guard assetsChangeDetails.hasIncrementalChanges else {
                    DispatchQueue.main.sync {
                        for subscriber in subscribers {
                            if let indexPathForAlbum = indexPath(forAlbum: album) {
                                subscriber.assetsManager(manager: self, reloadedAlbum: album, at: indexPathForAlbum)
                            }
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
                    if removedAssets.count > 0 {
                        DispatchQueue.main.sync {
                            for subscriber in self.subscribers {
                                subscriber.assetsManager(manager: self, removedAssets: removedAssets, at: removedIndexes)
                            }
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
                    if insertedAssets.count > 0 {
                        DispatchQueue.main.sync {
                            for subscriber in self.subscribers {
                                subscriber.assetsManager(manager: self, insertedAssets: insertedAssets, at: insertedIndexes)
                            }
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
                    if updatedAssets.count > 0 {
                        DispatchQueue.main.sync {
                            for subscriber in self.subscribers {
                                subscriber.assetsManager(manager: self, updatedAssets: updatedAssets, at: updatedIndexes)
                            }
                        }
                    }
                }
            }
            
            // notify unqualified albums
            if albumsToRemove.count > 0 {
                DispatchQueue.main.sync {
                    for subscriber in subscribers {
                        subscriber.assetsManager(manager: self, removedAlbums: albumsToRemove, at: indexPathsToRemove)
                    }
                }
            }
            
            // insert notify newly qualified albums
            let newSortedAlbums = sortedAlbums(fromAlbums: fetchedAlbumsArray[section])
            let insertedInfo = insertedIndexPaths(from: newSortedAlbums, oldAlbums: sortedAlbumsArray[section], section: section)
            sortedAlbumsArray[section] = newSortedAlbums
            
            // notify inserted indexPaths
            if insertedInfo.indexPaths.count > 0 {
                DispatchQueue.main.sync {
                    for subscriber in self.subscribers {
                        subscriber.assetsManager(manager: self, insertedAlbums: insertedInfo.albums, at: insertedInfo.indexPaths)
                    }
                }
            }
        }
        
        return updatedAlbumIndexPaths
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
    
    public func updatedIndexPaths(from newAlbums: [PHAssetCollection], oldAlbums: [PHAssetCollection], section: Int) -> (indexPaths: [IndexPath], albums: [PHAssetCollection]) {
        // find updated indexPaths
        var shorterAlbums: PHAssetCollection!
        
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
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        logi("Called!")
        guard notifyIfAuthorizationStatusChanged() else {
            logw("Does not have access to photo library.")
            return
        }
        let fetchMapBeforeChanges = fetchMap
        let sortedAlbumsArrayBeforeChanges = sortedAlbumsArray
        let updateCheckMap = synchronizeAlbums(changeInstance: changeInstance)
        let indexPathsNeedUpdateAlbum = synchronizeAssets(
            sortedAlbumsArrayBeforeChanges: sortedAlbumsArrayBeforeChanges,
            fetchMapBeforeChanges: fetchMapBeforeChanges,
            changeInstance: changeInstance
        )
        
        var indexPathsToUpdateAlbum = [IndexPath]()
        var albumsToUpdate = [PHAssetCollection]()
        
        for indexPath in indexPathsNeedUpdateAlbum {
            if updateCheckMap[indexPath.section][indexPath.row] == nil {
                // avoid duplicated UI update for optimization
                indexPathsToUpdateAlbum.append(indexPath)
                albumsToUpdate.append(sortedAlbumsArray[indexPath.section][indexPath.row])
            }
        }
        if albumsToUpdate.count > 0 {
            DispatchQueue.main.sync {
                for subscriber in self.subscribers {
                    subscriber.assetsManager(manager: self, updatedAlbums: albumsToUpdate, at: indexPathsToUpdateAlbum)
                }
            }
        }
    }
}
