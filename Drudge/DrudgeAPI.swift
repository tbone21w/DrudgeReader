//
//  DrudgeAPI.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/17/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import UIKit
import CoreData

enum PathComponent: String {
  case Articles = "articles"
  case SnapShots = "snapshots"
  case LatestArticles = "articles/latest"
}

enum DrudgeAPIResult {
  case Success([Article])
  case Failure(ErrorType)
}

enum ArticleSerialization {
  case Success(Article)
  case Failure(ErrorType)
}

enum DrudgeAPIError: ErrorType {
  case InvalidJSONData
  case NilData
  case DuplicateObject
}

/**
 * Builds API URL's and handles JSON serialization
 */
class DrudgeAPI {
  
  private static let baseURL = "http://45.55.175.213/api/v1"
  

  //"2016-05-22T08:17:08.595288-04:00"
  static let formatterISO8601: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSxxx"
    
    return formatter
  }()

  
  
  
  
  private class func drudgeURL(path path:PathComponent, parameters: [String: String]?) -> NSURL {
    let components = NSURLComponents(string: baseURL)!
    
    var queryItems = [NSURLQueryItem]()
    
    if let additionalParams = parameters {
      for (key, value) in additionalParams {
        let item = NSURLQueryItem(name: key, value: value)
        queryItems.append(item)
      }
    }
    
    components.queryItems = queryItems

    return components.URL!.URLByAppendingPathComponent(path.rawValue)
  }
  
  func articlesFromJSONData( inContext context: NSManagedObjectContext, data:NSData?) -> DrudgeAPIResult {
    
    guard let jsonData = data else {
      return .Failure(DrudgeAPIError.NilData)
    }
    
    //process dictionary into JSON
    do {
      let jsonObject: AnyObject = try NSJSONSerialization.JSONObjectWithData(jsonData, options: [])
      
      //unwrap jsonObject
      guard let
        jsonArticles = jsonObject as? [[String:AnyObject]]
        
        else {
          print("The JSON structure doesn't match our expectations")
          return .Failure(DrudgeAPIError.InvalidJSONData)
      }
      
      //Valid JSON
      var articles = [Article]()
      for articleJSON in jsonArticles {
        
        let result = articleFromJSONData(inContext: context, json: articleJSON)
        
        //articleFromJSONData(inContext: context, json: articleJSON)
        switch  result {
        case let .Success(article):
          articles.append(article)
        case let .Failure(error):
          let e = error as! DrudgeAPIError
          //ignore duplicate objects
          if e != DrudgeAPIError.DuplicateObject {
            return .Failure(e)
          }
        }
//        if let article = articleFromJSONData(inContext: context, json: articleJSON) {
//          print("Article:   \(article.title!)  \(article.updatedAt!)")
//          
//          articles.append(article)
//        } else {
//          return .Failure(DrudgeAPIError.InvalidJSONData)
//        }
      }
      
      //TODO MOVE to ArticleManager
      //save to DB
//      do {
//        try coreDataStack.saveContext()
//      } catch let error as NSError {
//        print("Error cleaning up core data \(error)")
//      }
      
      print("Number of Articles: \(articles.count)")
      
      return .Success(articles)
    } catch let error {
      //TODO return .Failure(error)
      print("Error serializing data to JSON \(error)")
      return .Failure(DrudgeAPIError.InvalidJSONData)
    }
  }
  
  
  func articleFromJSONData(inContext context: NSManagedObjectContext, json: [String : AnyObject]) -> ArticleSerialization {
    
    guard let
      currentLocation = json["location"] as? String,
      href = json["href"] as? String,
      id = json["id"] as? NSNumber,
      text = json["title"] as? String,
      imageURL = json["image_url"] as? String,
      created = json["created_at"] as? String,
      createdDate = DrudgeAPI.formatterISO8601.dateFromString(created),
      updated = json["updated_at"] as? String,
      updatedDate = DrudgeAPI.formatterISO8601.dateFromString(updated)
      else {
        print("invalid JSON string")
        return .Failure(DrudgeAPIError.InvalidJSONData)
    }
    

    
    //check for valid object
    if !containsArticle(inContext: context, id: id.intValue){
      let articleEntity = NSEntityDescription.entityForName("Article", inManagedObjectContext: context)
      let article = Article(entity: articleEntity!, insertIntoManagedObjectContext: context)
      
      article.id = id
      article.href = href
      article.title = text
      article.location = currentLocation
      article.imageURL = imageURL
      article.createdAt = createdDate
      article.updatedAt = updatedDate
      
      return .Success(article)
    }
  
    print("Found Duplicate ID: \(id)")
    return .Failure(DrudgeAPIError.DuplicateObject)
  }
  
  func containsArticle(inContext context: NSManagedObjectContext, id: Int32 ) -> Bool {
    let fetchRequest = NSFetchRequest(entityName: "Article")
    
    fetchRequest.resultType = .CountResultType
    
    fetchRequest.predicate = NSPredicate(format: "id = %D", id)
    
    var count = 0
    
    do {
      let results = try context.executeFetchRequest(fetchRequest) as! [NSNumber]
      
      count = results.first!.integerValue
    } catch let error as NSError {
      print("Could not fetch \(error), \(error.userInfo)")
    }
    
    return count > 0
  }
  
  
//  class func snapshotsURL() -> NSURL {
//    return drudgeURL(path: .SnapShots, parameters: nil)
//  }

  class func latestArticles() -> NSURL {
    return drudgeURL(path: .LatestArticles, parameters: nil)
  }
  
  class func articlesSince(formattedDate: String) -> NSURL {
    return drudgeURL(path: .LatestArticles, parameters: ["since": formattedDate])
  }
  
//  class func articlesForSnapshot(snapshotID: Int) -> NSURL {
//    return drudgeURL(path: .Articles, parameters: ["snapshot_id": String(snapshotID)])
//  }
//
//  class func articleURL(articleID: Int) -> NSURL {
//    let url = drudgeURL(path: .Articles, parameters: nil)
//
//    return url.URLByAppendingPathComponent(String(articleID))
//  }
//  
//  class func snapshotURL(snapshotID: Int) -> NSURL {
//    let snapshotParam = "snapshots"
//    
//    let url = drudgeURL(path: .Articles, parameters: [snapshotParam : String(snapshotID)])
//    return url
//  }
}
