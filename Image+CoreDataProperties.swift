//
//  Image+CoreDataProperties.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/23/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Image {

    @NSManaged var id: NSNumber?
    @NSManaged var src: String?
    @NSManaged var article: Article?

}
