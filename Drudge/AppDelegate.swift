//
//  AppDelegate.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/15/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  lazy var coreDataStack = CoreDataStack()
  
  var articleManager:ArticleManager!
  var drudgeAPI:DrudgeAPI!
  
  
  var timer:NSTimer?
  
  var applicationRunningInBackground = false
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    
    //setup local notifications
    let notificationSettings = UIUserNotificationSettings(forTypes: [.Badge, .Alert], categories: nil)
    UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
    
    
    //Set the intial view controller dependencies
    let navController = window!.rootViewController as! UINavigationController
    let articleViewController = navController.topViewController as! ArticleViewController
    articleViewController.coreDataStack = coreDataStack
    
    drudgeAPI = DrudgeAPI()
    articleManager = ArticleManager(coreDataStack: coreDataStack,drudgeAPI: drudgeAPI)

    articleViewController.articleManager = articleManager
    
    
    //delete older data
    coreDataStack.cleanupOldArticles()
    
    let articleCount = coreDataStack.getArticleCount()
    
    if  articleCount > 0 {
      //get updates
      print("Fetching Articles SINCE")
      if let maxDate = coreDataStack.getMostRecentArticleDate() {
        articleManager.fetchArticleSinceDate(maxDate, completion: {
            (drudgeAPIResult) -> Void in
                self.handleDrudgeAPIResult(drudgeAPIResult)
        })
      }
    } else {
      //get latest data
      print("Fetching ALL Articles")
      articleManager.fetchRecentArticles({
          (drudgeAPIResult) -> Void in
              self.handleDrudgeAPIResult(drudgeAPIResult)
      })
    }
    
    let url = DrudgeAPI.latestArticles()
    print("Latest Articles URL \(url.absoluteString)")
    

    setupForgroundProcessing()
    
    //set background fetch
    UIApplication
      .sharedApplication()
      .setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
    
    return true
  }
  

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    applicationRunningInBackground = true
    
    //invalidate the timers going into 'App' background
    if let timer = timer {
      print("Invalidating Timer")
      timer.invalidate()
    }
    timer = nil
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    applicationRunningInBackground = false
    
    setupForgroundProcessing()
    
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  func  application(application: UIApplication,
                    performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
    
    checkForNewArticlesBackground(completionHandler)
    
  }
  
  func handleDrudgeAPIResult(drudgeAPIResult: DrudgeAPIResult) {
    
    switch drudgeAPIResult {
    case let .Success(articles):
      print("Loaded \(articles.count)")
    case let .Failure(error):
      print("Failed to load Articles \(error)")
      
      //We may not need this check
      if  error is DrudgeAPIError  {
        let drudgeError = error as! DrudgeAPIError
        
        if drudgeError == DrudgeAPIError.NilData {
          print("Network error \(error)")
          let alert = UIAlertController(title: "Error Loading Data",
                                        message: "Network Error",
                                        preferredStyle: UIAlertControllerStyle.Alert)
          
          alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
          
          //must dispatch this on the mainQueue
          dispatch_async(dispatch_get_main_queue(), {
            self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
          });
        }
      }
    }
  }
  
  func setupForgroundProcessing() {
    print("Adding Timer")
    timer = NSTimer(timeInterval: (5.0 * 60), target: self, selector: #selector(checkForNewArticles), userInfo: nil, repeats: true)
    
    NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
  }
  
  func checkForNewArticles() {
    print("Active App Background Check For new Articles")
    if let maxDate = coreDataStack.getMostRecentArticleDate() {
      articleManager.fetchArticleSinceDate(maxDate, completion: {
        (drudgeAPIResult) -> Void in
        
        self.handleDrudgeAPIResult(drudgeAPIResult)
        
      })
    }
  }
  
  
  func checkForNewArticlesBackground(completion: (UIBackgroundFetchResult) -> Void) {
    print("Background Check For new Articles")
    if let maxDate = coreDataStack.getMostRecentArticleDate() {
      articleManager.fetchArticleSinceDate(maxDate, completion: {
        (drudgeAPIResult) -> Void in
        
        switch drudgeAPIResult {
          case let .Success(articles):
              print("Loaded \(articles.count)")
              if articles.count > 0 {
                  if self.applicationRunningInBackground {
                    self.scheduleLocalNotificaiton()
                  }
                  completion(.NewData)
              } else {
                completion(.NoData)
              }
          case let .Failure(error):
              print("Failed to load Articles \(error)")
              completion(.NoData)
        }
        
      })
    }
  }
  
  func scheduleLocalNotificaiton() {
    
    //todo get total new articles
    let count = coreDataStack.getNewArticleCount()
    
    if count > 0 {
      let localNotification = UILocalNotification()
      localNotification.fireDate = NSDate()
      localNotification.alertBody = "New Articles have been posted"
      localNotification.applicationIconBadgeNumber = count
      UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
  }
  
  func deleteData() {
    let fetchRequest = NSFetchRequest(entityName: "Article")
    var error: NSError? = nil
    
    let results =
      coreDataStack.context.countForFetchRequest(fetchRequest,
                                                 error: &error)
    
    if (results >= 0) {
      
      do {
        let results =
          try coreDataStack.context.executeFetchRequest(fetchRequest) as! [Article]
        
        for object in results {
          let article = object as Article
          coreDataStack.context.deleteObject(article)
        }
        
        do {
          try coreDataStack.saveContext()
        } catch let error as NSError {
          print("Error cleaning up core data \(error)")
        }

        
      } catch let error as NSError {
        print("Error fetching: \(error.localizedDescription)")
      }
    }
  }
  
}

