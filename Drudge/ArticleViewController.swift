//
//  ViewController.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/15/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import UIKit
import CoreData

enum SearchFilterType: String {
   case ShowAll = "Show All"
   case ShowUnread = "Show Unread"
}

class ArticleViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, CellGestureDelegate {

  var articles:[Article]! = []
  
  var coreDataStack:CoreDataStack!
  var articleManager:ArticleManager!
  var imageService:ImageService!
  
  var fetchRequest: NSFetchRequest!
  var asyncFetchRequest: NSAsynchronousFetchRequest!
  
  var fetchedResultsController: NSFetchedResultsController!
  
  var updateIndicator:UpdateIndicator = UpdateIndicator()
  var immediateTableUpdate = false
  
  var showPlaceholder = false
  
  var showAll = true
  
  var settingsObserver:AnyObject?
  
  lazy var refreshControl: UIRefreshControl = {
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(handleRefresh), forControlEvents: UIControlEvents.ValueChanged)
    
    return refreshControl
  }()
  
  //"2016-05-22T08:17:08.595288-04:00"
//  static let formatterISO8601: NSDateFormatter = {
//    let formatter = NSDateFormatter()
//    formatter.dateStyle = .FullStyle
//    
//    return formatter
//  }()
//  
  @IBOutlet weak var filterButton: UIBarButtonItem!
  
  @IBAction func handleFilterClick(sender: AnyObject?) {
      showAll = !showAll
      loadArticles()
  }
  
  
  @IBOutlet weak var newUpdatesIndicator: UpdateIndicator!
  
  @IBOutlet weak var tableView: UITableView!


   override func viewDidLoad() {
    super.viewDidLoad()

    //Handle settings
    getSettings()

    settingsObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSUserDefaultsDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: { (notificaiton) in
      self.settingsChangedHandler()
    })
    
    

    tableView.scrollIndicatorInsets = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0);
    
    //setup tableview
    tableView.dataSource = self
    
    
    //style UI
    tableView.backgroundColor = UIColor.blackColor()
    
    title = "Drudgin"
    //self.navigationController?.navigationBar.barTintColor = DrudgeStyleKit.logoLines
    
    //setup fetchedResutlsController and get data
    showAll = true
    filterButton.image = DrudgeStyleKit.imageOfFilter
    
    //load initial data
    loadArticles()

    //Setup new article indicator
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleGetUpdate))
    newUpdatesIndicator.addGestureRecognizer(tapGesture)
    newUpdatesIndicator.hidden = true
    newUpdatesIndicator.alpha = 0

    //setup pull to refresh
    tableView.addSubview(refreshControl)
    
    navigationItem.titleView = UIImageView(image:  DrudgeStyleKit.imageOfMiniLogo2)
    
  }
  
  
  /**
   * Load articles based on filter settings
   */
  func loadArticles() {
    fetchRequest = NSFetchRequest(entityName: "Article")
    
    if showAll {
      filterButton.image = DrudgeStyleKit.imageOfFilter
    } else {
      fetchRequest.predicate = NSPredicate(format: "read = false")
      filterButton.image = DrudgeStyleKit.imageOfNoFilter
    }
    
    let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                          managedObjectContext: coreDataStack.context,
                                                          sectionNameKeyPath: nil,
                                                          cacheName: nil)
    
    fetchedResultsController.delegate = self
    
    do {
      try fetchedResultsController.performFetch()
      tableView.reloadData()
    } catch let error as NSError {
      print("Error: \(error.localizedDescription)")
    }
  }
  
  
  /**
   * Event handler for the settings observer.  
   *
   * When settings changed grab the current settings and reload the table view
   */
  func settingsChangedHandler() {
    getSettings()
    tableView.reloadData()
  }
  
  
  func getSettings() {
    showPlaceholder = NSUserDefaults.standardUserDefaults().boolForKey("show_placeholder")
  }
  
  
  /**
   * Handle the manual pull to refresh.  We set a flag indicating we want immediate table update
   */
  func handleRefresh(refreshControl: UIRefreshControl) {
    
    if let maxDate = coreDataStack.getMostRecentArticleDate() {
      immediateTableUpdate = true
      articleManager.fetchArticleSinceDate(maxDate, completion: {
        (drudgeAPIResult) -> Void in
    
        self.immediateTableUpdate = false
        self.refreshControl.endRefreshing()
        
      })
    }
  }
  
  
  /**
   * Show new articles
   */
  func handleGetUpdate(sender:UIGestureRecognizer) {
    
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
  
  
  func tableViewCellSubViewTapped(cell:UITableViewCell) {
    performSegueWithIdentifier("showImage", sender: cell)
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("articleTableViewCell") as! ArticleTableViewCell
    
    cell.delegate = self
    
    let article = fetchedResultsController.objectAtIndexPath(indexPath) as! Article

    cell.article = article

    if article.imageURL != nil && !article.imageURL!.isEmpty {

       //have image need to load
      configureCellImageVisibleFetching(cell)
      
      // Download the image data, which could take some time
      imageService.fetchImage(article, completion: {
        (imageResult) -> Void in
        
        NSOperationQueue.mainQueue().addOperationWithBlock() {
          
          //image fetch operation done
          switch imageResult {
            case let .Success(image):
              // When the request finishes, only update the cell if it's still visible
              self.stopAnimatingCellSpinner(cell)
              
              if let cell = self.tableView.cellForRowAtIndexPath(indexPath)
                as? ArticleTableViewCell {
                cell.articleImage.image = image
              }
          case .Failure(_):
            //no value to indicatea fail to user, could even be TLS version
            self.configureCellImageHidden(cell)
            self.stopAnimatingCellSpinner(cell)
          }
          
        }
      })
      
    } else {
      //no image
      configureCellImageHidden(cell)
     self.stopAnimatingCellSpinner(cell)
    }
    
    return cell
  }
  

  
  func configureCellImageVisibleFetching(cell: ArticleTableViewCell) {
    cell.articleImageWidthConstraint.constant = cell.articleImage.frame.height
    cell.spinner.startAnimating()
    cell.spinner.hidden = false
    
    cell.articleImage.alpha = 1.0
  }
  
  func configureCellImageHidden(cell: ArticleTableViewCell) {
    if showPlaceholder {
      cell.articleImage.image =  DrudgeStyleKit.imageOfPicture
      cell.articleImage.alpha = 0.5
      cell.articleImageWidthConstraint.constant = cell.articleImage.frame.height
    } else {
      cell.articleImageWidthConstraint.constant = 0
    }
    
    stopAnimatingCellSpinner(cell)
  }
  
  func stopAnimatingCellSpinner(cell: ArticleTableViewCell) {
    cell.spinner.stopAnimating()
    cell.spinner.hidden = true
  }

  override func viewWillDisappear(animated: Bool) {
    print("ArticleViewController viewWillDisappear")
    if let observer = settingsObserver {
      print("Removing settings observer")
      NSNotificationCenter.defaultCenter().removeObserver(observer)
    }
  }

  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
    if segue.identifier == "showArticleDetail" {
      let vc = segue.destinationViewController as! ArticleDetailController
      
      var article:Article!
      
      
      if let indexPath = tableView.indexPathForSelectedRow {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! ArticleTableViewCell
        article = cell.article
        
        if article.read == false {
          article.read = true
          do {
            //this will trigger an update to the table view force an update (ignore update button)
            immediateTableUpdate = true
            try articleManager.coreDataStack.saveContext()
          } catch  {
            //no need to do anyhting
          }
          immediateTableUpdate = false
          
        }
        
        vc.article = article
      }
    }
    
    if segue.identifier == "showImage" {
      let vc = segue.destinationViewController as! ImageViewController
      
      let cell = sender as! ArticleTableViewCell
      vc.image = cell.articleImage.image
    }
  }
  
}


extension ArticleViewController: NSFetchedResultsControllerDelegate {
  
  //Not using the realtime update mechanism of FetchedResultsController.  We will show a 'new article' indicator and 
  //when tapped we will load in the new records.
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    if tableView.numberOfRowsInSection(0) == 0 || immediateTableUpdate {
      tableView.reloadData()
      
    } else {
      showUpdateIndicator()
    }
  }
}
