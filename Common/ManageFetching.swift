//
//  RequestFetching.swift
//  AssetsPickerViewController
//
//  Created by JY on 2020/07/03.
//

import Photos

// MARK: - Image Fetching IDs
protocol ManageFetching: NSObject {
    
    var requestMap: [IndexPath: PHImageRequestID] { get set }
}

extension ManageFetching {
    func cancelFetching(at indexPath: IndexPath) {
        if let requestId = requestMap[indexPath] {
            self.requestMap.removeValue(forKey: indexPath)
            if LogConfig.isFetchLogEnabled { logd("Canceled ID: \(requestId) at: \(indexPath.row) (\(self.requestMap.count))") }
            AssetsManager.shared.cancelRequest(requestId: requestId)
        }
    }
    
    func registerFetching(requestId: PHImageRequestID, at indexPath: IndexPath) {
        self.requestMap[indexPath] = requestId
        if LogConfig.isFetchLogEnabled { logd("Registered ID: \(requestId) at: \(indexPath.row) (\(self.requestMap.count))") }
    }
    
    func removeFetching(indexPath: IndexPath) {
        if let requestId = requestMap[indexPath] {
            self.requestMap.removeValue(forKey: indexPath)
            if LogConfig.isFetchLogEnabled { logd("Removed ID: \(requestId) at: \(indexPath.row) (\(self.requestMap.count))") }
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


