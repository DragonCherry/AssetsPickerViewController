## AssetsPickerViewController

[![Version](https://img.shields.io/cocoapods/v/AssetsPickerViewController.svg?style=flat)](http://cocoapods.org/pods/AssetsPickerViewController)
[![License](https://img.shields.io/cocoapods/l/AssetsPickerViewController.svg?style=flat)](http://cocoapods.org/pods/AssetsPickerViewController)
[![Platform](https://img.shields.io/cocoapods/p/AssetsPickerViewController.svg?style=flat)](http://cocoapods.org/pods/AssetsPickerViewController)

Customizable assets picker controller that supports selecting multiple photos and videos, fully written in Swift.


## Comment

This project is still under development so many features will be added, and will get better in the near future.

If you found any bugs - even in develop branch, do not hesitate raise an issue for it.

Any advice, suggestions, and pull request will be greatly appreciated.


## Screenshots

iOS friendly UI for Album

![albums_portrait](https://cloud.githubusercontent.com/assets/20486591/26525542/43036a42-4395-11e7-98f0-5bf3f40f923d.PNG)


iOS friendly UI for Asset

![photos_portrait](https://cloud.githubusercontent.com/assets/20486591/26525538/42b1d6dc-4395-11e7-9c16-b9abdb2e9247.PNG)


For landscape, keeps focusing indexes even during decelerating.

![photos_landscape](https://cloud.githubusercontent.com/assets/20486591/26525541/42f44f4e-4395-11e7-80e2-e1dd890a4d16.PNG)


Handles empty or no permisson cases.

![no_photos](https://cloud.githubusercontent.com/assets/20486591/26525540/42f25e82-4395-11e7-9dc2-73e04bcc9f00.PNG)
![no_permission](https://cloud.githubusercontent.com/assets/20486591/26525539/42e6759a-4395-11e7-9bae-1b90f6d3ec44.PNG)


Customizable Album Layout

![customize_album](https://cloud.githubusercontent.com/assets/20486591/26616647/1d343c24-460b-11e7-94cf-3b46a0f2e0a2.png)


Customizable Asset Layout

![customize_asset](https://cloud.githubusercontent.com/assets/20486591/26616648/1d385746-460b-11e7-9324-62ea634e2fcb.png)


## Features Done

- iOS friendly UI for album & photo controllers

- select album

- select multiple photos and videos

- realtime synchronization for library change in albums & photos

- customizable album cell

- customizable album order

- customizable asset cell

- customizable asset order

- option to show empty albums

- fully customizable configuration by settings struct model


## Features To-do

- iPad support

- single select mode with crop

- enhance example codes

- support many languages(German, French, Spanish, Chinese, Japanese, etc)


## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```ruby
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
