//
//  UIView+KVO.swift
//  Pods
//
//  Created by DragonCherry on 1/9/17.
//
//

import UIKit

private let kUIViewKVODictionaryKey = "kUIViewKVODictionaryKey"

public extension UIView {
    
    /** Set nil on first parameter to remove existing object for key. */
   func set(_ object: Any?, forKey key: AnyHashable) {
        var dictionary: [AnyHashable: Any]!
        if let savedDictionary = self.layer.value(forKey: kUIViewKVODictionaryKey) as? [AnyHashable: Any] {
            dictionary = savedDictionary
        } else {
            dictionary = [AnyHashable: Any]()
        }
        if let object = object {
            dictionary[key] = object
        } else {
            dictionary.removeValue(forKey: key)
        }
        self.layer.setValue(dictionary, forKey: kUIViewKVODictionaryKey)
    }
    
    func get(_ key: AnyHashable) -> Any? {
        if let dictionary = self.layer.value(forKey: kUIViewKVODictionaryKey) as? [AnyHashable: Any] {
            return dictionary[key]
        } else {
            return nil
        }
    }
}

