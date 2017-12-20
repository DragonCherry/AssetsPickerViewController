//
//  ShowAlbumListOnStartupController.swift
//  AssetsPickerViewController_Example
//
//  Created by DragonCherry on 20/12/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import AssetsPickerViewController

class ShowAlbumListOnStartupController: CommonExampleController {
    
    override func pressedPick(_ sender: Any) {
        
        // I've tried to solve this inside library, but I found that it's hard to present one more VC in presenting VC.
        // So, this is kind of workaround that allows user to select album before see their photos.
        
        let pickerConfig = AssetsPickerConfig()
        
        let picker = AssetsPickerViewController(pickerConfig: pickerConfig)
        picker.pickerDelegate = self
        
        let albumVC = AssetsAlbumViewController(pickerConfig: pickerConfig)
        albumVC.delegate = picker.photoViewController
        let albumNavi = UINavigationController(rootViewController: albumVC)
        albumNavi.modalPresentationStyle = .overCurrentContext
        
        if #available(iOS 11.0, *) {
            albumNavi.navigationBar.prefersLargeTitles = true
        }
        
        picker.modalPresentationStyle = .overCurrentContext
        present(picker, animated: false, completion: nil)
        picker.view.isHidden = true
        picker.present(albumNavi, animated: true, completion: {
            picker.view.isHidden = false
        })
    }
}

