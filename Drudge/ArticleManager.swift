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
  
 
  
  
  func fetchArticleSinceDate(lastUpdated: NSDate, completion: (DrudgeAPIResult) -> Void) {
    
    let formattedDate = DrudgeAPI.formatterISO8601.stringFromDate(lastUpdated)
    
    let url = DrudgeAPI.articlesSince(formattedDate)
    let request = NSURLRequest(URL: url)
    print("Request : \(url.absoluteString)")
    
    //Async, need a way to tell UI we are working and then update NSFetchedResultsController??
    let task = session.dataTaskWithRequest(request, completionHandler: {
      (data, response, error) -> Void in
      
      var result = self.drudgeAPI.articlesFromJSONData(inContext: self.coreDataStack.context, data: data)
      
      //if we successfully fetched articles
      if case let .Success(articles) = result {
        
        for article in articles {
          article.isNew = true
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
    
    let task = session.dataTaskWithRequest(request, completionHandler: {
      (data, response, error) -> Void in
      
      var result = self.drudgeAPI.articlesFromJSONData(inContext: self.coreDataStack.context, data: data)
  
      //if we successfully fetched articles
      if case let .Success(articles) = result {
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
  
  
  func insertMockData()  {
    var articles:[Article] = [Article]()
    
    let articleEntity = NSEntityDescription.entityForName("Article", inManagedObjectContext: coreDataStack.context)
    
    for i in 1 ... 2 {
      let article = Article(entity: articleEntity!, insertIntoManagedObjectContext: coreDataStack.context)
      
      article.id = i
      article.title = "Russia blames USA 'dark arts' for EUROVISION upset...  article \(i)"
      article.href = "http://www.google.com"
      
      articles.append(article)
    }
    
    do {
      try coreDataStack.context.save()
    } catch let error as NSError {
      print("Error inserting mock data: \(error.localizedDescription)")
    }
  }

  
  
}