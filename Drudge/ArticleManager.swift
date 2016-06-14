//
//  ArticleManager.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/17/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import UIKit
import CoreData

class ArticleManager {
  
  var coreDataStack:CoreDataStack!
  var drudgeAPI:DrudgeAPI
  
  enum ArticleResult {
    case Success([Article])
    case Failure(ErrorType)
  }
  
  enum PhotoError: ErrorType {
    case ImageCreationError
  }
  
  
  let session: NSURLSession = {
    let config = NSURLSessionConfiguration.defaultSessionConfiguration()
    return NSURLSession(configuration: config)
  }()

  init(coreDataStack:CoreDataStack, drudgeAPI: DrudgeAPI) {
    self.coreDataStack = coreDataStack
    self.drudgeAPI = drudgeAPI
  }
  
 
  
  
  func fetchArticleSinceDate(lastUpdated: NSDate, retentionDays: Int?, completion: (DrudgeAPIResult) -> Void) {
    
 
    
    let formattedDate = DrudgeAPI.formatterISO8601.stringFromDate(lastUpdated)
    
    let url = DrudgeAPI.articlesSince(formattedDate)
    let request = NSURLRequest(URL: url)
    
    print(" ")
    print("Fetching Articles since \(lastUpdated) from \(url)")
    
    //Async, need a way to tell UI we are working and then update NSFetchedResultsController??
    let task = session.dataTaskWithRequest(request, completionHandler: {
      (data, response, error) -> Void in
      
      //error at this point indicate network issues
      if error != nil {
        return completion(DrudgeAPIResult.Failure(DrudgeAPIError.NetworkError))
      }
      
      //check for data first
      var result = self.drudgeAPI.articlesFromJSONData(inContext: self.coreDataStack.privateContext, data: data)
      
      //if we successfully fetched articles
      if case let .Success(articles) = result {
        
        print("Found \(articles.count) Article(s)")
        
        
        
        //TODO this is always setting to true but we insert or update in the drudgeAPI.articlesFromJSONData, 
        //updated articels are not new
        for article in articles {
          article.isNew = true
          
          //check to see if we need to ignore this article
          if retentionDays != nil {
            if let updatedAt = article.updatedAt {
              let cutOffDate = NSDate().dateByAddingTimeInterval(-1*Double(retentionDays!)*24*60*60)
              if updatedAt.compare(cutOffDate) == NSComparisonResult.OrderedAscending {
                print("article date \(article.updatedAt) is older than cutoff \(cutOffDate)")
              }
            }
          }
        }
        
        do {
          try self.coreDataStack.saveContext()
        } catch let error {
          print(error)
          result = .Failure(error)
        }
      }
      
      //Callback with result
      completion(result)
    })
    
    task.resume()
  }
  
  
  /** 
   *    Fetches all the latest articles and saves to Core Data.
   */
  func fetchRecentArticles(completion: (DrudgeAPIResult) -> Void) {

    let url = DrudgeAPI.latestArticles()
    let request = NSURLRequest(URL: url)
    
    print("Fetching ALL Articles \(url)")
    
    let task = session.dataTaskWithRequest(request, completionHandler: {
      (data, response, error) -> Void in
      
      var result = self.drudgeAPI.articlesFromJSONData(inContext: self.coreDataStack.context, data: data)
  
      //if we successfully fetched articles
      if case .Success(_) = result {
        //TODO save article photo
        do {
          try self.coreDataStack.saveContext()
        } catch let error {
          print(error)
          result = .Failure(error)
        }
      }

      //Callback with result
      completion(result)
  
    })
    
    task.resume()
  }
  
  
}