//
//  Article.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/17/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import Foundation
import CoreData


class Article: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
  func getImageKey() -> String? {
    if let imageurl = imageURL {
      let url = NSURL(string: imageurl)!
      return "\(id)\(url.pathComponents?.last)"
    } else {
      return nil
    }
    
  }
}
