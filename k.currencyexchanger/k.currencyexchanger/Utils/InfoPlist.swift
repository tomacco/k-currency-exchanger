//
//  InfoPlist.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 29/9/22.
//

import Foundation

class InfoPlist {
    
    static func stringForKeyOrNil(key: String) -> String? {
        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
    
    static func stringFor(key: String) -> String {
        return Bundle.main.object(forInfoDictionaryKey: key) as! String
    }
    
    static func dictForKeyOrNil(key: String) -> Dictionary<String, Any>? {
        return Bundle.main.object(forInfoDictionaryKey: key) as? Dictionary<String, Any>
    }
    
    static func dictFor(key: String) -> Dictionary<String, Any> {
        return Bundle.main.object(forInfoDictionaryKey: key) as! Dictionary<String, Any>
    }

}
