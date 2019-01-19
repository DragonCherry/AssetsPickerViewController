//
//  AssetsPickerCustomStringConfig.swift
//  Pods
//
//  Created by Zonily Jame Pesquera on 5/22/17.
//
//

import Foundation

public typealias AssetsPickerCustomStringConfig = [AssetsPickerLocalizedStringKey: String]

// These are the available string keys on AssetsPickerViewController.strings
public enum AssetsPickerLocalizedStringKey: String {
    case cancel = "Cancel"
    case done = "Done"
    case titleAlbums = "Title_Albums"
    case titleSectionMyAlbums = "Title_Section_MyAlbums"
    case footerPhotos = "Footer_Photos"
    case footerVideos = "Footer_Videos"
    case footerItems = "Footer_Items"
    case titleSelectedPhoto = "Title_Selected_Photo"
    case titleSelectedPhotos = "Title_Selected_Photos"
    case titleSelectedVideo = "Title_Selected_Video"
    case titleSelectedVideos = "Title_Selected_Videos"
    case titleSelectedItems = "Title_Selected_Items"
    case titleNoItems = "Title_No_Items"
    case messageNoItems = "Message_No_Items"
    case messageNoItemsCamera = "Message_No_Items_Camera"
    case titleNoPermission = "Title_No_Permission"
    case messageNoPermission = "Message_No_Permission"
}
