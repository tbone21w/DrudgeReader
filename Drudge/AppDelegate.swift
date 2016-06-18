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
  
  var imageService: ImageService!
  var imageStore: ImageStore!
  var articleManager:ArticleManager!
  var drudgeAPI:DrudgeAPI!
  
  var articleRetentionDays:Int?

  var timer:NSTimer?
  
  var applicationRunningInBackground = false
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    
    //Setup local url cache
    let cacheSizeMemory = 4*1024*1024; // 4MB
    let cacheSizeDisk = 32*1024*1024; // 32MB
    
    let urlCache = NSURLCache(memoryCapacity: cacheSizeMemory, diskCapacity: cacheSizeDisk, diskPath: "nsurlcache")
    NSURLCache.setSharedURLCache(urlCache)
    
    //Settings
    articleRetentionDays = NSUserDefaults.standardUserDefaults().objectForKey("article_retention") as? Int
    
    //This is required if users has not made settings changes this was comming back nil
    if articleRetentionDays == nil {
       articleRetentionDays = 30
       NSUserDefaults.standardUserDefaults().registerDefaults(["article_retention" : articleRetentionDays!])
    }

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
    
    imageService = ImageService()
    imageStore = ImageStore()
    imageService.coreDataStack = coreDataStack
    imageService.imageStore = imageStore
    
    articleViewController.imageService = imageService
    
    //delete older data
    removeArticleImages(articleRetentionDays!)
    
    getArticles()

    setupActiveModeBackgroundProcessing()
    
    //set background fetch interval, used when app goes in background
    UIApplication
      .sharedApplication()
      .setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
    
    //global style
    self.window?.tintColor = DrudgeStyleKit.logoStroke
    
    UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : DrudgeStyleKit.logoStroke]
    
    return true
  }


  func applicationDidEnterBackground(application: UIApplication) {
    // backgroundmode supported, this method is called instead of applicationWillTerminate: when the user quits.
    
    applicationRunningInBackground = true
    
    //invalidate the timers going into 'App' background
    if let timer = timer {
      timer.invalidate()
    }
    timer = nil
  }
  

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; 
    //here you can undo many of the changes made on entering the background.
    UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    
    removeArticleImages(articleRetentionDays! )
    
    getArticles()
    
    applicationRunningInBackground = false
    
    setupActiveModeBackgroundProcessing()
    
  }

  // Implementing this will turn on background mode processing
  func  application(application: UIApplication,
                    performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
    
    checkForNewArticlesBackground(completionHandler)
  }
  
  
  /**
   * Checks local data and if user has no data or cleared the data it will fetch the current batch of articles.  If the
   * user has data then we will figure out the last updated time and get articles since then.
   */
  func getArticles() {
    let articleCount = coreDataStack.getArticleCount()
    
    if  articleCount > 0 {
      //get updates
      if let maxDate = coreDataStack.getMostRecentArticleDate() {
        articleManager.fetchArticleSinceDate(maxDate,
                                             retentionDays: articleRetentionDays,
                                             completion: {
          (drudgeAPIResult) -> Void in
          self.handleDrudgeAPIResult(drudgeAPIResult)
        })
      }
    } else {
      //get latest data
      articleManager.fetchRecentArticles({
        (drudgeAPIResult) -> Void in
        self.handleDrudgeAPIResult(drudgeAPIResult)
      })
    }
  }
  
  
  func removeArticleImages(days: Int) {
    let articlesToDelete = coreDataStack.getArticlesToDelete(days)
    print("articlesToDelete \(articlesToDelete?.count)")
    //remove any images related to articles
    if let articles = articlesToDelete {
      for article in articles {
        if let key = article.imageID {
          imageStore.deleteImageForKey(key)
        }
        coreDataStack.privateContext.deleteObject(article)
      }
      
      //save changes
      do {
        try coreDataStack.saveContext()
      } catch {
        print (error)
      }
      
    }
    
  }
  
  
  func handleDrudgeAPIResult(drudgeAPIResult: DrudgeAPIResult) {
    
    if case let .Failure(error) = drudgeAPIResult {
      print("Failed to load Articles \(error)")
      
      //We may not need this check
      if  error is DrudgeAPIError  {
        let drudgeError = error as! DrudgeAPIError
        
        if drudgeError == DrudgeAPIError.NilData {
          
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
  
  
  func setupActiveModeBackgroundProcessing() {
    timer = NSTimer(timeInterval: (5.0 * 60), target: self, selector: #selector(checkForNewArticles), userInfo: nil, repeats: true)
    
    NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
  }
  
  
  func checkForNewArticles() {
    if let maxDate = coreDataStack.getMostRecentArticleDate() {
      articleManager.fetchArticleSinceDate(maxDate,
                                           retentionDays: articleRetentionDays,
                                           completion: {
        (drudgeAPIResult) -> Void in
        
        self.handleDrudgeAPIResult(drudgeAPIResult)
        
      })
    }
  }
  
  
  func checkForNewArticlesBackground(completion: (UIBackgroundFetchResult) -> Void) {
    if let maxDate = coreDataStack.getMostRecentArticleDate() {
      articleManager.fetchArticleSinceDate(maxDate,
                                           retentionDays: articleRetentionDays,
                                           completion: {
        (drudgeAPIResult) -> Void in
        
        switch drudgeAPIResult {
          case let .Success(articles):
              if articles.count > 0 {
                  if self.applicationRunningInBackground {
                    self.scheduleLocalNotificaiton()
                  }
                  completion(.NewData)
              } else {
                completion(.NoData)
              }
          case .Failure(_):
              completion(.NoData)
        }
        
      })
    }
  }
  
  
  /**
   * schedules a local notification to be displayed showing all the 'New' Articles shince the users last used the app.
   */
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
  
}

