//
//  ViewController.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/15/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import UIKit
import CoreData

class ArticleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

  
  var articles:[Article]! = []
  var coreDataStack:CoreDataStack!
  var articleManager:ArticleManager!
  
  
  var fetchRequest: NSFetchRequest!
  var asyncFetchRequest: NSAsynchronousFetchRequest!
  
  var fetchedResultsController: NSFetchedResultsController!
  
  var updateIndicator:UpdateIndicator = UpdateIndicator()
  var manualRefreshing = false
  
  lazy var refreshControl: UIRefreshControl = {
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(handleRefresh), forControlEvents: UIControlEvents.ValueChanged)
    
    return refreshControl
  }()
  
  
  @IBOutlet weak var newUpdatesIndicator: UpdateIndicator!
  
  @IBOutlet weak var tableView: UITableView!


   override func viewDidLoad() {
    super.viewDidLoad()

    //setup tableview
    tableView.dataSource = self
    
    
    //style UI
    tableView.backgroundColor = UIColor.blackColor()
    
    
    //Hook tableview up to coredata
    fetchRequest = NSFetchRequest(entityName: "Article")
    let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                          managedObjectContext: coreDataStack.context,
                                                          sectionNameKeyPath: nil,
                                                          cacheName: nil)
    
    fetchedResultsController.delegate = self
    
    do {
      try fetchedResultsController.performFetch()
    } catch let error as NSError {
      print("Error: \(error.localizedDescription)")
    }

    //Setup new article indicator
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleGetUpdate))
    newUpdatesIndicator.addGestureRecognizer(tapGesture)
    newUpdatesIndicator.hidden = true
    newUpdatesIndicator.alpha = 0

    //setup pull to refresh
    tableView.addSubview(refreshControl)
  }
  
  func handleRefresh(refreshControl: UIRefreshControl) {
    
    if let maxDate = coreDataStack.getMostRecentArticleDate() {
      manualRefreshing = true
      articleManager.fetchArticleSinceDate(maxDate, completion: {
        (drudgeAPIResult) -> Void in
        
        switch drudgeAPIResult {
        case let .Success(articles):
          print("Pull to refresh loaded: \(articles.count)")
        case let .Failure(error):
          print("Failed to load Articles \(error)")
        }
    
        self.manualRefreshing = false
        self.refreshControl.endRefreshing()
        
      })
    }
  }
  
  
  func handleGetUpdate(sender:UIGestureRecognizer) {
    
    //TODO check if this on sepreate thread
    coreDataStack.resetNewArticles()
    
    hideUpdateIndicator()
  
    //Reload data and move to top
    UIView.animateWithDuration(0.4, animations: {
      self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
      self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0,inSection: 0 ),
        atScrollPosition: UITableViewScrollPosition.Top, animated: true)
    })
  }
  
  
  func hideUpdateIndicator() {
    UIView.animateWithDuration(0.8, animations: {
      self.newUpdatesIndicator.alpha = 0
      }, completion: {
        (value: Bool) -> Void in
        self.newUpdatesIndicator.hidden = true;
    })
  }
  
  func showUpdateIndicator() {
    if self.newUpdatesIndicator.hidden != false {
      
      //set visible and animate in alpha
      self.newUpdatesIndicator.hidden = false
      
      UIView.animateWithDuration(0.8, animations: {
        self.newUpdatesIndicator.alpha = 1
      })
    }
  }

  
  // MARK:  UITableViewDatasource
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return fetchedResultsController.sections!.count
  }
  
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sectionInfo = fetchedResultsController.sections![section]
    return sectionInfo.numberOfObjects
  }
  
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("articleTableViewCell")!
  
    let article = fetchedResultsController.objectAtIndexPath(indexPath) as! Article
    
    //style cell
    let selectedView = UIView()
    
    selectedView.backgroundColor = UIColor.darkGrayColor()
    cell.selectedBackgroundView? = selectedView
  
    cell.textLabel?.text = article.title
    
    return cell
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
    if segue.identifier == "showArticleDetail" {
      let vc = segue.destinationViewController as! ArticleDetailController
      
      var article:Article!
      
      if let indexPath = tableView.indexPathForSelectedRow {
        article = fetchedResultsController.objectAtIndexPath(indexPath) as! Article
        vc.article = article
      }
    }
  }
  
}


extension ArticleViewController: NSFetchedResultsControllerDelegate {
  
  //Not using the realtime update mechanism of FetchedResultsController.  We will show a 'new article' indicator and 
  //when tapped we will load in the new records.
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    if tableView.numberOfRowsInSection(0) == 0 || manualRefreshing {
      tableView.reloadData()
    } else {
      showUpdateIndicator()
    }
  }
}
