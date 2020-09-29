
# Now iOS 14 supports multiple asset picker by default. I recommend use PHPickerViewController instead of this picker for many reasons.

## AssetsPickerViewController

[![Version](https://img.shields.io/cocoapods/v/AssetsPickerViewController.svg?style=flat)](http://cocoapods.org/pods/AssetsPickerViewController)
[![License](https://img.shields.io/cocoapods/l/AssetsPickerViewController.svg?style=flat)](http://cocoapods.org/pods/AssetsPickerViewController)
[![Platform](https://img.shields.io/cocoapods/p/AssetsPickerViewController.svg?style=flat)](http://cocoapods.org/pods/AssetsPickerViewController)

Customizable assets picker controller that supports selecting multiple photos and videos, fully written in Swift.


## Comment

AssetsPickerViewController acts like Photos App in iOS.

If you found any bugs - even in develop branch, do not hesitate raise an issue for it.

Any advice, suggestions, and pull requests for new feature will be greatly appreciated.


## Just try it in web simulator, don't waste your time

https://appetize.io/app/752b6azuj3d3varvmu1hkwuuqm


## Screenshots

iOS friendly UI for Album & Asset

![albums_portrait](https://cloud.githubusercontent.com/assets/20486591/26525542/43036a42-4395-11e7-98f0-5bf3f40f923d.PNG)
![photos_portrait](https://user-images.githubusercontent.com/20486591/66302122-50d12b00-e933-11e9-8594-cf3d9e36d582.png)
![photos_portrait](https://user-images.githubusercontent.com/20486591/66302136-56c70c00-e933-11e9-910f-9e97cb882d31.png)


iPad Support

![ipad_landscape](https://user-images.githubusercontent.com/20486591/26968848-89474890-4d3e-11e7-9277-c949511eb491.png)


Keeps focusing indexes during orientation change.

![photos_landscape](https://cloud.githubusercontent.com/assets/20486591/26525541/42f44f4e-4395-11e7-80e2-e1dd890a4d16.PNG)


Handles empty or no permisson cases.

![no_photos](https://cloud.githubusercontent.com/assets/20486591/26525540/42f25e82-4395-11e7-9dc2-73e04bcc9f00.PNG)
![no_permission](https://cloud.githubusercontent.com/assets/20486591/26525539/42e6759a-4395-11e7-9bae-1b90f6d3ec44.PNG)


Customizable Album & Asset Layout

![customize_album](https://cloud.githubusercontent.com/assets/20486591/26616647/1d343c24-460b-11e7-94cf-3b46a0f2e0a2.png)
![customize_asset](https://cloud.githubusercontent.com/assets/20486591/26616648/1d385746-460b-11e7-9324-62ea634e2fcb.png)


3D Touch to Preview

![3d_touch](https://user-images.githubusercontent.com/20486591/27173588-2d2d5a94-51f4-11e7-961e-4ca4759a97c5.PNG)



## Features Done

- iOS friendly UI for album & photo controllers

- select album

- select multiple photos and videos

- realtime synchronization for library change in albums & photos

- option to show/hide empty albums

- option to show/hide "Hidden" album

- customizable album cell

- customizable album sorting by PHFetchOptions or filter block

- customizable album filtering by PHFetchOptions or filter block

- customizable asset cell

- customizable asset sorting by PHFetchOptions

- customizable asset filtering by PHFetchOptions

- iPad support

- force(3D) touch to preview - (still, live photo, and video)

- support many languages(German, French, Spanish, Chinese, Japanese, Arabic, Spanish, Korean, Indonesian, Russian, Turkish, Italian, etc)

- set selected assets before present picker controller

- supports dark mode from iOS 13

- takes and auto-selects photo or video took inside picker

- multiple selection by dragging cells (from iOS 13)

- SPM(Swift Package Manager) support


## Features To-do

- Cropping image before select

## Basic Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```swift
// to show
let picker = AssetsPickerViewController()
picker.pickerDelegate = self
present(picker, animated: true, completion: nil)

// to handle
extension SimpleExampleController: AssetsPickerViewControllerDelegate {
    
    func assetsPickerCannotAccessPhotoLibrary(controller: AssetsPickerViewController) {}
    func assetsPickerDidCancel(controller: AssetsPickerViewController) {}
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
        // do your job with selected assets
    }
    func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        return true
    }
    func assetsPicker(controller: AssetsPickerViewController, didSelect asset: PHAsset, at indexPath: IndexPath) {}
    func assetsPicker(controller: AssetsPickerViewController, shouldDeselect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        return true
    }
    func assetsPicker(controller: AssetsPickerViewController, didDeselect asset: PHAsset, at indexPath: IndexPath) {}
}
```

## Bonus

### Basic

To hide empty albums,
```swift
pickerConfig.albumIsShowEmptyAlbum = false
```

To show "Hidden" albums,
```swift
pickerConfig.albumIsShowHiddenAlbum = true
```

To set pre-selected assets before present picker,
```swift
pickerConfig.selectedAssets = self.assets
```

To limit selected assets count,
```swift
func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {   
    if controller.selectedAssets.count > 3 {
        // do your job here
        return false
    }
    return true
}
```

To enable single image select mode, deselect all items when the limit has reached,
```swift
func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {   
    if controller.selectedAssets.count > 0 {
        controller.photoViewController.deselectAll()
    }
    return true
}
```

To automatically deselect oldest selected asset for limited selection count,
```swift
pickerConfig.assetsMaximumSelectionCount = 5
```

### Appearence

To apply custom album cell,
```swift
pickerConfig.albumCellType = CustomAlbumCell.classForCoder()
// and implement your own UICollectionViewCell which conforms to AssetsAlbumCellProtocol
```

To apply custom asset cell,
```swift
pickerConfig.assetCellType = CustomAssetCell.classForCoder()
// and implement your own UICollectionViewCell which conforms to AssetsPhotoCellProtocol
```

### Sorting

To sort albums by PHFetchOptions,
```swift
let options = PHFetchOptions()
options.sortDescriptors = [NSSortDescriptor(key: "estimatedAssetCount", ascending: true)]
        
pickerConfig.albumFetchOptions = [
    .smartAlbum: options
]
```

To sort by block for a certain reason,
```swift
pickerConfig.albumComparator = { (albumType, leftEntry, rightEntry) -> Bool in
    // return: Is leftEntry ordered before the rightEntry?
    switch albumType {
    case .smartAlbum:
        return leftEntry.album.assetCollectionSubtype.rawValue < rightEntry.album.assetCollectionSubtype.rawValue
    case .album:
        return leftEntry.result.count < rightEntry.result.count     // ascending order by asset count
    case .moment:
        return true
    }
}
```

To sort assets by PHFetchOptions,
```swift
let options = PHFetchOptions()
options.sortDescriptors = [
    NSSortDescriptor(key: "pixelWidth", ascending: true),
    NSSortDescriptor(key: "pixelHeight", ascending: true)
]

pickerConfig.assetFetchOptions = [
    .smartAlbum: options
]
```

### Filtering

To filter albums by PHFetchOptions,
```swift
let options = PHFetchOptions()
options.predicate = NSPredicate(format: "estimatedAssetCount = 0")
pickerConfig.albumFetchOptions = [.smartAlbum: options]
```

To filter albums by block for a certain reason,
```swift
// return true to include, false to discard.
let smartAlbumFilter: ((PHAssetCollection, PHFetchResult<PHAsset>) -> Bool) = { (album, fetchResult) in
    // filter by album object
    if album.assetCollectionSubtype == .smartAlbumBursts { return false }
    if album.assetCollectionSubtype == .smartAlbumTimelapses { return false }
    if album.assetCollectionSubtype == .smartAlbumFavorites { return false }
            
    // filter by fetch result
    if fetchResult.count > 50 {
        return true     // only shows albums that contains more than 50 assets
    } else {
        return false    //
    }
}
pickerConfig.albumFilter = [
    .smartAlbum: smartAlbumFilter
]
```

To filter assets by PHFetchOptions,
```swift
let options = PHFetchOptions()
options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
options.sortDescriptors = [NSSortDescriptor(key: "duration", ascending: true)]
        
pickerConfig.assetFetchOptions = [
    .smartAlbum: options,
    .album: options
]
```

### Custom Localization Support

To set your own custom strings just use the static `customStringConfig` property of  `AssetsPickerConfig` which is of type `AssetsPickerCustomStringConfig`.

Overriding every string
```swift
AssetsPickerConfig.customStringConfig = [
    .cancel: "Cancel",
    .done: "Done",
    .titleAlbums: "Albums",
    .titleSectionMyAlbums: "My Albums",
    .footerPhotos: "%@ Photos",
    .footerVideos: "%@ Videos",
    .footerItems: "%@ Photos, %@ Videos",
    .titleSelectedPhoto: "%@ Photo Selected",
    .titleSelectedPhotos: "%@ Photos Selected",
    .titleSelectedVideo: "%@ Video Selected",
    .titleSelectedVideos: "%@ Videos Selected",
    .titleSelectedItems: "%@ Items Selected",
    .titleNoItems: "No Photos or Videos",
    .messageNoItems: "You can take photos and videos using the camera, or sync photos and videos onto your %@ using iTunes.",
    .messageNoItemsCamera: "You can sync photos and videos onto your %@ using iTunes.",
    .titleNoPermission: "This app does not have access to your photos or videos.",
    .messageNoPermission: "You can enable access in Privacy Settings.",
]
```

Overriding specific strings
```swift
AssetsPickerConfig.customStringConfig = [
    .titleNoItems: "No Photos or Videos",
    .messageNoItems: "You can take photos and videos using the camera, or sync photos and videos onto your %@ using iTunes.",
    .messageNoItemsCamera: "You can sync photos and videos onto your %@ using iTunes.",
    .titleNoPermission: "This app does not have access to your photos or videos.",
    .messageNoPermission: "You can enable access in Privacy Settings.",
]
```

Take note: If you don't set the strings correctly these can cause problems.

## Requirements & Dependency

Xcode10.2, Swift 5, iOS 10.0

Uses [SnapKit](https://github.com/SnapKit/SnapKit) for creating UI inside library. Thanks to SnapKit development team for doing such a beautiful job.

if your app's deployment target is greater than or equal to 11.0, you can use up-to-date version of SnapKit, otherwise you have to fix SnapKit's version to 5.0.0


## Installation

AssetsPickerViewController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AssetsPickerViewController', '~> 2.0'
```

Swift 4 is not supported anymore.

## Author

DragonCherry, dragoncherry@naver.com


## License

AssetsPickerViewController is available under the MIT license. See the LICENSE file for more info.

MIT License

Copyright (c) 2017 DragonCherry

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
