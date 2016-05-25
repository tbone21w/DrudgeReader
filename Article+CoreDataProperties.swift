//
//  Article+CoreDataProperties.swift
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

extension Article {

    @NSManaged var location: String?
    @NSManaged var href: String?
    @NSManaged var id: NSNumber?
    @NSManaged var title: String?
    @NSManaged var imageURL: String?
    @NSManaged var createdAt: NSDate?
    @NSManaged var updatedAt: NSDate?
    @NSManaged var isNew: NSNumber?
    @NSManaged var read: NSNumber?
    @NSManaged var images: NSSet?
    @NSManaged var locations: NSSet?

}
