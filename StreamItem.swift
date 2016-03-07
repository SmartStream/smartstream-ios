//
//  StreamItem.swift
//  SmartStream
//
//  Created by Hieu Nguyen on 3/3/16.
//  Copyright © 2016 SmartStream. All rights reserved.
//

import UIKit

class StreamItem: NSObject, Comparable {
    let dictionary: NSDictionary
    let url: String?
    let id: String?
    let extractor: String?
    let timestamp: NSTimeInterval?
    
    init(dictionary: NSDictionary) {
        self.dictionary = dictionary

        url = dictionary["url"] as? String
        id = dictionary["id"] as? String
        extractor = dictionary["extractor"] as? String
        timestamp = NSDate().timeIntervalSince1970
    }
    
    class func items(array array: [NSDictionary]) -> [StreamItem] {
        var items = [StreamItem]()
        for dictionary in array {
            let item = StreamItem(dictionary: dictionary)
            items.append(item)
        }
        return items
    }
}

// ==========================================================
// Note: for now the items are ordered based on their 
//       timestamps but this can easily be modified to look at 
//       the priority field first (when there is one), so they
//       would be ordered based on priorities. And only look
//       at the timestamp for tie-breaker.
// ==========================================================
func < (lhs: StreamItem, rhs: StreamItem) -> Bool {
    return lhs.timestamp < rhs.timestamp
}

func == (lhs: StreamItem, rhs: StreamItem) -> Bool {
    return lhs.timestamp == rhs.timestamp
}
