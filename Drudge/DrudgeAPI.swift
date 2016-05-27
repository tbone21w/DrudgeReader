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
  
  private static let baseURL = "https://drudge.herokuapp.com/api/v1/"
  

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
        //encode query string
        guard let
          escapedKey = key.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()),
          escapedValue = value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        else {
          break
        }
        
        let item = NSURLQueryItem(name: escapedKey, value: escapedValue)
        queryItems.append(item)
      }
    }
    
   
    
    components.queryItems = queryItems

    let url = components.URL!.URLByAppendingPathComponent(path.rawValue)
    
   

    return url
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
        
        if let article = result {
          articles.append(article)
        }
      }
      
      print("Number of Articles: \(articles.count)")
      
      return .Success(articles)
    } catch let error {
      //TODO return .Failure(error)
      print("Error serializing data to JSON \(error)")
      return .Failure(DrudgeAPIError.InvalidJSONData)
    }
  }
  
  private func articleFromJSONData(inContext context: NSManagedObjectContext, json: [String : AnyObject]) -> Article? {
    
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
        return nil
    }
    
    var article:Article?
    
    //check for valid object
    if let articleFromDB = getArticleById(inContext: context, id: id.intValue) {
      article = articleFromDB
      
      //make sure we have an update otherwise NSFetchedResultsController will see an update and the Update button will show
      if id == article?.id
                && imageURL == article?.imageURL
                && currentLocation == article?.location
                && createdDate == article?.createdAt
                && updatedDate == article?.updatedAt
                && href == article?.href
                && text == article?.title {
        
        return nil
      }
      
    } else {
      let articleEntity = NSEntityDescription.entityForName("Article", inManagedObjectContext: context)
      article = Article(entity: articleEntity!, insertIntoManagedObjectContext: context)
    }
  
    if let article = article {
      //set fields
      article.id = id
      article.href = href
      article.title = text
      article.location = currentLocation
      article.imageURL = imageURL
      article.createdAt = createdDate
      article.updatedAt = updatedDate
    }

    return article

  }
  
  func getArticleById(inContext context: NSManagedObjectContext, id: Int32) -> Article? {
    let fetchRequest = NSFetchRequest(entityName: "Article")
    
    fetchRequest.resultType = .ManagedObjectResultType
    fetchRequest.fetchLimit = 1
    
    fetchRequest.predicate = NSPredicate(format: "id = %D", id)
    
    var article:Article?
    
    do {
      let results = try context.executeFetchRequest(fetchRequest) as! [Article]
      article = results.first
    } catch let error as NSError {
      print("Could not fetch \(error), \(error.userInfo)")
    }
    
    return article
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
  
  class func latestArticles() -> NSURL {
    return drudgeURL(path: .LatestArticles, parameters: nil)
  }
  
  class func articlesSince(formattedDate: String) -> NSURL {
    return drudgeURL(path: .LatestArticles, parameters: ["since": formattedDate])
  }
  
}

