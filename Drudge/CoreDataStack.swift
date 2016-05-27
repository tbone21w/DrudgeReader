//
//  CoreDataStack.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/17/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import UIKit
import CoreData

class CoreDataStack {
  
  
  let modelName = "Drudge"
  
  
  lazy var context: NSManagedObjectContext = {
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    managedObjectContext.persistentStoreCoordinator = self.psc
    
    return managedObjectContext
  }()
  
  
  lazy var privateContext: NSManagedObjectContext = {
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    
    managedObjectContext.parentContext = self.context
    managedObjectContext.name = "Primary Private Queue"
    //managedObjectContext.mergePolicy = NSMerge
    
    return managedObjectContext
  }()
  
  
  private lazy var psc: NSPersistentStoreCoordinator = {
    
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
    let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(self.modelName)
    print("CORE DATA PATH \(url)")
    
    do {
      let options = [NSMigratePersistentStoresAutomaticallyOption : true]
      
      try coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                                                 configuration: nil,
                                                 URL: url,
                                                 options: options)
    } catch  {
      print("Error adding persistent store.")
    }
    
    return coordinator
  }()
  
  
  private lazy var managedObjectModel: NSManagedObjectModel = {
    
    let modelURL = NSBundle.mainBundle().URLForResource(self.modelName, withExtension: "momd")!
    
    return NSManagedObjectModel(contentsOfURL: modelURL)!
  }()
  
  
  
  private lazy var applicationDocumentsDirectory: NSURL = {
    let urls = NSFileManager
                    .defaultManager()
                    .URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
    return urls[urls.count-1]
  }()
  
  
  // MARK: CoreData Operations
  func saveContext () throws {
    
    var error: ErrorType?
    
    //propagate any child context changes to the parent
    privateContext.performBlockAndWait { () -> Void in
      if self.privateContext.hasChanges {
        do {
          try self.privateContext.save()
        } catch let saveError as NSError {
            error = saveError
            print("Could not save \(saveError), \(saveError.code), \(saveError.localizedFailureReason)")
        }
      }
    }
    
    //exit if we have an error
    if let error = error {
      throw error
    }
    
    //save the main context
    context.performBlockAndWait { () -> Void in
      if self.context.hasChanges {
        do {
          try self.context.save()
        } catch let saveError as NSError {
          print("Error: \(saveError.localizedDescription)")
          error = saveError
        }
      }
    }
    
    if let error = error {
      throw error
    }
    
  }
  

  func getArticleCount() -> Int {
    let fetchRequest = NSFetchRequest(entityName: "Article")
    
    fetchRequest.resultType = .CountResultType
    
    var count = 0
    
    do {
      let results = try privateContext.executeFetchRequest(fetchRequest) as! [NSNumber]
      
      count = results.first!.integerValue
    } catch let error as NSError {
      print("Could not fetch \(error), \(error.userInfo)")
    }
    
    return count
  }
  

  
  func getNewArticleCount() -> Int {
    let fetchRequest = NSFetchRequest(entityName: "Article")
    
    fetchRequest.resultType = .CountResultType
    
    fetchRequest.predicate = NSPredicate(format: "isNew = true")
    
    var count = 0
    
    do {
      let results = try privateContext.executeFetchRequest(fetchRequest) as! [NSNumber]
      
      count = results.first!.integerValue
    } catch let error as NSError {
      print("Could not fetch \(error), \(error.userInfo)")
    }
    
    return count
  }
  
  
  func getMostRecentArticleDate() -> NSDate? {
    let fetchRequest = NSFetchRequest(entityName: "Article")
    
    fetchRequest.resultType = .DictionaryResultType
    
    let sumExpressionDescription = NSExpressionDescription()
    sumExpressionDescription.name = "MaxDate"
    sumExpressionDescription.expression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "updatedAt")])
    
    sumExpressionDescription.expressionResultType = .DateAttributeType
    
    fetchRequest.propertiesToFetch = [sumExpressionDescription]
    
    var maxDate:NSDate?
    
    do {
      let results = try privateContext.executeFetchRequest(fetchRequest)
      
      if let result = results.first {
        maxDate = result["MaxDate"] as? NSDate
      }

      print("MAX Date: \(maxDate)")
      
    } catch let error as NSError {
      print("\(error)")
    }
    
    print("MAX Date: \(maxDate)")
    return maxDate
  }
  
  
  func resetNewArticles() {
    let request = NSBatchUpdateRequest(entityName: "Article")
    request.predicate = NSPredicate(format: "isNew = true")
    request.propertiesToUpdate = ["isNew" : false]
    
    request.resultType = .UpdatedObjectsCountResultType
    
    do {
      try privateContext.executeRequest(request)
      try context.save()
    } catch {
      print (error)
    }
    
  }
  
  //TODO need a preference on how many days to keep for now 30
  func cleanupOldArticles() {
    
    let fetchRequest = NSFetchRequest(entityName: "Article")
    
    let today = NSDate()
    let cutOffDate = NSCalendar.currentCalendar().dateByAddingUnit(
      .Day,
      value: -30,
      toDate: today,
      options: NSCalendarOptions(rawValue: 0))
    
    fetchRequest.predicate = NSPredicate(format: "updatedAt < %@", cutOffDate!)
    
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    deleteRequest.resultType = .ResultTypeObjectIDs
    
    do {
      //TODO grab IDs and remove photos for removed items
      try context.executeRequest(deleteRequest)
      try context.save()
    } catch {
      print (error)
    }
  }
  
}
