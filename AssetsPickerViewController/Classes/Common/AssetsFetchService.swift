//
//  AssetsFetchService.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 2020/07/03.
//

import Photos

// MARK: - Image Fetching IDs
class AssetsFetchService {
    
    var requestMap = [IndexPath: PHImageRequestID]()

    func cancelFetching(at indexPath: IndexPath) {
        if let requestId = requestMap[indexPath] {
            requestMap.removeValue(forKey: indexPath)
            if LogConfig.isFetchLogEnabled { logd("Canceled ID: \(requestId) at: \(indexPath.row) (\(self.requestMap.count))") }
            AssetsManager.shared.cancelRequest(requestId: requestId)
        }
    }
    
    func registerFetching(requestId: PHImageRequestID, at indexPath: IndexPath) {
        requestMap[indexPath] = requestId
        if LogConfig.isFetchLogEnabled { logd("Requested ID: \(requestId) at: \(indexPath.row) (\(self.requestMap.count))") }
    }
    
    func removeFetching(indexPath: IndexPath) {
        if let requestId = requestMap[indexPath] {
            requestMap.removeValue(forKey: indexPath)
            if LogConfig.isFetchLogEnabled { logd("Finished ID: \(requestId) at: \(indexPath.row) (\(self.requestMap.count))") }
        }
    }
    
    func isFetching(indexPath: IndexPath) -> Bool {
        if let _ = requestMap[indexPath] {
            return true
        } else {
            return false
        }
    }
}


