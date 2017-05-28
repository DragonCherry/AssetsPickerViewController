## AssetsPickerViewController

[![Version](https://img.shields.io/cocoapods/v/AssetsPickerViewController.svg?style=flat)](http://cocoapods.org/pods/HFSwipeView)
[![License](https://img.shields.io/cocoapods/l/AssetsPickerViewController.svg?style=flat)](http://cocoapods.org/pods/HFSwipeView)
[![Platform](https://img.shields.io/cocoapods/p/AssetsPickerViewController.svg?style=flat)](http://cocoapods.org/pods/AssetsPickerViewController)

Customizable assets picker controller that supports selecting multiple photos and videos, fully written in Swift.

## Screenshots

![albums_portrait](https://cloud.githubusercontent.com/assets/20486591/26525542/43036a42-4395-11e7-98f0-5bf3f40f923d.PNG)
![photos_portrait](https://cloud.githubusercontent.com/assets/20486591/26525538/42b1d6dc-4395-11e7-9c16-b9abdb2e9247.PNG)
![photos_landscape](https://cloud.githubusercontent.com/assets/20486591/26525541/42f44f4e-4395-11e7-80e2-e1dd890a4d16.PNG)
![no_photos](https://cloud.githubusercontent.com/assets/20486591/26525540/42f25e82-4395-11e7-9dc2-73e04bcc9f00.PNG)
![no_permission](https://cloud.githubusercontent.com/assets/20486591/26525539/42e6759a-4395-11e7-9bae-1b90f6d3ec44.PNG)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

This project is still under development as many features will be added in the future.

Any advice and suggestions will be greatly appreciated.


## Features Done

- iOS friendly style album & photo UI

- select album

- select multiple photos and videos

- realtime sync for library change in albums & photos

- customizable album cell

- customizable asset cell


## Features To-do

- customizable album order

- customizable asset order

- single select mode with crop

- fully customizable configuration by settings struct model

- Enhance example codes

- etc


## Example

```ruby
// to show
let picker = AssetsPickerViewController()
picker.pickerDelegate = self
present(picker, animated: true, completion: nil)

// to handle
extension SimpleExampleController: AssetsPickerViewControllerDelegate {
    
    func assetsPickerCannotAccessPhotoLibrary(controller: AssetsPickerViewController) {}
    func assetsPickerDidCancel(controller: AssetsPickerViewController) {}
    func assetsPickerNotGranted(controller: AssetsPickerViewController) {}
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

## Requirements

Xcode8, Swift 3, iOS 9.0


## Installation

AssetsPickerViewController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "AssetsPickerViewController"
```

## Author

DragonCherry, dragoncherry@naver.com


## License

AssetsPickerViewController is available under the MIT license. See the LICENSE file for more info.
